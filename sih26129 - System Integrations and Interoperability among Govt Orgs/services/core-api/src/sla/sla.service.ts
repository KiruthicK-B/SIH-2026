import { Inject, Injectable } from '@nestjs/common';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';

interface SlaRuleRow {
  label: string;
  target_label: string;
  target_hours: string;
  current_label: string;
  current_hours: string;
  within_sla: boolean;
}

// Which real rows back each SLA rule's "actual" measurement — policy-as-code, same
// convention as EligibilityService's department rules. `step` rules measure a single
// timeline step's real turnaround (submitted_on -> step_date, done steps only);
// `application` measures a whole flagship flow's real turnaround (submitted_on ->
// last_updated, completed only).
const SLA_MATCHERS: Record<string, { type: 'step'; labelLike: string } | { type: 'application'; service: string }> = {
  'Business License (end-to-end)': { type: 'application', service: 'Business License' },
  'Identity Verification': { type: 'step', labelLike: '%Identity%' },
  'Municipal Verification': { type: 'step', labelLike: '%Municipal%' },
  'Tax Verification': { type: 'step', labelLike: '%Tax%' },
};

/**
 * Recomputes each SLA rule's "actual" side from real applications/timeline_steps
 * timestamps — this used to always show the seeded value, never the live one.
 * `target_hours` stays exactly as configured (a real target isn't "fake data").
 * step_date/submitted_on are DATE columns, not TIMESTAMPTZ, so real precision here
 * is whole days — reported honestly in hours (days * 24), not invented sub-day
 * figures the schema can't actually back.
 */
@Injectable()
export class SlaService {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async computeAndPersist(): Promise<void> {
    const { rows } = await this.pool.query<SlaRuleRow>('SELECT * FROM sla_rules');

    for (const rule of rows) {
      const matcher = SLA_MATCHERS[rule.label];
      if (!matcher) continue;

      const avgHours =
        matcher.type === 'application'
          ? await this.avgApplicationHours(matcher.service)
          : await this.avgStepHours(matcher.labelLike);

      // No real applications for this rule yet — keep the seeded fallback rather
      // than showing a misleading zero.
      if (avgHours === null) continue;

      const currentLabel = this.formatHours(avgHours);
      const withinSla = avgHours <= Number(rule.target_hours);
      await this.pool.query(
        `UPDATE sla_rules SET current_hours = $2, current_label = $3, within_sla = $4 WHERE label = $1`,
        [rule.label, avgHours, currentLabel, withinSla],
      );
    }

    const { rows: allRules } = await this.pool.query<SlaRuleRow>('SELECT within_sla FROM sla_rules');
    const compliance = allRules.length > 0 ? (100 * allRules.filter((r) => r.within_sla).length) / allRules.length : 0;
    await this.pool.query(
      `UPDATE platform_stats SET value = $1 WHERE key = 'overall_sla_compliance'`,
      [Math.round(compliance * 10) / 10],
    );
  }

  private async avgApplicationHours(service: string): Promise<number | null> {
    // last_updated/submitted_on are DATE columns — DATE - DATE yields an integer
    // day count in Postgres, not an interval, so this is a plain multiply, not
    // extract(epoch FROM ...).
    const { rows } = await this.pool.query(
      `SELECT avg((last_updated - submitted_on) * 24.0) AS hours
       FROM applications WHERE service = $1 AND status = 'Completed'`,
      [service],
    );
    return rows[0]?.hours != null ? Number(rows[0].hours) : null;
  }

  private async avgStepHours(labelLike: string): Promise<number | null> {
    const { rows } = await this.pool.query(
      `SELECT avg((t.step_date - a.submitted_on) * 24.0) AS hours
       FROM timeline_steps t
       JOIN applications a ON a.id = t.application_id
       WHERE t.label ILIKE $1 AND t.status = 'done' AND t.step_date IS NOT NULL`,
      [labelLike],
    );
    return rows[0]?.hours != null ? Number(rows[0].hours) : null;
  }

  private formatHours(hours: number): string {
    if (hours < 24) return `${Math.round(hours)} hours`;
    const days = Math.round((hours / 24) * 10) / 10;
    return `${days} days`;
  }
}
