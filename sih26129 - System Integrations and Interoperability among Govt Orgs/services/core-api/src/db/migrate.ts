import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { Pool } from 'pg';

const MIGRATIONS_DIR = join(__dirname, '..', '..', 'db', 'migrations');
const SEED_DIR = join(__dirname, '..', '..', 'db', 'seed');

async function applyDir(pool: Pool, dir: string, label: string) {
  let files: string[] = [];
  try {
    files = readdirSync(dir).filter((f) => f.endsWith('.sql')).sort();
  } catch {
    return;
  }

  for (const file of files) {
    const id = `${label}/${file}`;
    const { rows } = await pool.query('SELECT 1 FROM schema_migrations WHERE id = $1', [id]);
    if (rows.length > 0) continue;

    const sql = readFileSync(join(dir, file), 'utf-8');
    console.log(`[migrate] applying ${id}`);
    await pool.query('BEGIN');
    try {
      await pool.query(sql);
      await pool.query('INSERT INTO schema_migrations (id) VALUES ($1)', [id]);
      await pool.query('COMMIT');
    } catch (err) {
      await pool.query('ROLLBACK');
      throw err;
    }
  }
}

export async function runMigrations(pool: Pool) {
  await pool.query(
    'CREATE TABLE IF NOT EXISTS schema_migrations (id TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now())',
  );
  await applyDir(pool, MIGRATIONS_DIR, 'migrations');
  await applyDir(pool, SEED_DIR, 'seed');
}
