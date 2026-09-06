import { BadRequestException, Body, Controller, Get, Inject, NotFoundException, Post } from '@nestjs/common';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';
import { findScope, SCOPES } from '../scopes/scope-catalog';
import { ScopesService } from '../scopes/scopes.service';
import { KeycloakAdminService } from './keycloak-admin.service';

type LookupMedium = 'aadhaar' | 'pan' | 'phone';

interface RegisterCompleteBody {
  medium: LookupMedium;
  value: string;
  phoneNumber?: string;
  password: string;
  consentGiven: boolean;
  grantedScopes: string[];
}

// Deliberately outside JwtAuthGuard — called before the user has a token, to resolve
// whichever identifier they typed (mobile number / citizen ID / Aadhaar-style number)
// into the Keycloak username used as a loginHint on the hosted login page. core-api
// never sees or handles the password itself. Returns a flat "not found" without
// revealing which identifier type matched, to avoid a trivial enumeration oracle.
@Controller('auth')
export class IdentifierResolutionController {
  constructor(
    @Inject(PG_POOL) private readonly pool: Pool,
    private readonly keycloakAdmin: KeycloakAdminService,
    private readonly scopes: ScopesService,
  ) {}

  @Post('resolve-identifier')
  async resolve(@Body('identifier') identifier: string) {
    const cleaned = (identifier ?? '').trim();
    if (!cleaned) throw new NotFoundException('no matching account');

    const { rows } = await this.pool.query(
      `SELECT keycloak_username FROM master_identity
       WHERE keycloak_username = $1 OR phone_number = $1 OR aadhaar_number = $1 OR master_id = $1`,
      [cleaned],
    );
    if (rows.length === 0 || !rows[0].keycloak_username) throw new NotFoundException('no matching account');

    return { username: rows[0].keycloak_username };
  }

  /**
   * SIMULATED DigiLocker/Aadhaar eKYC lookup against a persistent mock UIDAI registry
   * (digilocker-adapter's own database) — real DigiLocker Partner + UIDAI AUA/KUA
   * integration requires formal government approval, not obtainable here. No DB
   * write; just previews what the registry has on file so the citizen can confirm
   * before choosing data-sharing scopes and creating an account.
   */
  @Post('register/lookup')
  async lookup(@Body() body: { medium: LookupMedium; value: string }) {
    const govtRecord = await this.fetchGovtRecord(body.medium, body.value);
    await this.rejectIfDeceased(govtRecord);
    return govtRecord;
  }

  // Public catalog of data-sharing scopes a citizen can choose from at registration —
  // no citizen-specific data, safe to expose pre-login. Single source of truth is
  // scope-catalog.ts; the frontend never hardcodes this list.
  @Get('register/scopes')
  scopeCatalog() {
    return SCOPES.map((s) => ({ key: s.key, label: s.label, sourceAuthority: s.sourceAuthority, isDefault: s.isDefault }));
  }

  @Post('register/complete')
  async complete(@Body() body: RegisterCompleteBody) {
    if (!body.consentGiven) {
      throw new BadRequestException('Consent is required to create a OneDesk account');
    }
    if (!body.password || body.password.length < 6) {
      throw new BadRequestException('A password of at least 6 characters is required');
    }
    // Phone is deliberately optional — not every real citizen (e.g. a newborn) has
    // one; when absent, login falls back to the generated OneDesk ID (below).
    const phoneNumber = body.phoneNumber?.trim() || null;
    const grantedScopes = (body.grantedScopes ?? []).filter((key) => findScope(key));

    // Re-fetch from the govt registry rather than trusting whatever the client sent —
    // the earlier /register/lookup call is just a preview; this is the write path.
    // aadhaar_number is the registry's primary key, so it's always present on the
    // resolved record regardless of which medium (Aadhaar/PAN/phone) found it.
    const govtRecord = await this.fetchGovtRecord(body.medium, body.value);
    await this.rejectIfDeceased(govtRecord);
    const aadhaarNumber = govtRecord.aadhaarNumber as string;

    // phone_number = NULL never matches in Postgres, so a citizen registering with
    // no phone only gets caught by the aadhaar_number half here — no special-casing
    // needed for the null case.
    const { rows: existing } = await this.pool.query(
      'SELECT 1 FROM master_identity WHERE phone_number = $1 OR aadhaar_number = $2',
      [phoneNumber, aadhaarNumber],
    );
    if (existing.length > 0) {
      throw new BadRequestException('An account already exists for this phone number or Aadhaar number');
    }

    const { rows: seqRows } = await this.pool.query("SELECT nextval('citizen_seq') AS n");
    const masterId = `CIT-${seqRows[0].n}`;
    const username = phoneNumber ?? masterId;
    const name = govtRecord.name as string;
    const nameParts = name.trim().split(/\s+/);
    const firstName = nameParts[0] ?? name;
    const lastName = nameParts.slice(1).join(' ') || firstName;

    // Create the real Keycloak account first — if this fails, nothing is written to
    // master_identity, avoiding a citizen record with no way to ever log in.
    await this.keycloakAdmin.createCitizenUser({
      username,
      password: body.password,
      firstName,
      lastName,
      masterId,
    });

    // identity.basic + identity.contact (default scopes) — written directly, not via
    // the generic scope-column path: phone_number is the citizen's own chosen OneDesk
    // login/contact number (or absent entirely), not necessarily whatever the
    // registry has on file.
    await this.pool.query(
      `INSERT INTO master_identity
         (master_id, citizen_name, keycloak_username, phone_number, aadhaar_number, date_of_birth, gender)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [masterId, name, username, phoneNumber, aadhaarNumber, govtRecord.dateOfBirth, govtRecord.gender],
    );

    const photoPath = await this.scopes.fetchAndSavePhoto(aadhaarNumber, masterId);
    if (photoPath) {
      await this.pool.query('UPDATE master_identity SET photo_path = $1 WHERE master_id = $2', [photoPath, masterId]);
    }
    await this.scopes.recordDefaultGrants(masterId);
    await this.scopes.applyOptionalGrants(masterId, grantedScopes, govtRecord);

    await this.pool.query(
      `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose)
       VALUES ($1, $2, 'Unified Portal', 'WRITE', $3, 'Success', 'Citizen self-registration')`,
      [`aud-${Date.now()}`, masterId, `New OneDesk account created (${masterId})`],
    );

    return { masterId, username };
  }

  /**
   * The registry is the authoritative source, not OneDesk — if it says a citizen's
   * identity status is DECEASED, registration must stop here rather than creating a
   * live account. No raw identifier is logged; the audit resource string is
   * deliberately generic (the aadhaar number itself is never written to audit_log).
   */
  private async rejectIfDeceased(govtRecord: Record<string, unknown>): Promise<void> {
    if (govtRecord.identityStatus !== 'DECEASED') return;
    await this.pool.query(
      `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose)
       VALUES ($1, 'Unified Portal', 'Identity Registry', 'IDENTITY_VERIFICATION_FAILED', 'Registration attempt', 'Denied', 'DECEASED_STATUS')`,
      [`aud-${Date.now()}`],
    );
    throw new BadRequestException('This identifier cannot be registered at this time. Contact support if you believe this is an error.');
  }

  private async fetchGovtRecord(medium: LookupMedium, value: string): Promise<Record<string, unknown>> {
    const base = process.env.DIGILOCKER_ADAPTER_URL ?? 'http://digilocker-adapter:4005';
    const res = await fetch(`${base}/ekyc`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ medium, value }),
    });
    const responseBody = await res.json();
    if (res.status === 404) throw new NotFoundException(responseBody.message ?? 'No record on file for this identifier');
    if (!res.ok) throw new BadRequestException(responseBody.message ?? 'Could not verify this identifier');
    return responseBody;
  }
}
