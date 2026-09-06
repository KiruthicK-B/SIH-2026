import { Controller, Get, Inject, UseGuards } from '@nestjs/common';
import type { Pool } from 'pg';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { PG_POOL } from '../db/db.module';
import { SlaService } from './sla.service';

@Controller('sla')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('officer', 'platform-admin')
export class SlaController {
  constructor(
    @Inject(PG_POOL) private readonly pool: Pool,
    private readonly sla: SlaService,
  ) {}

  @Get()
  async get() {
    await this.sla.computeAndPersist();

    const [{ rows }, { rows: statRows }] = await Promise.all([
      this.pool.query('SELECT * FROM sla_rules ORDER BY label'),
      this.pool.query(`SELECT value FROM platform_stats WHERE key = 'overall_sla_compliance'`),
    ]);
    const entries = rows.map((r) => ({
      label: r.label,
      targetLabel: r.target_label,
      targetHours: Number(r.target_hours),
      currentLabel: r.current_label,
      currentHours: Number(r.current_hours),
      withinSla: r.within_sla,
    }));
    return { overallCompliance: statRows.length > 0 ? Number(statRows[0].value) : 0, entries };
  }
}
