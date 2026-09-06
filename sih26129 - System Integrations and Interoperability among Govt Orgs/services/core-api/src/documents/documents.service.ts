import { ForbiddenException, Inject, Injectable } from '@nestjs/common';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';

@Injectable()
export class DocumentsService {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async list(citizenMasterId?: string) {
    const { rows } = citizenMasterId
      ? await this.pool.query('SELECT * FROM documents WHERE citizen_master_id = $1 ORDER BY issued_on DESC', [citizenMasterId])
      : await this.pool.query('SELECT * FROM documents ORDER BY issued_on DESC');
    return rows.map((r) => ({
      id: r.id,
      name: r.name,
      issuedBy: r.issued_by,
      status: r.status,
      issuedOn: new Date(r.issued_on).toISOString().slice(0, 10),
      applicationId: r.application_id ?? undefined,
      hasFile: r.file_path != null,
    }));
  }

  /** Called when a real application completes — the certificate a citizen would
   * actually receive, not a pre-seeded prop. */
  async issueDocument(citizenMasterId: string | null, name: string, issuedBy: string, applicationId: string) {
    if (!citizenMasterId) return;
    await this.pool.query(
      `INSERT INTO documents (id, citizen_master_id, name, issued_by, status, application_id)
       VALUES ($1, $2, $3, $4, 'Verified', $5)`,
      [`doc-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`, citizenMasterId, name, issuedBy, applicationId],
    );
  }

  /** A citizen-uploaded file, attached during the Application Wizard's Documents
   * step. No `applicationId` yet — the application doesn't exist until final submit
   * — linked afterward via linkToApplication(). */
  async uploadDocument(citizenMasterId: string, name: string, filePath: string, mimeType: string, sizeBytes: number) {
    const id = `doc-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
    await this.pool.query(
      `INSERT INTO documents (id, citizen_master_id, name, issued_by, status, file_path, mime_type, size_bytes)
       VALUES ($1, $2, $3, 'Self-uploaded', 'Pending Verification', $4, $5, $6)`,
      [id, citizenMasterId, name, filePath, mimeType, sizeBytes],
    );
    return id;
  }

  async getFile(id: string, citizenMasterId?: string) {
    const { rows } = await this.pool.query('SELECT * FROM documents WHERE id = $1', [id]);
    if (rows.length === 0 || !rows[0].file_path) return null;
    if (citizenMasterId && rows[0].citizen_master_id !== citizenMasterId) {
      throw new ForbiddenException('this document does not belong to you');
    }
    return { filePath: rows[0].file_path, mimeType: rows[0].mime_type, name: rows[0].name };
  }

  /** Ownership-checked — only links documents the same citizen uploaded. */
  async linkToApplication(documentIds: string[], applicationId: string, citizenMasterId: string) {
    if (documentIds.length === 0) return;
    await this.pool.query(
      `UPDATE documents SET application_id = $1 WHERE id = ANY($2) AND citizen_master_id = $3`,
      [applicationId, documentIds, citizenMasterId],
    );
  }
}
