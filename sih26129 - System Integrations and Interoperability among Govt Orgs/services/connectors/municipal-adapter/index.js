// Mock "Municipal Corporation" system — legacy database adapter. Unlike the other
// mocks (which are stateless REST/SOAP echoes), this one is backed by its own,
// genuinely separate Postgres database (see docker-compose's DATABASE_URL) — a real
// DB-adapter round-trip, not a canned JSON response. This is the connector core-api's
// admin kill-switch targets for the graceful-degradation demo, and the step an
// officer approves manually rather than one that auto-completes.
const express = require('express')
const { Pool } = require('pg')

const app = express()
app.use(express.json())

const PORT = process.env.PORT || 4003
const pool = new Pool({ connectionString: process.env.DATABASE_URL })

async function ensureSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS municipal_reviews (
      application_id TEXT PRIMARY KEY,
      reviewed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      status TEXT NOT NULL
    )
  `)
}

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'municipal-adapter' }))

app.post('/review', async (req, res) => {
  const { applicationId } = req.body
  const valid = typeof applicationId === 'string' && /^[A-Za-z0-9-]{4,}$/.test(applicationId)

  if (!valid) {
    setTimeout(() => res.json({ applicationId, status: 'REJECTED' }), 1200)
    return
  }

  setTimeout(async () => {
    try {
      await pool.query(
        `INSERT INTO municipal_reviews (application_id, status) VALUES ($1, 'REVIEWED')
         ON CONFLICT (application_id) DO UPDATE SET status = 'REVIEWED', reviewed_at = now()`,
        [applicationId],
      )
      const { rows } = await pool.query('SELECT status FROM municipal_reviews WHERE application_id = $1', [applicationId])
      res.json({ applicationId, status: rows[0]?.status === 'REVIEWED' ? 'REVIEWED' : 'ERROR' })
    } catch (err) {
      console.error('municipal-adapter DB write failed', err)
      res.status(500).json({ applicationId, status: 'ERROR' })
    }
  }, 1200)
})

ensureSchema()
  .then(() => app.listen(PORT, () => console.log(`municipal-adapter (legacy DB adapter) listening on ${PORT}`)))
  .catch((err) => {
    console.error('municipal-adapter failed to initialize its database schema', err)
    process.exit(1)
  })
