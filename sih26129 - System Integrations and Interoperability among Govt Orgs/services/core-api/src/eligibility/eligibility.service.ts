import { Inject, Injectable } from '@nestjs/common';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';
import { findScope } from '../scopes/scope-catalog';

export interface EligibilityResult {
  eligible: boolean;
  reasons: string[];
}

function ageFrom(dateOfBirth: Date | null): number | null {
  if (!dateOfBirth) return null;
  const diffMs = Date.now() - new Date(dateOfBirth).getTime();
  return Math.floor(diffMs / (1000 * 60 * 60 * 24 * 365.25));
}

/**
 * Department-access eligibility, evaluated against the citizen's own declared
 * profile — not just "has a consent been ticked." Rules live here as code (they're
 * policy, not application data) and only cover the departments that actually need
 * one; everything else stays eligible-by-default, matching pre-existing behavior.
 */
@Injectable()
export class EligibilityService {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async checkEligibility(department: string, citizenMasterId: string | null): Promise<EligibilityResult> {
    if (!citizenMasterId) return { eligible: true, reasons: [] };

    const { rows } = await this.pool.query(
      'SELECT date_of_birth, employment_status, highest_qualification FROM master_identity WHERE master_id = $1',
      [citizenMasterId],
    );
    if (rows.length === 0) return { eligible: true, reasons: [] };

    const profile = rows[0];
    const age = ageFrom(profile.date_of_birth);
    const reasons: string[] = [];

    if (department === 'Revenue Department') {
      if (age === null || age < 21) reasons.push('Must be 21 years or older');
      if (profile.employment_status !== 'Employed') reasons.push('Must be currently employed');
      if (!profile.highest_qualification) reasons.push('Must have a registered educational qualification');
    } else if (department === 'RTO') {
      if (age === null || age < 18) reasons.push('Must be 18 years or older');
    }

    return { eligible: reasons.length === 0, reasons };
  }

  /**
   * A pending request may also declare a required data-sharing scope — separate from
   * the age/employment rules above, this checks whether the citizen has actually
   * granted OneDesk permission to hold that category of data at all (see
   * scopes.module.ts). No scope requirement means no gate, so older/unscoped
   * departments are unaffected.
   */
  async checkScope(requiredScope: string | null, citizenMasterId: string | null): Promise<EligibilityResult> {
    if (!requiredScope || !citizenMasterId) return { eligible: true, reasons: [] };
    const scope = findScope(requiredScope);
    if (!scope) return { eligible: true, reasons: [] };

    const { rows } = await this.pool.query(
      'SELECT 1 FROM citizen_scope_grants WHERE citizen_master_id = $1 AND scope_key = $2',
      [citizenMasterId, requiredScope],
    );
    if (rows.length > 0) return { eligible: true, reasons: [] };
    return { eligible: false, reasons: [`OneDesk hasn't been granted the "${scope.label}" scope for this citizen — grant it in Settings first`] };
  }
}
