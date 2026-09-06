const { Pool } = require('pg');
const { ENTITY_TABLES } = require('./entities');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

// Table names are mixed-case (e.g. "landRecords") so must be double-quoted in
// every statement to preserve case — Postgres folds unquoted identifiers to
// lowercase. Always sourced from the fixed ENTITY_TABLES whitelist, never
// from request input, so string-building the identifier here is safe.
function quoteIdent(name) {
  return `"${name}"`;
}

async function ensureTables() {
  for (const table of ENTITY_TABLES) {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS ${quoteIdent(table)} (
        id TEXT PRIMARY KEY,
        data JSONB NOT NULL,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )
    `);
  }
}

async function waitForPostgres({ retries = 30, delayMs = 1000 } = {}) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      await pool.query('SELECT 1');
      return;
    } catch (err) {
      if (attempt === retries) throw err;
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }
}

module.exports = { pool, quoteIdent, ensureTables, waitForPostgres };
