import { writeFile } from 'node:fs/promises';
import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import type { Pool } from 'pg';
import { PG_POOL } from '../db/db.module';
import { DEFAULT_SCOPE_KEYS, findScope, extractScopeColumns, SCOPES } from './scope-catalog';

const DIGILOCKER_ADAPTER_URL = process.env.DIGILOCKER_ADAPTER_URL ?? 'http://digilocker-adapter:4005';
const UPLOAD_DIR = process.env.UPLOAD_DIR ?? '/app/uploads';

const EXTENSION_BY_CONTENT_TYPE: Record<string, string> = {
  'image/avif': '.avif',
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
};

@Injectable()
export class ScopesService {
  constructor(@Inject(PG_POOL) private readonly pool: Pool) {}

  async listGrants(masterId: string) {
    const { rows } = await this.pool.query('SELECT scope_key FROM citizen_scope_grants WHERE citizen_master_id = $1', [masterId]);
    const granted = new Set(rows.map((r) => r.scope_key));
    return SCOPES.map((s) => ({ key: s.key, label: s.label, sourceAuthority: s.sourceAuthority, isDefault: s.isDefault, granted: granted.has(s.key) }));
  }

  /** Bookkeeping only — the default scopes' columns are written directly by
   * register/complete itself (name/DOB/gender/phone from the values it already has). */
  async recordDefaultGrants(masterId: string) {
    for (const key of DEFAULT_SCOPE_KEYS) {
      await this.pool.query(
        'INSERT INTO citizen_scope_grants (citizen_master_id, scope_key) VALUES ($1, $2) ON CONFLICT DO NOTHING',
        [masterId, key],
      );
    }
  }

  /** Applies non-default scopes chosen at registration, using the govt record already
   * fetched during eKYC lookup (no extra network round-trip). Defaults are excluded —
   * see recordDefaultGrants — since none of the non-default scopes touch photo_path or
   * phone_number, there's no overlap with values register/complete sets directly. */
  async applyOptionalGrants(masterId: string, keys: string[], govtRecord: Record<string, unknown>) {
    const optionalKeys = keys.filter((k) => !DEFAULT_SCOPE_KEYS.includes(k));
    const columnValues: Record<string, unknown> = {};
    for (const key of optionalKeys) {
      const scope = findScope(key);
      if (scope) Object.assign(columnValues, extractScopeColumns(scope, govtRecord));
    }
    await this.applyColumnUpdate(masterId, columnValues);
    for (const key of optionalKeys) {
      await this.pool.query(
        'INSERT INTO citizen_scope_grants (citizen_master_id, scope_key) VALUES ($1, $2) ON CONFLICT DO NOTHING',
        [masterId, key],
      );
    }
  }

  async fetchAndSavePhoto(aadhaarNumber: string, masterId: string): Promise<string | null> {
    const res = await fetch(`${DIGILOCKER_ADAPTER_URL}/photo/${aadhaarNumber}`);
    if (!res.ok) return null;
    const buffer = Buffer.from(await res.arrayBuffer());
    // Preserve the real image format instead of hardcoding .jpg — an admin can
    // upload any format (this registry has real AVIF uploads), and serving those
    // bytes back labeled as image/jpeg makes browsers refuse to render them.
    const contentType = res.headers.get('content-type') ?? '';
    const ext = EXTENSION_BY_CONTENT_TYPE[contentType] ?? '.jpg';
    const filePath = `${UPLOAD_DIR}/${masterId}-photo${ext}`;
    await writeFile(filePath, buffer);
    return filePath;
  }

  /** Settings-page grant of a scope not chosen at registration time — always a
   * non-default scope (defaults are locked in the UI), so this never touches
   * phone_number/photo_path; safe to re-fetch and copy generically. */
  async grantScope(masterId: string, key: string) {
    const scope = findScope(key);
    if (!scope) throw new BadRequestException(`unknown scope: ${key}`);
    if (scope.isDefault) throw new BadRequestException('this scope is always shared');

    const { rows } = await this.pool.query('SELECT aadhaar_number FROM master_identity WHERE master_id = $1', [masterId]);
    if (rows.length === 0) throw new NotFoundException('citizen record not found');
    const aadhaarNumber = rows[0].aadhaar_number;
    if (!aadhaarNumber) throw new BadRequestException('no Aadhaar on file to re-verify this scope against');

    const res = await fetch(`${DIGILOCKER_ADAPTER_URL}/ekyc`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ aadhaarNumber }),
    });
    if (!res.ok) throw new BadRequestException('could not re-verify this citizen against the government registry');
    const govtRecord = await res.json();

    await this.applyColumnUpdate(masterId, extractScopeColumns(scope, govtRecord));
    await this.pool.query(
      'INSERT INTO citizen_scope_grants (citizen_master_id, scope_key) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [masterId, key],
    );
  }

  async revokeScope(masterId: string, key: string) {
    const scope = findScope(key);
    if (!scope) throw new BadRequestException(`unknown scope: ${key}`);
    if (scope.isDefault) throw new BadRequestException('this scope is always shared and cannot be revoked');

    const nullClauses = scope.columns.map((col) => `${col} = NULL`).join(', ');
    await this.pool.query(`UPDATE master_identity SET ${nullClauses} WHERE master_id = $1`, [masterId]);
    await this.pool.query('DELETE FROM citizen_scope_grants WHERE citizen_master_id = $1 AND scope_key = $2', [masterId, key]);
  }

  private async applyColumnUpdate(masterId: string, columnValues: Record<string, unknown>) {
    const columns = Object.keys(columnValues);
    if (columns.length === 0) return;
    const setSql = columns.map((col, i) => `${col} = $${i + 2}`).join(', ');
    await this.pool.query(`UPDATE master_identity SET ${setSql} WHERE master_id = $1`, [masterId, ...columns.map((c) => columnValues[c])]);
  }
}
