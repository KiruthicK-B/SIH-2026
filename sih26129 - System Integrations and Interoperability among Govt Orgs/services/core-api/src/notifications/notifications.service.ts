import { Inject, Injectable } from '@nestjs/common';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';

export type NotificationType = 'application' | 'consent' | 'document' | 'system';

@Injectable()
export class NotificationsService {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async list(citizenMasterId?: string) {
    const { rows } = citizenMasterId
      ? await this.pool.query('SELECT * FROM notifications WHERE citizen_master_id = $1 ORDER BY created_at DESC', [citizenMasterId])
      : await this.pool.query('SELECT * FROM notifications ORDER BY created_at DESC');
    return rows.map((r) => ({
      id: r.id,
      type: r.type,
      title: r.title,
      description: r.description,
      timestamp: new Date(r.created_at).toISOString(),
      read: r.read,
    }));
  }

  async markRead(id: string, citizenMasterId?: string) {
    if (citizenMasterId) {
      await this.pool.query('UPDATE notifications SET read = true WHERE id = $1 AND citizen_master_id = $2', [id, citizenMasterId]);
    } else {
      await this.pool.query('UPDATE notifications SET read = true WHERE id = $1', [id]);
    }
  }

  async markAllRead(citizenMasterId?: string) {
    if (citizenMasterId) {
      await this.pool.query('UPDATE notifications SET read = true WHERE citizen_master_id = $1', [citizenMasterId]);
    } else {
      await this.pool.query('UPDATE notifications SET read = true');
    }
  }

  /** Called by ApplicationsService/WorkflowService when something real happens —
   * never seeded speculatively, only in response to an actual state transition. */
  async notify(citizenMasterId: string | null, type: NotificationType, title: string, description: string) {
    if (!citizenMasterId) return;
    await this.pool.query(
      `INSERT INTO notifications (id, citizen_master_id, type, title, description) VALUES ($1, $2, $3, $4, $5)`,
      [`ntf-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`, citizenMasterId, type, title, description],
    );
  }
}
