import { BadRequestException, Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import type { Pool } from 'pg';
import { ConnectorsService, LIVE_DEPARTMENTS } from '../connectors/connectors.service';
import { PG_POOL } from '../db/db.module';
import { DocumentsService } from '../documents/documents.service';
import { ApplicationEventsService } from '../events/application-events.service';
import { NotificationsService } from '../notifications/notifications.service';
import type { Application, WorkflowEvent } from '../applications/applications.types';

// Municipal Review is deliberately not auto-advanced — it requires an officer's
// approval (Phase 3's OfficerDashboard). The chain runs everything up to it
// automatically, then stops and waits.
const OFFICER_GATED_DEPARTMENT = 'Municipal Corporation';

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

@Injectable()
export class WorkflowService {
  private readonly logger = new Logger(WorkflowService.name);

  constructor(
    @Inject(PG_POOL) private readonly pool: Pool,
    private readonly connectors: ConnectorsService,
    private readonly events: ApplicationEventsService,
    private readonly notifications: NotificationsService,
    private readonly documents: DocumentsService,
  ) {}

  private async hydrate(id: string): Promise<Application | null> {
    const { rows: appRows } = await this.pool.query('SELECT * FROM applications WHERE id = $1', [id]);
    if (appRows.length === 0) return null;
    const a = appRows[0];
    const { rows: stepRows } = await this.pool.query(
      'SELECT * FROM timeline_steps WHERE application_id = $1 ORDER BY step_order',
      [id],
    );
    return {
      id: a.id,
      service: a.service,
      department: a.department,
      status: a.status,
      lastUpdated: new Date(a.last_updated).toISOString().slice(0, 10),
      submittedOn: new Date(a.submitted_on).toISOString().slice(0, 10),
      citizenName: a.citizen_name,
      description: a.description,
      flagship: a.flagship,
      citizenMasterId: a.citizen_master_id ?? undefined,
      timeline: stepRows.map((s) => ({
        label: s.label,
        department: s.department,
        status: s.status,
        date: s.step_date ? new Date(s.step_date).toISOString().slice(0, 10) : undefined,
        systemType: s.system_type ?? undefined,
        note: s.note ?? undefined,
        blockedReasonCode: s.blocked_reason_code ?? undefined,
      })),
    };
  }

  private async publish(id: string) {
    const app = await this.hydrate(id);
    if (app) this.events.publish(app);
  }

  /**
   * Live revalidation against the authoritative govt registry, run before any
   * protected workflow step. Consent gives permission to access data — it does not
   * freeze that data, so a citizen's identity_status is re-checked against the real
   * registry every time, not trusted from whatever master_identity cached at
   * registration. Any drift (in EITHER direction — including a later correction back
   * to ACTIVE) pauses the workflow once and requires an explicit subsequent retry
   * before proceeding — never a silent auto-resume, per the mock-registry-mutation
   * demo's policy. Returns true if the caller should stop (this step is now blocked).
   */
  private async revalidateIdentity(
    applicationId: string,
    citizenMasterId: string | null,
    currentStep: { id: string; department: string },
  ): Promise<boolean> {
    if (!citizenMasterId) return false;

    const { rows } = await this.pool.query(
      'SELECT aadhaar_number, identity_status FROM master_identity WHERE master_id = $1',
      [citizenMasterId],
    );
    if (rows.length === 0 || !rows[0].aadhaar_number) return false;
    const cachedStatus: string = rows[0].identity_status ?? 'ACTIVE';
    const aadhaarNumber: string = rows[0].aadhaar_number;

    let liveStatus = cachedStatus;
    try {
      const base = process.env.DIGILOCKER_ADAPTER_URL ?? 'http://digilocker-adapter:4005';
      const res = await fetch(`${base}/ekyc`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ medium: 'aadhaar', value: aadhaarNumber }),
        signal: AbortSignal.timeout(5000),
      });
      if (res.ok) {
        const body = await res.json();
        liveStatus = body.identityStatus ?? 'ACTIVE';
      }
      // A non-ok response (registry unreachable/record gone) falls back to the
      // cached value rather than spuriously blocking a workflow on a transient
      // registry blip — the registry being briefly unreachable is not evidence of
      // a status change.
    } catch {
      // same fallback for a network-level failure
    }

    if (liveStatus !== cachedStatus) {
      await this.pool.query('UPDATE master_identity SET identity_status = $1 WHERE master_id = $2', [liveStatus, citizenMasterId]);
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose)
         VALUES ($1, 'System', 'Identity Registry', 'IDENTITY_STATUS_CHANGED', $2, 'Success', $3)`,
        [`aud-${Date.now()}`, `${citizenMasterId}: ${cachedStatus} -> ${liveStatus}`, 'Authoritative identity status changed'],
      );
      const note =
        liveStatus === 'DECEASED'
          ? 'Identity verification requires review before this application can continue.'
          : 'Identity status was corrected by the registry — this application requires revalidation before it can continue.';
      await this.blockForIdentityReview(applicationId, currentStep.id, note);
      await this.notifications.notify(
        citizenMasterId,
        'system',
        `Application ${applicationId}`,
        'Identity verification requires review before this application can continue.',
      );
      await this.publish(applicationId);
      return true;
    }

    if (cachedStatus !== 'ACTIVE') {
      // No new drift this check, but the citizen is still known non-active from an
      // earlier pause — a retry must not silently slip through just because nothing
      // changed since the last check.
      await this.blockForIdentityReview(applicationId, currentStep.id, 'Identity verification requires review before this application can continue.');
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose)
         VALUES ($1, 'System', $2, 'DATA_REQUEST_DENIED', $3, 'Denied', 'DECEASED_STATUS')`,
        [`aud-${Date.now()}`, currentStep.department, `${applicationId}: ${currentStep.department}`],
      );
      await this.publish(applicationId);
      return true;
    }

    // Cleared to proceed — if a prior pause left the application flagged, that flag
    // is now stale (the step below is about to actually advance again).
    await this.pool.query(`UPDATE applications SET status = 'In Progress' WHERE id = $1 AND status = 'Revalidation Required'`, [applicationId]);
    return false;
  }

  private async blockForIdentityReview(applicationId: string, stepId: string, note: string): Promise<void> {
    await this.pool.query(
      `UPDATE timeline_steps SET status = 'blocked', note = $2, blocked_reason_code = 'identity_status_changed' WHERE id = $1`,
      [stepId, note],
    );
    await this.pool.query(`UPDATE applications SET status = 'Revalidation Required' WHERE id = $1`, [applicationId]);
    await this.pool.query(
      `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose)
       VALUES ($1, 'System', 'Identity Registry', 'WORKFLOW_PAUSED', $2, 'Success', 'identity_status_changed')`,
      [`aud-${Date.now()}-p`, applicationId],
    );
  }

  /**
   * Drives a flagship application's timeline forward automatically, step by step,
   * calling each department's connector in turn — this replaces manually clicking
   * "advance" for the Business License flow. Runs until it hits the officer-gated
   * Municipal Review step, a killed connector, or the end of the timeline.
   * Fire-and-forget from the caller — progress is pushed via SSE, not the return value.
   */
  async runAutoAdvance(applicationId: string): Promise<void> {
    const { rows: appRows } = await this.pool.query('SELECT citizen_master_id, service FROM applications WHERE id = $1', [applicationId]);
    const citizenMasterId: string | null = appRows[0]?.citizen_master_id ?? null;
    const serviceName: string = appRows[0]?.service ?? applicationId;

    // eslint-disable-next-line no-constant-condition
    while (true) {
      const { rows: stepRows } = await this.pool.query(
        'SELECT * FROM timeline_steps WHERE application_id = $1 ORDER BY step_order',
        [applicationId],
      );
      if (stepRows.length === 0) return;

      const current = stepRows.find((s) => s.status === 'active');
      if (!current) return; // nothing active — done, or waiting on a blocked/officer-gated step

      const pausedForIdentity = await this.revalidateIdentity(applicationId, citizenMasterId, current);
      if (pausedForIdentity) return;

      if (current.department === OFFICER_GATED_DEPARTMENT) {
        return; // stop and wait for an officer action (Phase 3)
      }

      const killed = await this.connectors.isKilled(current.department);
      if (killed) {
        await this.pool.query(
          `UPDATE timeline_steps SET status = 'blocked', note = $2, blocked_reason_code = 'connector_killed' WHERE id = $1`,
          [current.id, `${current.department} system is temporarily unavailable. Retry scheduled — other steps are unaffected.`],
        );
        await this.pool.query(
          `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose) VALUES ($1, 'System', $2, 'VERIFY', $3, 'Failed', 'Connector unavailable')`,
          [`aud-${Date.now()}`, current.department, `${applicationId}: ${current.label}`],
        );
        await this.publish(applicationId);
        return;
      }

      let ok: boolean;
      let reason: 'connector' | 'consent_revoked' = 'connector';
      try {
        const result = await this.connectors.callForDepartment(current.department, applicationId, citizenMasterId);
        ok = result.ok;
        reason = result.reason ?? 'connector';
      } catch (err) {
        this.logger.warn(`connector call failed for ${current.department}: ${(err as Error).message}`);
        ok = false;
      }

      const today = todayISO();
      if (!ok) {
        const isConsentIssue = reason === 'consent_revoked';
        await this.pool.query(
          `UPDATE timeline_steps SET status = 'blocked', note = $2, blocked_reason_code = $3 WHERE id = $1`,
          [
            current.id,
            isConsentIssue
              ? `${current.department} cannot access this citizen's data — required consent is missing or has been revoked. Grant consent to resume.`
              : `${current.department} did not respond as expected. Retry scheduled — other steps are unaffected.`,
            isConsentIssue ? 'consent_revoked' : 'connector_killed',
          ],
        );
        await this.pool.query(
          `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose) VALUES ($1, 'System', $2, $3, $4, $5, $6)`,
          [
            `aud-${Date.now()}`,
            current.department,
            isConsentIssue ? 'READ' : 'VERIFY',
            `${applicationId}: ${current.label}`,
            isConsentIssue ? 'Denied' : 'Failed',
            isConsentIssue ? 'Data access attempted without valid consent' : 'Connector call failed',
          ],
        );
        await this.notifications.notify(
          citizenMasterId,
          isConsentIssue ? 'consent' : 'system',
          `Application ${applicationId}`,
          isConsentIssue
            ? `${current.department} cannot proceed — required consent is missing or revoked.`
            : `${current.department} is temporarily unavailable — retry scheduled.`,
        );
        await this.publish(applicationId);
        return;
      }

      if (LIVE_DEPARTMENTS.has(current.department)) {
        // Accepted for review, not reviewed — the actual decision arrives later via
        // an officer acting in that department's own portal and calling back through
        // /interop/dept-callback (handleDeptCallback below). Stop here; resuming the
        // chain is that callback's job, not this loop's.
        await this.pool.query(
          `UPDATE timeline_steps SET status = 'awaiting_department', note = $2 WHERE id = $1`,
          [current.id, `Submitted to ${current.department} — awaiting officer review.`],
        );
        await this.notifications.notify(
          citizenMasterId,
          'application',
          `Application ${applicationId}`,
          `${current.label} submitted to ${current.department} — awaiting review.`,
        );
        await this.publish(applicationId);
        return;
      }

      await this.pool.query(`UPDATE timeline_steps SET status = 'done', step_date = $2 WHERE id = $1`, [current.id, today]);
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose) VALUES ($1, 'System', $2, 'VERIFY', $3, 'Success', 'Automated workflow step')`,
        [`aud-${Date.now()}`, current.department, `${applicationId}: ${current.label}`],
      );
      await this.notifications.notify(
        citizenMasterId,
        'application',
        `Application ${applicationId}`,
        `${current.label} confirmed by ${current.department}.`,
      );

      const currentIdx = stepRows.findIndex((s) => s.id === current.id);
      const next = stepRows[currentIdx + 1];
      if (next) {
        await this.pool.query(`UPDATE timeline_steps SET status = 'active' WHERE id = $1`, [next.id]);
      }

      const { rows: freshSteps } = await this.pool.query('SELECT status FROM timeline_steps WHERE application_id = $1', [applicationId]);
      const allDone = freshSteps.every((s) => s.status === 'done');
      if (allDone) {
        await this.pool.query(`UPDATE applications SET status = 'Completed', last_updated = $2 WHERE id = $1`, [applicationId, today]);
        await this.notifications.notify(
          citizenMasterId,
          'application',
          `Application ${applicationId}`,
          `${serviceName} application has been completed.`,
        );
        await this.documents.issueDocument(citizenMasterId, `${serviceName} Certificate`, current.department, applicationId);
      } else {
        await this.pool.query(`UPDATE applications SET last_updated = $2 WHERE id = $1`, [applicationId, today]);
      }

      await this.publish(applicationId);
      // loop continues to the next step (Identity -> Business Registry -> Revenue -> ...
      // stops automatically once `next` lands on Municipal Corporation, per the check above)
    }
  }

  /**
   * Resumes a chain paused on a live department portal (see runAutoAdvance's
   * LIVE_DEPARTMENTS branch) once that department's officer has actually decided —
   * called from InteropController after the callback's HMAC signature checks out.
   * Mirrors approveMunicipalReview's advance-then-check-allDone shape, since that's
   * the same "one step finished, is the application done or does it keep going"
   * logic, just triggered by an external system instead of an in-app officer click.
   */
  async handleDeptCallback(
    department: string,
    applicationId: string,
    decision: 'APPROVED' | 'REJECTED',
    remark: string,
    decidedBy: string,
  ): Promise<void> {
    const { rows: appRows } = await this.pool.query('SELECT citizen_master_id, service FROM applications WHERE id = $1', [applicationId]);
    if (appRows.length === 0) throw new NotFoundException(`application ${applicationId} not found`);
    const citizenMasterId: string | null = appRows[0].citizen_master_id ?? null;
    const serviceName: string = appRows[0].service;

    const { rows: stepRows } = await this.pool.query(
      'SELECT * FROM timeline_steps WHERE application_id = $1 ORDER BY step_order',
      [applicationId],
    );
    const current = stepRows.find((s) => s.department === department && s.status === 'awaiting_department');
    if (!current) throw new NotFoundException(`no step awaiting ${department} for application ${applicationId}`);

    const today = todayISO();

    if (decision === 'REJECTED') {
      await this.pool.query(`UPDATE timeline_steps SET status = 'rejected', step_date = $2, note = $3 WHERE id = $1`, [current.id, today, remark]);
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose) VALUES ($1, $2, $3, 'REJECT', $4, 'Success', $5)`,
        [`aud-${Date.now()}`, decidedBy, department, `${applicationId}: ${current.label}`, remark],
      );
      await this.pool.query(`UPDATE applications SET status = 'Rejected', last_updated = $2 WHERE id = $1`, [applicationId, today]);
      await this.notifications.notify(citizenMasterId, 'application', `Application ${applicationId}`, `${department} rejected this application: ${remark}`);
      await this.publish(applicationId);
      return;
    }

    await this.pool.query(`UPDATE timeline_steps SET status = 'done', step_date = $2, note = $3 WHERE id = $1`, [current.id, today, remark]);
    await this.pool.query(
      `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose) VALUES ($1, $2, $3, 'APPROVE', $4, 'Success', $5)`,
      [`aud-${Date.now()}`, decidedBy, department, `${applicationId}: ${current.label}`, remark],
    );
    await this.notifications.notify(citizenMasterId, 'application', `Application ${applicationId}`, `${current.label} approved by ${department}: ${remark}`);

    const currentIdx = stepRows.findIndex((s) => s.id === current.id);
    const next = stepRows[currentIdx + 1];
    if (next) {
      await this.pool.query(`UPDATE timeline_steps SET status = 'active' WHERE id = $1`, [next.id]);
    }

    const { rows: freshSteps } = await this.pool.query('SELECT status FROM timeline_steps WHERE application_id = $1', [applicationId]);
    const allDone = freshSteps.every((s) => s.status === 'done');
    if (allDone) {
      await this.pool.query(`UPDATE applications SET status = 'Completed', last_updated = $2 WHERE id = $1`, [applicationId, today]);
      await this.notifications.notify(citizenMasterId, 'application', `Application ${applicationId}`, `${serviceName} application has been completed.`);
      await this.documents.issueDocument(citizenMasterId, `${serviceName} Certificate`, department, applicationId);
    } else {
      await this.pool.query(`UPDATE applications SET last_updated = $2 WHERE id = $1`, [applicationId, today]);
    }

    await this.publish(applicationId);
    if (next) {
      await this.runAutoAdvance(applicationId);
    }
  }

  /**
   * The one step in the Business License flow that never auto-advances: an officer
   * must explicitly approve it. Still respects the kill-switch (an officer can't push
   * a review through a connector the admin has deliberately taken down) and, once
   * approved, resumes the auto-advance chain for whatever comes after (Final Approval).
   */
  async approveMunicipalReview(applicationId: string, actor: string): Promise<WorkflowEvent> {
    const { rows: stepRows } = await this.pool.query(
      'SELECT * FROM timeline_steps WHERE application_id = $1 ORDER BY step_order',
      [applicationId],
    );
    if (stepRows.length === 0) throw new NotFoundException(`application ${applicationId} not found`);

    const current = stepRows.find((s) => s.status === 'active');
    if (!current || current.department !== OFFICER_GATED_DEPARTMENT) {
      throw new BadRequestException('Municipal Review is not the current active step for this application');
    }

    const { rows: appRows } = await this.pool.query('SELECT citizen_master_id FROM applications WHERE id = $1', [applicationId]);
    const citizenMasterId: string | null = appRows[0]?.citizen_master_id ?? null;
    const pausedForIdentity = await this.revalidateIdentity(applicationId, citizenMasterId, current);
    if (pausedForIdentity) {
      return {
        title: 'Identity verification required',
        description: 'This application requires identity revalidation before it can proceed.',
        tone: 'warning',
      };
    }

    const killed = await this.connectors.isKilled(OFFICER_GATED_DEPARTMENT);
    if (killed) {
      await this.pool.query(
        `UPDATE timeline_steps SET status = 'blocked', note = $2, blocked_reason_code = 'connector_killed' WHERE id = $1`,
        [current.id, `${OFFICER_GATED_DEPARTMENT} system is temporarily unavailable. Retry scheduled — other steps are unaffected.`],
      );
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose) VALUES ($1, $2, $3, 'APPROVE', $4, 'Failed', 'Officer approval attempted while connector killed')`,
        [`aud-${Date.now()}`, actor, OFFICER_GATED_DEPARTMENT, `${applicationId}: ${current.label}`],
      );
      await this.publish(applicationId);
      return {
        title: `${OFFICER_GATED_DEPARTMENT} unavailable`,
        description: 'This connector is currently killed by an administrator — approval cannot go through until it is restored.',
        tone: 'warning',
      };
    }

    const result = await this.connectors.reviewMunicipal(applicationId);
    if (!result.ok) {
      throw new BadRequestException('Municipal review connector call failed');
    }

    const today = todayISO();
    await this.pool.query(`UPDATE timeline_steps SET status = 'done', step_date = $2 WHERE id = $1`, [current.id, today]);
    await this.pool.query(
      `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose) VALUES ($1, $2, $3, 'APPROVE', $4, 'Success', 'Officer-approved municipal review')`,
      [`aud-${Date.now()}`, actor, OFFICER_GATED_DEPARTMENT, `${applicationId}: ${current.label}`],
    );

    const currentIdx = stepRows.findIndex((s) => s.id === current.id);
    const next = stepRows[currentIdx + 1];
    if (next) {
      await this.pool.query(`UPDATE timeline_steps SET status = 'active' WHERE id = $1`, [next.id]);
    }
    await this.pool.query(`UPDATE applications SET last_updated = $2 WHERE id = $1`, [applicationId, today]);
    await this.publish(applicationId);

    // Resume the chain — Final Approval isn't officer-gated, so this completes it.
    await this.runAutoAdvance(applicationId);

    return {
      title: 'Municipal Review approved',
      description: `${actor} approved municipal review — application moves to final approval.`,
      tone: 'success',
    };
  }

  /**
   * Manual "Retry" (ExceptionsTab): re-attempts this application's currently blocked
   * step. If the connector is still killed, runAutoAdvance's own check re-blocks it
   * immediately — this only actually resolves anything for transient failures, not
   * kill-switch blocks (those need an admin Restore).
   */
  async retryBlockedStep(applicationId: string): Promise<void> {
    const { rows: blocked } = await this.pool.query(
      `SELECT id FROM timeline_steps WHERE application_id = $1 AND status = 'blocked'`,
      [applicationId],
    );
    for (const step of blocked) {
      await this.pool.query(
        `UPDATE timeline_steps SET status = 'active', note = NULL, blocked_reason_code = NULL WHERE id = $1`,
        [step.id],
      );
    }
    if (blocked.length > 0) {
      await this.publish(applicationId);
      await this.runAutoAdvance(applicationId);
    }
  }

  /** Admin kill-switch: immediately blocks any in-flight step at this department. */
  async killConnector(department: string): Promise<void> {
    const { rows: activeSteps } = await this.pool.query(
      `SELECT * FROM timeline_steps WHERE department = $1 AND status = 'active'`,
      [department],
    );
    for (const step of activeSteps) {
      await this.pool.query(
        `UPDATE timeline_steps SET status = 'blocked', note = $2, blocked_reason_code = 'connector_killed' WHERE id = $1`,
        [step.id, `${department} system is temporarily unavailable. Retry scheduled — other steps are unaffected.`],
      );
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose) VALUES ($1, 'Platform Admin', $2, 'VERIFY', $3, 'Failed', 'Connector killed by administrator')`,
        [`aud-${Date.now()}-${step.id}`, department, `${step.application_id}: ${step.label}`],
      );
      await this.publish(step.application_id);
    }
  }

  /** Admin restore: un-blocks any step waiting on this department and resumes its chain. */
  async restoreConnector(department: string): Promise<void> {
    const { rows: blockedSteps } = await this.pool.query(
      `SELECT * FROM timeline_steps WHERE department = $1 AND status = 'blocked' AND blocked_reason_code = 'connector_killed'`,
      [department],
    );
    for (const step of blockedSteps) {
      await this.pool.query(
        `UPDATE timeline_steps SET status = 'active', note = NULL, blocked_reason_code = NULL WHERE id = $1`,
        [step.id],
      );
      await this.publish(step.application_id);
      // Fire-and-forget: resume the chain from here without blocking the admin's HTTP response.
      void this.runAutoAdvance(step.application_id);
    }
  }
}
