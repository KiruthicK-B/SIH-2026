import { Inject, Injectable } from '@nestjs/common';
import type { Pool } from 'pg';
import { Builder, parseStringPromise } from 'xml2js';
import { PG_POOL } from '../db/db.module';
import { DOC_URL_TTL_MS, SLUG_BY_DEPARTMENT, signDocumentAccess } from '../interop/interop-secrets';
import { connectorCallsTotal } from '../metrics/metrics';

export interface ConnectorRegistryRow {
  name: string;
  protocol: string;
  health: string;
  killSwitchEnabled: boolean;
}

export interface ConnectorCallResult {
  ok: boolean;
  reason?: 'connector' | 'consent_revoked';
}

// The three live department portals (see LIVE_DEPARTMENT_PORTALS_PLAN.md) — each a
// genuinely separate service/protocol/database, not a stub. Exported so
// WorkflowService can tell "step is done" apart from "step was accepted for async
// review" without either side hardcoding the department list twice.
export const LIVE_DEPARTMENTS = new Set(['Business Registry Portal', 'License Authority Portal', 'Revenue Department Portal']);

// Base URL per department, same env vars the call methods below already use —
// reused here to real-ping each adapter's own /health route before returning the
// registry, instead of only ever reflecting the manual admin kill-switch.
const HEALTH_CHECK_URL: Record<string, string> = {
  'Identity Service': `${process.env.IDENTITY_ADAPTER_URL ?? 'http://identity-adapter:4000'}/health`,
  'Business Registry': `${process.env.BUSINESS_REGISTRY_ADAPTER_URL ?? 'http://business-registry-adapter:4001'}/health`,
  'Revenue Department': `${process.env.REVENUE_ADAPTER_URL ?? 'http://revenue-adapter:4002'}/health`,
  'Municipal Corporation': `${process.env.MUNICIPAL_ADAPTER_URL ?? 'http://municipal-adapter:4003'}/health`,
  'License Authority': `${process.env.LICENSE_AUTHORITY_ADAPTER_URL ?? 'http://license-authority-adapter:4004'}/health`,
  'Business Registry Portal': `${process.env.BUSINESS_REGISTRY_PORTAL_URL ?? 'http://business-registry-portal:4301'}/health`,
  'License Authority Portal': `${process.env.LICENSE_AUTHORITY_PORTAL_URL ?? 'http://license-authority-portal:4302'}/health`,
  'Revenue Department Portal': `${process.env.REVENUE_PORTAL_URL ?? 'http://revenue-portal:4303'}/health`,
};

async function pingHealthy(url: string): Promise<boolean> {
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(2000) });
    return res.ok;
  } catch {
    return false;
  }
}

const PROTOCOL_BY_DEPARTMENT: Record<string, string> = {
  'Identity Service': 'OAuth',
  'Business Registry': 'SOAP',
  'Revenue Department': 'REST',
  'Municipal Corporation': 'DB',
  'License Authority': 'GraphQL',
  'Business Registry Portal': 'SOAP',
  'License Authority Portal': 'GraphQL',
  'Revenue Department Portal': 'REST',
};

interface CanonicalCasePayload {
  applicationId: string;
  applicationType: string;
  submittedOn: string;
  citizen: {
    masterId: string;
    name: string;
    consentedDataCategory: string;
    address: string | null;
    dateOfBirth: string | null;
    phoneNumber: string | null;
    employmentStatus: string | null;
  };
  /** `url` is a signed pointer back to OneDesk, not the bytes — see
   * InteropController.document for why the file itself never travels. */
  documents: { docId: string; type: string; status: string; mimeType: string | null; url: string }[];
  requestedAt: string;
}

/**
 * The only place that knows department-specific integration quirks (protocol,
 * request/response shape). Everything upstream (WorkflowService) only ever calls
 * these named methods and gets back a canonical {ok, detail} — same principle as the
 * HLD's connector/adapter framework: isolate legacy quirks here, not in the workflow.
 */
@Injectable()
export class ConnectorsService {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async listRegistry(): Promise<ConnectorRegistryRow[]> {
    const { rows } = await this.pool.query('SELECT * FROM connector_registry ORDER BY name');

    // Real reachability, not just the manual kill-switch — a kill-switched connector
    // stays 'Down' regardless of the ping (that's an explicit admin override), but a
    // non-killed one now reflects whether its adapter actually answered just now.
    await Promise.all(
      rows
        .filter((r) => !r.kill_switch_enabled && HEALTH_CHECK_URL[r.name])
        .map(async (r) => {
          const healthy = await pingHealthy(HEALTH_CHECK_URL[r.name]);
          const health = healthy ? 'Healthy' : 'Down';
          if (health !== r.health) {
            await this.pool.query('UPDATE connector_registry SET health = $2 WHERE name = $1', [r.name, health]);
          }
          r.health = health;
        }),
    );

    return rows.map((r) => ({ name: r.name, protocol: r.protocol, health: r.health, killSwitchEnabled: r.kill_switch_enabled }));
  }

  async isKilled(department: string): Promise<boolean> {
    const { rows } = await this.pool.query('SELECT kill_switch_enabled FROM connector_registry WHERE name = $1', [department]);
    return rows.length > 0 ? rows[0].kill_switch_enabled : false;
  }

  async setKillSwitch(department: string, enabled: boolean): Promise<void> {
    await this.pool.query(
      `UPDATE connector_registry SET kill_switch_enabled = $2, health = $3 WHERE name = $1`,
      [department, enabled, enabled ? 'Down' : 'Healthy'],
    );
  }

  /** Real OAuth/OIDC-shaped token-introspection call against the identity-adapter
   * service (RFC 7662 shape) — no longer inline-faked. */
  async verifyIdentity(applicationId: string): Promise<ConnectorCallResult> {
    const base = process.env.IDENTITY_ADAPTER_URL ?? 'http://identity-adapter:4000';
    const res = await fetch(`${base}/introspect`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ applicationId }),
      signal: AbortSignal.timeout(5000),
    });
    const body = await res.json();
    return { ok: res.ok && body.active === true, reason: 'connector' };
  }

  async verifyBusinessRegistry(applicationId: string): Promise<ConnectorCallResult> {
    const base = process.env.BUSINESS_REGISTRY_ADAPTER_URL ?? 'http://business-registry-adapter:4001';
    const xml = `<VerifyBusinessRequest><ApplicationId>${applicationId}</ApplicationId></VerifyBusinessRequest>`;
    const res = await fetch(`${base}/verify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/xml' },
      body: xml,
      signal: AbortSignal.timeout(5000),
    });
    const text = await res.text();
    return { ok: res.ok && text.includes('VERIFIED'), reason: 'connector' };
  }

  // Content for the consent request a blocked department needs — single source of
  // truth for both the inline auto-create below and ConsentsService's self-heal
  // reconciliation (a step can end up blocked-on-consent with no request yet if it
  // blocked before this content existed, or the process restarted mid-call).
  private static readonly CONSENT_REQUEST_CONTENT: Record<string, { purpose: string; dataRequested: string[] }> = {
    'Revenue Department': {
      purpose: 'Tax Verification for Business License Processing',
      dataRequested: ['Business Income Details'],
    },
    'Business Registry Portal': {
      purpose: 'Business Registration Review for Trade & Establishment Clearance',
      dataRequested: ['Identity & Address Details'],
    },
    'License Authority Portal': {
      purpose: 'License Eligibility Review for Trade & Establishment Clearance',
      dataRequested: ['Identity & Address Details'],
    },
    'Revenue Department Portal': {
      purpose: 'Revenue Clearance for Trade & Establishment Clearance',
      dataRequested: ['Identity & Address Details'],
    },
  };

  /** Idempotent — safe to call on every blocked check/reconciliation pass. */
  async ensureConsentRequest(department: string, citizenMasterId: string): Promise<void> {
    const content = ConnectorsService.CONSENT_REQUEST_CONTENT[department];
    if (!content) return;
    await this.pool.query(
      `INSERT INTO pending_consent_requests (id, department, purpose, data_requested, requested_on, citizen_master_id)
       VALUES ($1, $2, $3, $4, CURRENT_DATE, $5)
       ON CONFLICT (id) DO NOTHING`,
      [`req-consent-${department.toLowerCase().replace(/\s+/g, '-')}-${citizenMasterId}`, department, content.purpose, content.dataRequested, citizenMasterId],
    );
  }

  /**
   * Consent enforcement lives here, not just logged after the fact: a missing or
   * revoked consent blocks the call before it ever reaches the Revenue Department
   * adapter — the platform's "access without valid consent is blocked outright"
   * claim, made real for the con-1001 (Business Income Details) consent record.
   */
  async verifyRevenue(applicationId: string, citizenMasterId: string | null): Promise<ConnectorCallResult> {
    if (citizenMasterId) {
      const { rows } = await this.pool.query(
        `SELECT 1 FROM consents WHERE department = 'Revenue Department' AND citizen_master_id = $1 AND status = 'Active' AND valid_until >= CURRENT_DATE`,
        [citizenMasterId],
      );
      if (rows.length === 0) {
        // Blocking the call is only half the job — the citizen also needs something
        // to actually grant. Without this, "Grant consent to resume" pointed at a My
        // Consents page with nothing on it.
        await this.ensureConsentRequest('Revenue Department', citizenMasterId);
        return { ok: false, reason: 'consent_revoked' };
      }
    }

    const base = process.env.REVENUE_ADAPTER_URL ?? 'http://revenue-adapter:4002';
    const res = await fetch(`${base}/verify-tax`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ applicationId }),
      signal: AbortSignal.timeout(5000),
    });
    const body = await res.json();
    return { ok: res.ok && body.status === 'VERIFIED', reason: 'connector' };
  }

  async reviewMunicipal(applicationId: string): Promise<ConnectorCallResult> {
    const base = process.env.MUNICIPAL_ADAPTER_URL ?? 'http://municipal-adapter:4003';
    const res = await fetch(`${base}/review`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ applicationId }),
      signal: AbortSignal.timeout(5000),
    });
    const body = await res.json();
    return { ok: res.ok && body.status === 'REVIEWED', reason: 'connector' };
  }

  async approveLicenseAuthority(applicationId: string): Promise<ConnectorCallResult> {
    const base = process.env.LICENSE_AUTHORITY_ADAPTER_URL ?? 'http://license-authority-adapter:4004';
    const query = `mutation Approve($applicationId: ID!) { approveApplication(applicationId: $applicationId) { applicationId status } }`;
    const res = await fetch(`${base}/graphql`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, variables: { applicationId } }),
      signal: AbortSignal.timeout(5000),
    });
    const body = await res.json();
    return { ok: res.ok && body?.data?.approveApplication?.status === 'APPROVED', reason: 'connector' };
  }

  /**
   * The real canonical contract for the three live department portals — built fresh
   * per department because consent scopes what's actually included, not just whether
   * the call proceeds (§4/§8 of LIVE_DEPARTMENT_PORTALS_PLAN.md). Returns null when
   * consent is missing, after auto-creating the request the citizen needs to grant —
   * same self-heal pattern as verifyRevenue.
   */
  private async buildCanonicalPayload(
    department: string,
    applicationId: string,
    citizenMasterId: string,
  ): Promise<CanonicalCasePayload | null> {
    const { rows: consentRows } = await this.pool.query(
      `SELECT data_category FROM consents WHERE department = $1 AND citizen_master_id = $2 AND status = 'Active' AND valid_until >= CURRENT_DATE LIMIT 1`,
      [department, citizenMasterId],
    );
    if (consentRows.length === 0) {
      await this.ensureConsentRequest(department, citizenMasterId);
      return null;
    }

    const [{ rows: appRows }, { rows: citizenRows }, { rows: docRows }] = await Promise.all([
      this.pool.query('SELECT service, citizen_name, submitted_on FROM applications WHERE id = $1', [applicationId]),
      this.pool.query(
        'SELECT address, date_of_birth, phone_number, employment_status FROM master_identity WHERE master_id = $1',
        [citizenMasterId],
      ),
      this.pool.query('SELECT id, name, status, mime_type FROM documents WHERE application_id = $1', [applicationId]),
    ]);

    // Signed pointers back to OneDesk, valid for this department and this
    // application only — the department's own backend fetches through them, the
    // bytes never ride along with the submit payload.
    const slug = SLUG_BY_DEPARTMENT[department] ?? '';
    const expiresAt = Date.now() + DOC_URL_TTL_MS;
    const publicBase = process.env.INTEROP_PUBLIC_BASE_URL ?? 'http://core-api:3000';

    return {
      applicationId,
      applicationType: appRows[0]?.service ?? 'Unknown',
      submittedOn: appRows[0]?.submitted_on ? new Date(appRows[0].submitted_on).toISOString().slice(0, 10) : '',
      citizen: {
        masterId: citizenMasterId,
        name: appRows[0]?.citizen_name ?? 'Unknown',
        consentedDataCategory: consentRows[0].data_category,
        address: citizenRows[0]?.address ?? null,
        dateOfBirth: citizenRows[0]?.date_of_birth ? new Date(citizenRows[0].date_of_birth).toISOString().slice(0, 10) : null,
        phoneNumber: citizenRows[0]?.phone_number ?? null,
        employmentStatus: citizenRows[0]?.employment_status ?? null,
      },
      documents: docRows.map((d) => ({
        docId: d.id,
        type: d.name,
        status: d.status,
        mimeType: d.mime_type ?? null,
        url: `${publicBase}/interop/documents/${slug}/${applicationId}/${d.id}?exp=${expiresAt}&sig=${signDocumentAccess(d.id, applicationId, department, expiresAt)}`,
      })),
      requestedAt: new Date().toISOString(),
    };
  }

  /** Business Registry Portal — legacy SOAP/XML, own MySQL database. */
  private async submitSoap(payload: CanonicalCasePayload): Promise<ConnectorCallResult> {
    const base = process.env.BUSINESS_REGISTRY_PORTAL_URL ?? 'http://business-registry-portal:4301';
    const builder = new Builder({ headless: true });
    const xml = builder.buildObject({
      SubmitCaseRequest: {
        ApplicationId: payload.applicationId,
        ApplicationType: payload.applicationType,
        SubmittedOn: payload.submittedOn,
        CitizenMasterId: payload.citizen.masterId,
        CitizenName: payload.citizen.name,
        ConsentedDataCategory: payload.citizen.consentedDataCategory,
        Address: payload.citizen.address ?? '',
        DateOfBirth: payload.citizen.dateOfBirth ?? '',
        PhoneNumber: payload.citizen.phoneNumber ?? '',
        EmploymentStatus: payload.citizen.employmentStatus ?? '',
        Documents: {
          Document: payload.documents.map((d) => ({
            DocId: d.docId,
            Type: d.type,
            MimeType: d.mimeType ?? '',
            Url: d.url,
          })),
        },
      },
    });
    const res = await fetch(`${base}/soap/submit`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/xml' },
      body: xml,
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return { ok: false, reason: 'connector' };
    const parsed = await parseStringPromise(await res.text());
    return { ok: parsed?.SubmitCaseResponse?.Accepted?.[0] === 'true', reason: 'connector' };
  }

  /** License Authority Portal — GraphQL, own MongoDB database. */
  private async submitGraphQl(payload: CanonicalCasePayload): Promise<ConnectorCallResult> {
    const base = process.env.LICENSE_AUTHORITY_PORTAL_URL ?? 'http://license-authority-portal:4302';
    const query = `mutation Submit($input: SubmitCaseInput!) { submitCase(input: $input) { accepted } }`;
    const variables = {
      input: {
        applicationId: payload.applicationId,
        applicationType: payload.applicationType,
        submittedOn: payload.submittedOn,
        citizenMasterId: payload.citizen.masterId,
        citizenName: payload.citizen.name,
        consentedDataCategory: payload.citizen.consentedDataCategory,
        address: payload.citizen.address,
        dateOfBirth: payload.citizen.dateOfBirth,
        phoneNumber: payload.citizen.phoneNumber,
        employmentStatus: payload.citizen.employmentStatus,
        documents: payload.documents.map((d) => ({ docId: d.docId, type: d.type, mimeType: d.mimeType, url: d.url })),
      },
    };
    const res = await fetch(`${base}/graphql`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query, variables }),
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return { ok: false, reason: 'connector' };
    const body = await res.json();
    return { ok: body?.data?.submitCase?.accepted === true, reason: 'connector' };
  }

  /** Revenue Department Portal — REST/JSON, own Postgres database. */
  private async submitRest(payload: CanonicalCasePayload): Promise<ConnectorCallResult> {
    const base = process.env.REVENUE_PORTAL_URL ?? 'http://revenue-portal:4303';
    const res = await fetch(`${base}/api/cases`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(5000),
    });
    if (!res.ok) return { ok: false, reason: 'connector' };
    const body = await res.json();
    return { ok: body.accepted === true, reason: 'connector' };
  }

  /**
   * Submits a case to a live department portal for asynchronous human review.
   * "ok: true" here means "accepted for review," not "reviewed" — the actual
   * decision arrives later via the signed /interop/dept-callback webhook
   * (WorkflowService.handleDeptCallback), never as this call's return value.
   */
  async submitToLiveDepartment(
    department: string,
    applicationId: string,
    citizenMasterId: string | null,
  ): Promise<ConnectorCallResult> {
    if (!citizenMasterId) return { ok: false, reason: 'connector' };
    const payload = await this.buildCanonicalPayload(department, applicationId, citizenMasterId);
    if (!payload) return { ok: false, reason: 'consent_revoked' };

    switch (department) {
      case 'Business Registry Portal':
        return this.submitSoap(payload);
      case 'License Authority Portal':
        return this.submitGraphQl(payload);
      case 'Revenue Department Portal':
        return this.submitRest(payload);
      default:
        return { ok: false, reason: 'connector' };
    }
  }

  async callForDepartment(department: string, applicationId: string, citizenMasterId: string | null): Promise<ConnectorCallResult> {
    const result = await this.dispatch(department, applicationId, citizenMasterId);
    connectorCallsTotal.inc({ department, outcome: result.ok ? 'success' : result.reason === 'consent_revoked' ? 'consent_denied' : 'failure' });

    // The protocol-level interoperability event itself — which department, which
    // protocol, what came back — distinct from workflow.service.ts's audit row,
    // which only records the higher-level "did this timeline step succeed."
    const protocol = PROTOCOL_BY_DEPARTMENT[department] ?? 'unknown';
    await this.pool.query(
      `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose)
       VALUES ($1, 'System', $2, 'DATA_REQUEST', $3, $4, 'Interoperability data request')`,
      [
        `aud-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
        department,
        `${applicationId}: requested from ${department} adapter (${protocol})`,
        result.ok ? 'Success' : 'Failed',
      ],
    );

    return result;
  }

  private async dispatch(department: string, applicationId: string, citizenMasterId: string | null): Promise<ConnectorCallResult> {
    switch (department) {
      case 'Identity Service':
        return this.verifyIdentity(applicationId);
      case 'Business Registry':
        return this.verifyBusinessRegistry(applicationId);
      case 'Revenue Department':
        return this.verifyRevenue(applicationId, citizenMasterId);
      case 'Municipal Corporation':
        return this.reviewMunicipal(applicationId);
      case 'License Authority':
        return this.approveLicenseAuthority(applicationId);
      case 'Business Registry Portal':
      case 'License Authority Portal':
      case 'Revenue Department Portal':
        return this.submitToLiveDepartment(department, applicationId, citizenMasterId);
      default:
        // Non-flagship generic services have no real connector — treat as a no-op success.
        return { ok: true, reason: 'connector' };
    }
  }
}
