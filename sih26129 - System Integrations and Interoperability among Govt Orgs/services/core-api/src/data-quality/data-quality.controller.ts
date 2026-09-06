import { Controller, Get, Inject, UseGuards } from '@nestjs/common';
import type { Pool } from 'pg';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { PG_POOL } from '../db/db.module';
import { DataQualityService } from './data-quality.service';

@Controller('data-quality')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('officer', 'platform-admin')
export class DataQualityController {
  constructor(
    @Inject(PG_POOL) private readonly pool: Pool,
    private readonly dataQuality: DataQualityService,
  ) {}

  @Get()
  async get() {
    await this.dataQuality.computeAndPersist();

    const [metrics, issues, byDepartment] = await Promise.all([
      this.pool.query('SELECT * FROM data_quality_metrics WHERE id = 1'),
      this.pool.query('SELECT label, count FROM data_quality_issues ORDER BY count DESC'),
      this.pool.query('SELECT department, valid_rate FROM data_quality_department_rates ORDER BY department'),
    ]);
    const m = metrics.rows[0];
    return {
      metrics: {
        recordsProcessed: m.records_processed,
        validRecords: m.valid_records,
        warnings: m.warnings,
        validationErrors: m.validation_errors,
      },
      issues: issues.rows.map((r) => ({ label: r.label, count: r.count })),
      byDepartment: byDepartment.rows.map((r) => ({ department: r.department, validRate: Number(r.valid_rate) })),
    };
  }
}
