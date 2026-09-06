import { Controller, Get, Inject, UseGuards } from '@nestjs/common';
import type { Pool } from 'pg';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { PG_POOL } from '../db/db.module';

// department_identifiers rows were seeded with short department names (pre-dating
// the full "X Department" names used elsewhere) — this maps the real department name
// to the identifier-table's name so identity resolution can be joined honestly,
// rather than fuzzy-matching strings.
const IDENTITY_DEPARTMENT_ALIASES: Record<string, string> = {
  'Revenue Department': 'Revenue',
  'Education Department': 'Education',
  'Social Welfare Department': 'Welfare',
  'Business Registry': 'Business Registry',
};

@Controller('data-mapping')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('platform-admin')
export class DataMappingController {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  @Get()
  async get() {
    const [depts, flows, identifiers] = await Promise.all([
      this.pool.query(`
        SELECT d.*, c.protocol AS connector_protocol, c.health AS connector_health, c.kill_switch_enabled
        FROM departments d
        LEFT JOIN connector_registry c ON c.name = d.name
        ORDER BY d.name
      `),
      this.pool.query('SELECT * FROM adapter_data_flows ORDER BY department, step_order'),
      this.pool.query(`
        SELECT di.department, di.identifier, di.confidence, mi.citizen_name, mi.master_id
        FROM department_identifiers di
        JOIN master_identity mi ON mi.master_id = di.master_id
      `),
    ]);

    const flowsByDept = new Map<string, typeof flows.rows>();
    for (const f of flows.rows) {
      const list = flowsByDept.get(f.department) ?? [];
      list.push(f);
      flowsByDept.set(f.department, list);
    }

    const identifiersByAlias = new Map<string, (typeof identifiers.rows)[number]>();
    for (const i of identifiers.rows) {
      identifiersByAlias.set(i.department, i);
    }

    // Real connectors only — this tab claims "live connectors only, no illustrative
    // filler"; departments with no adapter behind them have no actual data flow to
    // map, so they don't belong on this diagram (they still show up honestly
    // elsewhere, e.g. Departments/Data Standards, as manually-processed).
    return depts.rows
      .filter((d) => d.connector_health != null)
      .map((d) => {
        const hasLiveConnector = d.connector_health != null;
        const alias = IDENTITY_DEPARTMENT_ALIASES[d.name];
        const identity = alias ? identifiersByAlias.get(alias) : undefined;

        return {
          id: d.id,
          name: d.name,
          description: d.description,
          interfaceType: d.interface_type,
          modernizationPercent: d.modernization_percent,
          protocol: d.connector_protocol ?? 'Manual',
          health: d.connector_health ?? 'Manual Processing',
          hasLiveConnector,
          killSwitchEnabled: d.kill_switch_enabled ?? false,
          dataFlows: (flowsByDept.get(d.name) ?? []).map((f) => ({
            direction: f.direction,
            field: f.field,
            canonicalField: f.canonical_field,
            sampleValue: f.sample_value,
          })),
          identityResolution: identity
            ? {
                masterId: identity.master_id,
                citizenName: identity.citizen_name,
                departmentIdentifier: identity.identifier,
                confidence: identity.confidence != null ? Number(identity.confidence) : null,
              }
            : null,
        };
      });
  }
}
