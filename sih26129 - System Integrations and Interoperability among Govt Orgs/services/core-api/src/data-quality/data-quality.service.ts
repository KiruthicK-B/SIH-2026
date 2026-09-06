import { Inject, Injectable } from '@nestjs/common';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';

/**
 * Recomputes data-quality metrics/issues/department-rates from live tables on every
 * read — this used to be seeded once by SQL and never touched again (a frozen,
 * fake snapshot). Deliberately lightweight (regex/null checks, a referential-
 * integrity scan, a real per-department done/blocked ratio), not an enterprise MDM
 * validation engine — matches what this POC actually needs to demonstrate.
 */
@Injectable()
export class DataQualityService {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async computeAndPersist(): Promise<void> {
    const [missingRequired, invalidFormat, orphanedConsents, orphanedPending, recordCounts, departmentRates] = await Promise.all([
      this.pool.query(
        `SELECT count(*)::int AS n FROM master_identity
         WHERE citizen_name IS NULL OR phone_number IS NULL OR date_of_birth IS NULL`,
      ),
      this.pool.query(
        `SELECT count(*)::int AS n FROM master_identity
         WHERE (phone_number IS NOT NULL AND phone_number !~ '^\\d{10}$')
            OR (aadhaar_number IS NOT NULL AND aadhaar_number !~ '^\\d{12}$')`,
      ),
      this.pool.query(
        `SELECT count(*)::int AS n FROM consents c
         WHERE c.citizen_master_id IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM master_identity m WHERE m.master_id = c.citizen_master_id)`,
      ),
      this.pool.query(
        `SELECT count(*)::int AS n FROM pending_consent_requests p
         WHERE p.citizen_master_id IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM master_identity m WHERE m.master_id = p.citizen_master_id)`,
      ),
      this.pool.query(`SELECT (SELECT count(*) FROM master_identity) + (SELECT count(*) FROM applications) AS n`),
      this.pool.query(
        `SELECT department,
                round(100.0 * count(*) FILTER (WHERE status = 'done') / NULLIF(count(*) FILTER (WHERE status IN ('done', 'blocked')), 0), 1) AS valid_rate
         FROM timeline_steps
         GROUP BY department
         HAVING count(*) FILTER (WHERE status IN ('done', 'blocked')) > 0`,
      ),
    ]);

    const missing = missingRequired.rows[0].n as number;
    const invalid = invalidFormat.rows[0].n as number;
    const orphaned = (orphanedConsents.rows[0].n as number) + (orphanedPending.rows[0].n as number);
    const recordsProcessed = recordCounts.rows[0].n as number;
    const validRecords = Math.max(0, recordsProcessed - missing - invalid - orphaned);

    await this.pool.query(
      `UPDATE data_quality_metrics SET records_processed = $1, valid_records = $2, warnings = $3, validation_errors = $4 WHERE id = 1`,
      [recordsProcessed, validRecords, invalid, missing],
    );

    // Reuses the existing 3-row shape (label is the natural key here since the table
    // has no unique constraint on it — same three issue types every read, so a
    // straight UPDATE-by-label plus an insert-if-missing keeps it idempotent).
    for (const [label, count] of [
      ['Missing Required Field', missing],
      ['Invalid Format', invalid],
      ['Orphaned Consent Record', orphaned],
    ] as const) {
      const { rowCount } = await this.pool.query(
        `UPDATE data_quality_issues SET count = $2, status = $3 WHERE label = $1`,
        [label, count, count > 0 ? 'Quarantined' : 'Resolved'],
      );
      if (rowCount === 0) {
        await this.pool.query(
          `INSERT INTO data_quality_issues (label, count, status) VALUES ($1, $2, $3)`,
          [label, count, count > 0 ? 'Quarantined' : 'Resolved'],
        );
      }
    }

    // Only departments with real timeline_steps activity get overwritten — a
    // department nothing has been submitted for yet keeps its seeded placeholder
    // rather than showing a misleading 0%.
    for (const row of departmentRates.rows) {
      if (row.valid_rate == null) continue;
      await this.pool.query(
        `UPDATE data_quality_department_rates SET valid_rate = $2 WHERE department = $1`,
        [row.department, row.valid_rate],
      );
    }
  }
}
