import { Controller, Get, Inject, UseGuards } from '@nestjs/common';
import type { Pool } from 'pg';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { AuthenticatedUser } from '../auth/jwt.types';
import { PG_POOL } from '../db/db.module';

@Controller('grievances')
@UseGuards(JwtAuthGuard)
export class GrievancesController {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  @Get()
  async list(@CurrentUser() user: AuthenticatedUser) {
    const scope = user.roles.includes('citizen') ? (user.masterId ?? undefined) : undefined;
    const { rows } = scope
      ? await this.pool.query('SELECT * FROM grievances WHERE citizen_master_id = $1 ORDER BY filed_on DESC', [scope])
      : await this.pool.query('SELECT * FROM grievances ORDER BY filed_on DESC');
    return rows.map((r) => ({
      id: r.id,
      subject: r.subject,
      department: r.department,
      relatedApplication: r.related_application ?? undefined,
      status: r.status,
      filedOn: new Date(r.filed_on).toISOString().slice(0, 10),
      description: r.description,
    }));
  }
}
