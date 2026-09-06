import { Controller, Get, Inject, UseGuards } from '@nestjs/common';
import type { Pool } from 'pg';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PG_POOL } from '../db/db.module';

@Controller('departments')
@UseGuards(JwtAuthGuard)
export class DepartmentsController {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  @Get()
  async list() {
    // LEFT JOIN, not INNER: only 5 of 9 departments have a live automated connector
    // (see connector_registry) — the other 4 are honestly reported as manually
    // processed rather than faked as "Healthy", matching ModernizationTab's own story.
    const { rows } = await this.pool.query(`
      SELECT d.*, c.health AS connector_health, c.kill_switch_enabled
      FROM departments d
      LEFT JOIN connector_registry c ON c.name = d.name
      ORDER BY d.name
    `);
    return rows.map((r) => ({
      id: r.id,
      name: r.name,
      description: r.description,
      serviceCount: r.service_count,
      interfaceType: r.interface_type,
      onboardedOn: new Date(r.onboarded_on).toISOString().slice(0, 10),
      modernization: {
        percent: r.modernization_percent,
        target: r.modernization_target,
        status: r.modernization_status,
      },
      hasLiveConnector: r.connector_health != null,
      health: r.connector_health ?? 'Manual Processing',
      killSwitchEnabled: r.kill_switch_enabled ?? false,
    }));
  }
}
