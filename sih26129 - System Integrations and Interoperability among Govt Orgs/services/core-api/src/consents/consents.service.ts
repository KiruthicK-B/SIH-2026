import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import type { Pool, QueryResultRow } from 'pg';
import { PG_POOL } from '../db/db.module';
import { EligibilityService } from '../eligibility/eligibility.service';
import { NotificationsService } from '../notifications/notifications.service';
import type { Consent, PendingConsentRequest } from './consents.types';

function iso(d: any) {
  return new Date(d).toISOString().slice(0, 10);
}

@Injectable()
export class ConsentsService {
  constructor(
    @Inject(PG_POOL) private readonly pool: Pool,
    private readonly eligibility: EligibilityService,
    private readonly notifications: NotificationsService,
  ) {}

  async listConsents(citizenMasterId?: string): Promise<Consent[]> {
    const { rows } = citizenMasterId
      ? await this.pool.query('SELECT * FROM consents WHERE citizen_master_id = $1 ORDER BY granted_on DESC', [citizenMasterId])
      : await this.pool.query('SELECT * FROM consents ORDER BY granted_on DESC');
    return rows.map((c: QueryResultRow) => ({
      id: c.id,
      dataCategory: c.data_category,
      department: c.department,
      purpose: c.purpose,
      status: c.status,
      grantedOn: iso(c.granted_on),
      validUntil: iso(c.valid_until),
      citizenMasterId: c.citizen_master_id ?? undefined,
    }));
  }

  async listPendingRequests(citizenMasterId?: string): Promise<PendingConsentRequest[]> {
    const { rows } = citizenMasterId
      ? await this.pool.query('SELECT * FROM pending_consent_requests WHERE citizen_master_id = $1 ORDER BY requested_on DESC', [citizenMasterId])
      : await this.pool.query('SELECT * FROM pending_consent_requests ORDER BY requested_on DESC');
    return Promise.all(
      rows.map(async (r: QueryResultRow) => {
        const [eligibility, scope] = await Promise.all([
          this.eligibility.checkEligibility(r.department, r.citizen_master_id ?? null),
          this.eligibility.checkScope(r.required_scope ?? null, r.citizen_master_id ?? null),
        ]);
        return {
          id: r.id,
          department: r.department,
          purpose: r.purpose,
          dataRequested: r.data_requested,
          requestedOn: iso(r.requested_on),
          eligible: eligibility.eligible && scope.eligible,
          eligibilityReasons: [...eligibility.reasons, ...scope.reasons],
        };
      }),
    );
  }

  async allowRequest(requestId: string, actor: string, citizenMasterId?: string): Promise<Consent> {
    const { rows } = citizenMasterId
      ? await this.pool.query('SELECT * FROM pending_consent_requests WHERE id = $1 AND citizen_master_id = $2', [requestId, citizenMasterId])
      : await this.pool.query('SELECT * FROM pending_consent_requests WHERE id = $1', [requestId]);
    if (rows.length === 0) throw new NotFoundException(`pending request ${requestId} not found`);
    const request = rows[0];

    const [eligibility, scope] = await Promise.all([
      this.eligibility.checkEligibility(request.department, request.citizen_master_id ?? null),
      this.eligibility.checkScope(request.required_scope ?? null, request.citizen_master_id ?? null),
    ]);
    const reasons = [...eligibility.reasons, ...scope.reasons];
    if (reasons.length > 0) {
      throw new BadRequestException(`Not eligible for ${request.department}: ${reasons.join('; ')}`);
    }

    const newConsentId = `con-${Date.now()}`;
    const grantedOn = new Date().toISOString().slice(0, 10);
    const validUntil = new Date(Date.now() + 1000 * 60 * 60 * 24 * 60).toISOString().slice(0, 10);

    await this.pool.query('BEGIN');
    try {
      await this.pool.query(
        `INSERT INTO consents (id, data_category, department, purpose, status, granted_on, valid_until, citizen_master_id)
         VALUES ($1, $2, $3, $4, 'Active', $5, $6, $7)`,
        [newConsentId, (request.data_requested as string[]).join(', '), request.department, request.purpose, grantedOn, validUntil, request.citizen_master_id],
      );
      await this.pool.query('DELETE FROM pending_consent_requests WHERE id = $1', [requestId]);
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose, consent_id)
         VALUES ($1, $2, $3, 'GRANT CONSENT', $4, 'Success', $5, $6)`,
        [`aud-${Date.now()}`, actor, request.department, (request.data_requested as string[]).join(', '), request.purpose, newConsentId],
      );
      await this.pool.query('COMMIT');
    } catch (err) {
      await this.pool.query('ROLLBACK');
      throw err;
    }

    await this.notifications.notify(
      request.citizen_master_id ?? null,
      'consent',
      `Consent granted — ${request.department}`,
      `${request.department} can now access ${(request.data_requested as string[]).join(', ')} for ${request.purpose}.`,
    );

    const { rows: created } = await this.pool.query('SELECT * FROM consents WHERE id = $1', [newConsentId]);
    const c = created[0];
    return { id: c.id, dataCategory: c.data_category, department: c.department, purpose: c.purpose, status: c.status, grantedOn: iso(c.granted_on), validUntil: iso(c.valid_until) };
  }

  async denyRequest(requestId: string, citizenMasterId?: string): Promise<void> {
    const { rowCount } = citizenMasterId
      ? await this.pool.query('DELETE FROM pending_consent_requests WHERE id = $1 AND citizen_master_id = $2', [requestId, citizenMasterId])
      : await this.pool.query('DELETE FROM pending_consent_requests WHERE id = $1', [requestId]);
    if (rowCount === 0) throw new NotFoundException(`pending request ${requestId} not found`);
  }

  async revokeConsent(consentId: string, actor: string, citizenMasterId?: string): Promise<void> {
    const { rows } = citizenMasterId
      ? await this.pool.query('SELECT * FROM consents WHERE id = $1 AND citizen_master_id = $2', [consentId, citizenMasterId])
      : await this.pool.query('SELECT * FROM consents WHERE id = $1', [consentId]);
    if (rows.length === 0) throw new NotFoundException(`consent ${consentId} not found`);
    const consent = rows[0];

    await this.pool.query('BEGIN');
    try {
      await this.pool.query(`UPDATE consents SET status = 'Revoked' WHERE id = $1`, [consentId]);
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose, consent_id)
         VALUES ($1, $2, $3, 'REVOKE CONSENT', $4, 'Success', 'Citizen-initiated revocation', $5)`,
        [`aud-${Date.now()}`, actor, consent.department, consent.data_category, consentId],
      );
      await this.pool.query('COMMIT');
    } catch (err) {
      await this.pool.query('ROLLBACK');
      throw err;
    }

    await this.notifications.notify(
      consent.citizen_master_id ?? null,
      'consent',
      `Consent revoked — ${consent.department}`,
      `${consent.department} no longer has access to ${consent.data_category}.`,
    );
  }
}
