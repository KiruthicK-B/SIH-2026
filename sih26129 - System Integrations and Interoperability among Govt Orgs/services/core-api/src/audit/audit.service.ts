import { BadRequestException, Inject, Injectable } from '@nestjs/common';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';
import type { AuditLogEntry } from './audit.types';

export interface AuditFilters {
  department?: string;
  action?: string;
  result?: string;
  date?: string; // YYYY-MM-DD prefix match, mirrors the frontend's `.startsWith(date)` filter
}

@Injectable()
export class AuditService {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async list(filters: AuditFilters): Promise<AuditLogEntry[]> {
    const clauses: string[] = [];
    const params: unknown[] = [];

    if (filters.department && filters.department !== 'all') {
      params.push(filters.department);
      clauses.push(`department = $${params.length}`);
    }
    if (filters.action && filters.action !== 'all') {
      params.push(filters.action);
      clauses.push(`action = $${params.length}`);
    }
    if (filters.result && filters.result !== 'all') {
      params.push(filters.result);
      clauses.push(`result = $${params.length}`);
    }
    if (filters.date) {
      params.push(`${filters.date}%`);
      clauses.push(`to_char(ts, 'YYYY-MM-DD') LIKE $${params.length}`);
    }

    const where = clauses.length > 0 ? `WHERE ${clauses.join(' AND ')}` : '';
    const { rows } = await this.pool.query(`SELECT * FROM audit_log ${where} ORDER BY ts DESC`, params);

    return rows.map((r) => ({
      id: r.id,
      timestamp: new Date(r.ts).toISOString(),
      actor: r.actor,
      department: r.department,
      action: r.action,
      resource: r.resource,
      result: r.result,
      purpose: r.purpose ?? undefined,
      consentId: r.consent_id ?? undefined,
    }));
  }

  async listDistinct(column: 'department' | 'action'): Promise<string[]> {
    // Defense-in-depth: only ever called with the two literals in the type above
    // today, but a runtime whitelist means a future careless call site can't turn
    // this into SQL injection via the column name.
    if (column !== 'department' && column !== 'action') throw new BadRequestException('invalid column');
    const { rows } = await this.pool.query(`SELECT DISTINCT ${column} FROM audit_log ORDER BY ${column}`);
    return rows.map((r) => r[column]);
  }
}
