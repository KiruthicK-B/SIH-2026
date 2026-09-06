import { Controller, Get, Inject, UseGuards } from '@nestjs/common';
import type { Pool } from 'pg';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { PG_POOL } from '../db/db.module';

// Everything below is a fact about this repository's actual code/config, not
// runtime state — kept here (not duplicated in the frontend) so there is one
// source of truth. Each entry cites where it came from.
const ADAPTER_INFO: Record<string, { port: number; framework: string; route: string; source: string }> = {
  'Identity Service': {
    port: 4000,
    framework: 'Node/Express',
    route: 'POST /introspect',
    source: 'connectors.service.ts:verifyIdentity',
  },
  'Business Registry': {
    port: 4001,
    framework: 'Node/Express + xml2js (SOAP)',
    route: 'POST /verify',
    source: 'connectors.service.ts:verifyBusinessRegistry',
  },
  'Revenue Department': {
    port: 4002,
    framework: 'Node/Express',
    route: 'POST /verify-tax',
    source: 'connectors.service.ts:verifyRevenue',
  },
  'Municipal Corporation': {
    port: 4003,
    framework: 'Node/Express + pg (own Postgres DB)',
    route: 'POST /review',
    source: 'connectors.service.ts:reviewMunicipal',
  },
  'License Authority': {
    port: 4004,
    framework: 'Node/Express + graphql-yoga',
    route: 'POST /graphql (mutation approveApplication)',
    source: 'connectors.service.ts:approveLicenseAuthority',
  },
};

const CORE_API_ROUTES = [
  'applications',
  'consents',
  'audit',
  'admin/connectors',
  'admin/traffic-summary',
  'admin/recent-events',
  'schema/field-mappings',
  'departments',
  'identity',
  'auth/resolve-identifier',
  'services',
  'sla',
  'data-quality',
  'notifications',
  'documents',
  'grievances',
  'data-mapping',
  'architecture',
];

async function pingHealthy(url: string): Promise<boolean> {
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(2000) });
    return res.ok;
  } catch {
    return false;
  }
}

@Controller('architecture')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('platform-admin')
export class ArchitectureController {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  @Get()
  async get() {
    const [mdmHealthy, kongHealthy, keycloakHealthy, { rows: connectors }] = await Promise.all([
      pingHealthy(`${process.env.MDM_SERVICE_URL ?? 'http://mdm-service:8000'}/health`),
      pingHealthy(`${process.env.KONG_ADMIN_URL ?? 'http://kong:8001'}/status`),
      // Keycloak 26 exposes health on its separate management port (9000), not 8080.
      pingHealthy(`${process.env.KEYCLOAK_HEALTH_URL ?? 'http://keycloak:9000'}/health/ready`),
      this.pool.query('SELECT * FROM connector_registry ORDER BY name'),
    ]);

    const adapters = connectors.map((c) => ({
      id: c.name,
      name: c.name,
      protocol: c.protocol,
      health: c.health,
      killSwitchEnabled: c.kill_switch_enabled,
      port: ADAPTER_INFO[c.name]?.port ?? null,
      framework: ADAPTER_INFO[c.name]?.framework ?? 'Node/Express',
      route: ADAPTER_INFO[c.name]?.route ?? null,
      source: ADAPTER_INFO[c.name]?.source ?? 'connector_registry table',
    }));

    return {
      identityProvider: {
        id: 'keycloak',
        name: 'Keycloak',
        role: 'OIDC identity provider — issues the role/department claims every login relies on',
        port: 8080,
        healthy: keycloakHealthy,
        source: 'docker-compose.yml:keycloak',
      },
      gateway: {
        id: 'kong',
        name: 'Kong',
        role: 'Single entry point from the browser — routing, CORS, rate-limiting',
        port: 8010,
        healthy: kongHealthy,
        routes: ['/api/* → core-api (strip_path)', '/mdm/* → mdm-service (strip_path)'],
        source: 'gateway/kong.yml',
      },
      services: [
        {
          id: 'core-api',
          name: 'core-api',
          framework: 'NestJS 10 (TypeScript)',
          role: 'Modular monolith — workflow orchestration, consent enforcement, canonical field mapping, audit log',
          port: 3000,
          healthy: true, // trivially true — this response only exists if core-api is up
          routes: CORE_API_ROUTES,
          source: 'core-api/src/app.module.ts',
        },
        {
          id: 'mdm-service',
          name: 'mdm-service',
          framework: 'FastAPI (Python)',
          role: 'Master data management — fuzzy/synonym field-mapping suggestions for onboarding a new department connector',
          port: 8000,
          healthy: mdmHealthy,
          routes: ['GET /health', 'POST /suggest-mapping', 'GET /canonical-fields'],
          source: 'mdm-service/main.py',
        },
      ],
      databases: [
        {
          id: 'db-core-api',
          name: 'Postgres — core_api',
          role: 'Canonical store for core-api: applications, consents, audit log, departments, connector registry',
          usedBy: ['core-api'],
          source: 'docker-compose.yml:core-api DATABASE_URL',
        },
        {
          id: 'db-municipal',
          name: 'Postgres — municipal_adapter',
          role: "Municipal Corporation's own database, written directly by its adapter — not shared with core-api",
          usedBy: ['municipal-adapter'],
          source: 'connectors/municipal-adapter/index.js',
        },
      ],
      adapters,
      // Real edges only — every entry here corresponds to an actual fetch()/pg call
      // in the codebase, cited by source.
      edges: [
        { from: 'frontend', to: 'kong', protocol: 'HTTPS', label: 'Browser calls Kong', source: 'onedesk/src/lib/api.ts' },
        { from: 'frontend', to: 'keycloak', protocol: 'OIDC', label: 'Login (direct, not via Kong)', source: 'onedesk/src/lib/keycloak.ts' },
        { from: 'kong', to: 'core-api', protocol: 'REST', label: '/api/*', source: 'gateway/kong.yml' },
        { from: 'kong', to: 'mdm-service', protocol: 'REST', label: '/mdm/*', source: 'gateway/kong.yml' },
        { from: 'core-api', to: 'keycloak', protocol: 'JWKS', label: 'Token verification', source: 'docker-compose.yml:KEYCLOAK_JWKS_URI' },
        { from: 'core-api', to: 'db-core-api', protocol: 'DB', label: 'pg pool', source: 'core-api/src/db/db.module.ts' },
        { from: 'municipal-adapter', to: 'db-municipal', protocol: 'DB', label: 'pg pool (own DB)', source: 'connectors/municipal-adapter/index.js' },
        ...adapters.map((a) => ({
          from: a.id,
          to: 'core-api',
          protocol: a.protocol,
          label: a.route ?? '',
          source: a.source,
        })),
      ],
    };
  }
}
