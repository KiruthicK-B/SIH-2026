const { pool, quoteIdent } = require('./db');

// Generic JSON-document CRUD against one whitelisted table. Mirrors
// HiveJsonRepository<T> on the Flutter side: id is the primary key, data is
// the model's exact toJson() blob, nothing else is interpreted server-side.

async function getAll(table) {
  const { rows } = await pool.query(`SELECT data FROM ${quoteIdent(table)} ORDER BY updated_at ASC`);
  return rows.map((r) => r.data);
}

async function getById(table, id) {
  const { rows } = await pool.query(`SELECT data FROM ${quoteIdent(table)} WHERE id = $1`, [id]);
  return rows[0]?.data ?? null;
}

async function save(table, item) {
  if (!item || typeof item.id !== 'string' || item.id.length === 0) {
    throw new Error('item.id is required');
  }
  await pool.query(
    `INSERT INTO ${quoteIdent(table)} (id, data, updated_at) VALUES ($1, $2, now())
     ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, updated_at = now()`,
    [item.id, item],
  );
}

async function saveMany(table, items) {
  if (!Array.isArray(items)) throw new Error('items must be an array');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const item of items) {
      if (!item || typeof item.id !== 'string' || item.id.length === 0) {
        throw new Error('every item requires an id');
      }
      await client.query(
        `INSERT INTO ${quoteIdent(table)} (id, data, updated_at) VALUES ($1, $2, now())
         ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, updated_at = now()`,
        [item.id, item],
      );
    }
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

async function remove(table, id) {
  await pool.query(`DELETE FROM ${quoteIdent(table)} WHERE id = $1`, [id]);
}

async function clear(table) {
  await pool.query(`DELETE FROM ${quoteIdent(table)}`);
}

module.exports = { getAll, getById, save, saveMany, remove, clear };
