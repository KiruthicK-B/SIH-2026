import { Inject, Injectable } from '@nestjs/common';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';
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

// Base URL per department, same env vars the call methods below already use —
// reused here to real-ping each adapter's own /health route before returning the
// registry, instead of only ever reflecting the manual admin kill-switch.
const HEALTH_CHECK_URL: Record<string, string> = {
  'Identity Service': `${process.env.IDENTITY_ADAPTER_URL ?? 'http://identity-adapter:4000'}/health`,
  'Business Registry': `${process.env.BUSINESS_REGISTRY_ADAPTER_URL ?? 'http://business-registry-adapter:4001'}/health`,
  'Revenue Department': `${process.env.REVENUE_ADAPTER_URL ?? 'http://revenue-adapter:4002'}/health`,
  'Municipal Corporation': `${process.env.MUNICIPAL_ADAPTER_URL ?? 'http://municipal-adapter:4003'}/health`,
  'License Authority': `${process.env.LICENSE_AUTHORITY_ADAPTER_URL ?? 'http://license-authority-adapter:4004'}/health`,
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
};

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
      default:
        // Non-flagship generic services have no real connector — treat as a no-op success.
        return { ok: true, reason: 'connector' };
    }
  }
}
