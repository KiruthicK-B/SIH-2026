import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';
import { DocumentsService } from '../documents/documents.service';
import { NotificationsService } from '../notifications/notifications.service';
import type {
  Application,
  NewApplicationInput,
  TimelineStep,
  WorkflowEvent,
} from './applications.types';

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

const BUSINESS_LICENSE_TIMELINE = (today: string): TimelineStep[] => [
  { label: 'Application Submitted', department: 'OneDesk', status: 'done', date: today, systemType: 'Unified Portal' },
  { label: 'Identity Verified', department: 'Identity Service', status: 'active', systemType: 'OAuth / Federation' },
  { label: 'Business Details Verified', department: 'Business Registry', status: 'pending', systemType: 'Legacy SOAP' },
  { label: 'Tax Verification', department: 'Revenue Department', status: 'pending', systemType: 'REST API' },
  { label: 'Municipal Review', department: 'Municipal Corporation', status: 'pending', systemType: 'Legacy Database Adapter' },
  { label: 'Final Approval', department: 'License Authority', status: 'pending', systemType: 'GraphQL API' },
];

const GENERIC_TIMELINE = (today: string, department: string): TimelineStep[] => [
  { label: 'Application Submitted', department: 'Unified Portal', status: 'done', date: today },
  { label: 'Documents Verified', department, status: 'active' },
  { label: 'Eligibility Verification', department, status: 'pending' },
  { label: 'Department Approval', department, status: 'pending' },
  { label: 'Application Completed', department, status: 'pending' },
];

@Injectable()
export class ApplicationsService {
  constructor(
    @Inject(PG_POOL) private readonly pool: Pool,
    private readonly notifications: NotificationsService,
    private readonly documents: DocumentsService,
  ) {}

  private async hydrate(appRows: any[]): Promise<Application[]> {
    if (appRows.length === 0) return [];
    const ids = appRows.map((r) => r.id);
    const { rows: stepRows } = await this.pool.query(
      'SELECT * FROM timeline_steps WHERE application_id = ANY($1) ORDER BY application_id, step_order',
      [ids],
    );
    const stepsByApp = new Map<string, TimelineStep[]>();
    for (const s of stepRows) {
      const list = stepsByApp.get(s.application_id) ?? [];
      list.push({
        label: s.label,
        department: s.department,
        status: s.status,
        date: s.step_date ? new Date(s.step_date).toISOString().slice(0, 10) : undefined,
        systemType: s.system_type ?? undefined,
        note: s.note ?? undefined,
        blockedReasonCode: s.blocked_reason_code ?? undefined,
      });
      stepsByApp.set(s.application_id, list);
    }
    return appRows.map((a) => ({
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
      timeline: stepsByApp.get(a.id) ?? [],
    }));
  }

  async listApplications(citizenMasterId?: string): Promise<Application[]> {
    const { rows } = citizenMasterId
      ? await this.pool.query('SELECT * FROM applications WHERE citizen_master_id = $1 ORDER BY submitted_on DESC', [citizenMasterId])
      : await this.pool.query('SELECT * FROM applications ORDER BY submitted_on DESC');
    return this.hydrate(rows);
  }

  /** Backs OfficerDashboard: applications with a step currently active at this
   * department — i.e. genuinely "assigned to me right now," not the whole platform. */
  async listAssigned(department: string | null): Promise<Application[]> {
    const { rows } = await this.pool.query(
      `SELECT DISTINCT a.* FROM applications a
       JOIN timeline_steps t ON t.application_id = a.id
       WHERE t.status = 'active' AND ($1::text IS NULL OR t.department = $1)
       ORDER BY a.submitted_on DESC`,
      [department],
    );
    return this.hydrate(rows);
  }

  async getApplication(id: string, citizenMasterId?: string): Promise<Application> {
    const { rows } = citizenMasterId
      ? await this.pool.query('SELECT * FROM applications WHERE id = $1 AND citizen_master_id = $2', [id, citizenMasterId])
      : await this.pool.query('SELECT * FROM applications WHERE id = $1', [id]);
    // Same "not found" for a wrong ID and for someone else's application — a citizen
    // probing IDs can't tell which case they hit.
    if (rows.length === 0) throw new NotFoundException(`application ${id} not found`);
    const [hydrated] = await this.hydrate(rows);
    return hydrated;
  }

  async submitApplication(input: NewApplicationInput, actor: string): Promise<Application> {
    // Guards against a double-click or a refresh-resubmit creating two real
    // applications — a citizen with no master ID (edge case, not the risk this
    // targets) always falls through to a normal insert since NULL never matches NULL.
    if (input.citizenMasterId) {
      const { rows: dup } = await this.pool.query(
        `SELECT id FROM applications
         WHERE citizen_master_id = $1 AND service = $2 AND description = $3
           AND created_at >= NOW() - INTERVAL '15 seconds'
         ORDER BY created_at DESC LIMIT 1`,
        [input.citizenMasterId, input.service, input.description],
      );
      if (dup.length > 0) return this.getApplication(dup[0].id);
    }

    const today = todayISO();
    const isBusinessLicense = input.service === 'Business License';
    const { rows: seqRows } = await this.pool.query("SELECT nextval('application_seq') AS n");
    const seq = seqRows[0].n;
    const id = isBusinessLicense ? `BL-2026-${seq}` : `APP-2026-${seq}`;
    const timeline = isBusinessLicense ? BUSINESS_LICENSE_TIMELINE(today) : GENERIC_TIMELINE(today, input.department);

    await this.pool.query('BEGIN');
    try {
      await this.pool.query(
        `INSERT INTO applications (id, service, department, status, last_updated, submitted_on, citizen_name, citizen_master_id, description, flagship)
         VALUES ($1, $2, $3, 'In Progress', $4, $4, $5, $6, $7, $8)`,
        [id, input.service, input.department, today, input.citizenName, input.citizenMasterId ?? null, input.description, isBusinessLicense],
      );
      for (const [i, step] of timeline.entries()) {
        await this.pool.query(
          `INSERT INTO timeline_steps (application_id, step_order, label, department, status, step_date, system_type)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [id, i, step.label, step.department, step.status, step.date ?? null, step.systemType ?? null],
        );
      }
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose)
         VALUES ($1, $2, $3, 'WRITE', $4, 'Success', 'Application submission')`,
        [`aud-${Date.now()}`, actor, input.department, `Application ${id} submitted`],
      );
      await this.pool.query('COMMIT');
    } catch (err) {
      await this.pool.query('ROLLBACK');
      throw err;
    }

    if (input.documentIds && input.documentIds.length > 0 && input.citizenMasterId) {
      await this.documents.linkToApplication(input.documentIds, id, input.citizenMasterId);
    }

    await this.notifications.notify(
      input.citizenMasterId ?? null,
      'application',
      `Application ${id}`,
      `Submitted for ${input.service} — ${input.department}.`,
    );

    return this.getApplication(id);
  }

  /**
   * Manual step-advancement for non-flagship generic services (no real connector
   * behind them — e.g. Scholarship Scheme, Income Certificate). Flagship Business
   * License applications are driven entirely by WorkflowService's real connector
   * calls + kill-switch instead (see workflow.service.ts) and never call this.
   */
  async advanceApplication(id: string, actor: string): Promise<WorkflowEvent | null> {
    const today = todayISO();
    const { rows: stepRows } = await this.pool.query(
      'SELECT * FROM timeline_steps WHERE application_id = $1 ORDER BY step_order',
      [id],
    );
    if (stepRows.length === 0) throw new NotFoundException(`application ${id} not found`);
    const { rows: appRows } = await this.pool.query('SELECT citizen_master_id, service FROM applications WHERE id = $1', [id]);
    const citizenMasterId: string | null = appRows[0]?.citizen_master_id ?? null;
    const serviceName: string = appRows[0]?.service ?? id;

    let event: WorkflowEvent | null = null;

    await this.pool.query('BEGIN');
    try {
      const activeIdx = stepRows.findIndex((s) => s.status === 'active');
      if (activeIdx === -1) {
        await this.pool.query('COMMIT');
        return null;
      }
      const step = stepRows[activeIdx];

      await this.pool.query(`UPDATE timeline_steps SET status = 'done', step_date = $2 WHERE id = $1`, [step.id, today]);
      event = {
        title: `${step.label} completed`,
        description: `${step.department} confirmed ${step.label.toLowerCase()}.`,
        tone: 'success',
      };
      const nextStep = stepRows[activeIdx + 1];
      if (nextStep && nextStep.status === 'pending') {
        await this.pool.query(`UPDATE timeline_steps SET status = 'active' WHERE id = $1`, [nextStep.id]);
      }
      await this.pool.query(
        `INSERT INTO audit_log (id, actor, department, action, resource, result, purpose) VALUES ($1, $2, $3, 'VERIFY', $4, 'Success', 'Workflow step completed')`,
        [`aud-${Date.now()}`, actor, step.department, `${id}: ${step.label}`],
      );

      const { rows: freshSteps } = await this.pool.query('SELECT status FROM timeline_steps WHERE application_id = $1', [id]);
      const allDone = freshSteps.every((s) => s.status === 'done');
      if (allDone) {
        await this.pool.query(`UPDATE applications SET status = 'Completed', last_updated = $2 WHERE id = $1`, [id, today]);
      } else {
        await this.pool.query(`UPDATE applications SET last_updated = $2 WHERE id = $1`, [id, today]);
      }
      await this.pool.query('COMMIT');

      await this.notifications.notify(citizenMasterId, 'application', `Application ${id}`, event.description);
      if (allDone) {
        await this.notifications.notify(citizenMasterId, 'application', `Application ${id}`, `${serviceName} application has been completed.`);
        await this.documents.issueDocument(citizenMasterId, `${serviceName} Certificate`, step.department, id);
      }
    } catch (err) {
      await this.pool.query('ROLLBACK');
      throw err;
    }

    return event;
  }
}
