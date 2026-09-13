// Revenue Department Portal — an independently-run system, not a OneDesk module.
// REST API + its own PostgreSQL database + its own officer login, deliberately
// outside OneDesk's Keycloak trust boundary (see LIVE_DEPARTMENT_PORTALS_PLAN.md §6).
// OneDesk submits a case here and gets on with its own business; the only thing
// that comes back is a signed webhook once an officer here actually decides.
const path = require('node:path')
const crypto = require('node:crypto')
const { EventEmitter } = require('node:events')
const express = require('express')
const cors = require('cors')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')
const { Pool } = require('pg')

const API_PORT = process.env.PORT || 4303
const FRONTEND_PORT = process.env.FRONTEND_PORT || 5303
const JWT_SECRET = process.env.JWT_SECRET || 'revenue-portal-jwt-dev-secret'
const CALLBACK_SECRET = process.env.CALLBACK_SECRET || 'revenue-portal-dev-secret'
const ONEDESK_CALLBACK_URL = process.env.ONEDESK_CALLBACK_URL || 'http://core-api:3000/interop/dept-callback/revenue'
const SEED_OFFICER_USERNAME = process.env.SEED_OFFICER_USERNAME || 'admin1'
const SEED_OFFICER_PASSWORD = process.env.SEED_OFFICER_PASSWORD || 'admin123'
const RETIRED_OFFICER_USERNAME = 'officer.revenue'

const pool = new Pool({ connectionString: process.env.DATABASE_URL })

// Same shape as core-api's ApplicationEventsService — one process-local emitter,
// one 'case' event carrying the full row, subscribed to by the SSE route below.
const caseEvents = new EventEmitter()
caseEvents.setMaxListeners(50)

async function ensureSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS officers (
      username TEXT PRIMARY KEY,
      password_hash TEXT NOT NULL
    )
  `)
  await pool.query(`
    CREATE TABLE IF NOT EXISTS cases (
      application_id TEXT PRIMARY KEY,
      application_type TEXT NOT NULL,
      citizen_master_id TEXT NOT NULL,
      citizen_name TEXT NOT NULL,
      address TEXT,
      consented_data_category TEXT,
      documents JSONB NOT NULL DEFAULT '[]',
      status TEXT NOT NULL DEFAULT 'PENDING_REVIEW',
      remark TEXT,
      decided_by TEXT,
      decided_at TIMESTAMPTZ,
      received_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `)
  // Added after the first cases table shipped — additive so an existing volume
  // keeps its rows instead of needing a wipe.
  await pool.query(`ALTER TABLE cases ADD COLUMN IF NOT EXISTS submitted_on TEXT`)
  await pool.query(`ALTER TABLE cases ADD COLUMN IF NOT EXISTS date_of_birth TEXT`)
  await pool.query(`ALTER TABLE cases ADD COLUMN IF NOT EXISTS phone_number TEXT`)
  await pool.query(`ALTER TABLE cases ADD COLUMN IF NOT EXISTS employment_status TEXT`)
  const { rows } = await pool.query('SELECT 1 FROM officers WHERE username = $1', [SEED_OFFICER_USERNAME])
  if (rows.length === 0) {
    const hash = await bcrypt.hash(SEED_OFFICER_PASSWORD, 10)
    await pool.query('INSERT INTO officers (username, password_hash) VALUES ($1, $2)', [SEED_OFFICER_USERNAME, hash])
    console.log(`[revenue-portal] seeded officer "${SEED_OFFICER_USERNAME}"`)
  }
  // One login per portal, not two — retire the old per-department account now that
  // every portal shares admin1/admin123.
  await pool.query('DELETE FROM officers WHERE username = $1', [RETIRED_OFFICER_USERNAME])
}

async function waitForPostgres(retries = 20, delayMs = 1000) {
  for (let i = 0; i < retries; i++) {
    try {
      await pool.query('SELECT 1')
      return
    } catch {
      await new Promise((r) => setTimeout(r, delayMs))
    }
  }
  throw new Error('revenue-portal: postgres never became ready')
}

function signCallback(applicationId, decision, decidedBy, decidedAt) {
  return crypto
    .createHmac('sha256', CALLBACK_SECRET)
    .update(`${applicationId}|${decision}|${decidedBy}|${decidedAt}`)
    .digest('hex')
}

async function notifyOneDesk(applicationId, decision, remark, decidedBy, decidedAt) {
  const signature = signCallback(applicationId, decision, decidedBy, decidedAt)
  try {
    const res = await fetch(ONEDESK_CALLBACK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-signature': signature },
      body: JSON.stringify({ applicationId, decision, remark, decidedBy, decidedAt }),
      signal: AbortSignal.timeout(5000),
    })
    if (!res.ok) console.error(`[revenue-portal] callback to OneDesk failed: ${res.status}`)
  } catch (err) {
    console.error(`[revenue-portal] callback to OneDesk errored: ${err.message}`)
  }
}

function requireAuth(req, res, next) {
  const header = req.headers.authorization || ''
  const token = header.startsWith('Bearer ') ? header.slice(7) : null
  if (!token) return res.status(401).json({ error: 'missing bearer token' })
  try {
    req.officer = jwt.verify(token, JWT_SECRET)
    next()
  } catch {
    res.status(401).json({ error: 'invalid or expired token' })
  }
}

/**
 * Strips each document's signed OneDesk URL before the row goes to a browser.
 * The officer UI fetches documents through this backend's own proxy route
 * instead, so the signed pointer never leaves the server — the department holds
 * the credential, not whoever is sitting in front of the screen.
 */
function sanitizeCase(row) {
  const docs = typeof row.documents === 'string' ? JSON.parse(row.documents) : (row.documents ?? [])
  return {
    ...row,
    documents: docs.map(({ url: _url, ...rest }) => rest),
  }
}

async function publishCase(applicationId) {
  const { rows } = await pool.query('SELECT * FROM cases WHERE application_id = $1', [applicationId])
  if (rows.length > 0) caseEvents.emit('case', sanitizeCase(rows[0]))
}

// --- API (backend port) --------------------------------------------------------

const api = express()
api.use(cors())
api.use(express.json())

api.get('/health', (_req, res) => res.json({ status: 'ok', service: 'revenue-portal' }))

// Inbound from OneDesk core-api — accepts a case for review, doesn't decide anything.
api.post('/api/cases', async (req, res) => {
  const { applicationId, applicationType, submittedOn, citizen, documents } = req.body || {}
  if (!applicationId || !citizen?.masterId) {
    return res.status(400).json({ accepted: false, error: 'applicationId and citizen.masterId are required' })
  }
  await pool.query(
    `INSERT INTO cases (application_id, application_type, submitted_on, citizen_master_id, citizen_name, address,
       consented_data_category, date_of_birth, phone_number, employment_status, documents, status)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'PENDING_REVIEW')
     ON CONFLICT (application_id) DO UPDATE SET
       application_type = EXCLUDED.application_type, submitted_on = EXCLUDED.submitted_on,
       citizen_name = EXCLUDED.citizen_name, address = EXCLUDED.address,
       consented_data_category = EXCLUDED.consented_data_category, date_of_birth = EXCLUDED.date_of_birth,
       phone_number = EXCLUDED.phone_number, employment_status = EXCLUDED.employment_status,
       documents = EXCLUDED.documents, status = 'PENDING_REVIEW', remark = NULL, decided_by = NULL, decided_at = NULL`,
    [
      applicationId,
      applicationType ?? 'Unknown',
      submittedOn ?? null,
      citizen.masterId,
      citizen.name ?? 'Unknown',
      citizen.address ?? null,
      citizen.consentedDataCategory ?? null,
      citizen.dateOfBirth ?? null,
      citizen.phoneNumber ?? null,
      citizen.employmentStatus ?? null,
      JSON.stringify(documents ?? []),
    ],
  )
  await publishCase(applicationId)
  res.json({ accepted: true })
})

// Live updates for the officer UI — token as a query param since EventSource can't
// set an Authorization header (same reasoning as core-api's
// applications-events.controller.ts, which this mirrors).
api.get('/api/events', (req, res) => {
  try {
    jwt.verify(req.query.token || '', JWT_SECRET)
  } catch {
    return res.status(401).end()
  }

  res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', Connection: 'keep-alive' })
  res.write(': connected\n\n')

  const onCase = (row) => res.write(`data: ${JSON.stringify(row)}\n\n`)
  caseEvents.on('case', onCase)
  const heartbeat = setInterval(() => res.write(': heartbeat\n\n'), 20000)

  req.on('close', () => {
    clearInterval(heartbeat)
    caseEvents.off('case', onCase)
    res.end()
  })
})

api.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body || {}
  if (!username || !password) return res.status(400).json({ error: 'username and password are required' })
  const { rows } = await pool.query('SELECT * FROM officers WHERE username = $1', [username])
  if (rows.length === 0 || !(await bcrypt.compare(password, rows[0].password_hash))) {
    return res.status(401).json({ error: 'invalid credentials' })
  }
  const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: '8h' })
  res.json({ token, username })
})

api.get('/api/cases', requireAuth, async (_req, res) => {
  const { rows } = await pool.query('SELECT * FROM cases ORDER BY received_at DESC')
  res.json(rows.map(sanitizeCase))
})

api.get('/api/cases/:id', requireAuth, async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM cases WHERE application_id = $1', [req.params.id])
  if (rows.length === 0) return res.status(404).json({ error: 'case not found' })
  res.json(sanitizeCase(rows[0]))
})

/**
 * Serves a citizen document to the officer's browser by fetching it from OneDesk
 * with the signed URL stored on the case. Proxied rather than redirected so the
 * signature stays server-side and the officer UI can render the file from its own
 * origin (no cross-origin iframe/CORS problem to work around).
 */
api.get('/api/cases/:id/documents/:docId/file', requireAuth, async (req, res) => {
  const { rows } = await pool.query('SELECT documents FROM cases WHERE application_id = $1', [req.params.id])
  if (rows.length === 0) return res.status(404).json({ error: 'case not found' })
  const docs = typeof rows[0].documents === 'string' ? JSON.parse(rows[0].documents) : (rows[0].documents ?? [])
  const doc = docs.find((d) => d.docId === req.params.docId)
  if (!doc?.url) return res.status(404).json({ error: 'document not available for this case' })

  try {
    const upstream = await fetch(doc.url, { signal: AbortSignal.timeout(10000) })
    if (!upstream.ok) {
      console.error(`[revenue-portal] document fetch from OneDesk failed: ${upstream.status}`)
      return res.status(502).json({ error: 'could not retrieve the document from OneDesk' })
    }
    res.type(doc.mimeType || upstream.headers.get('content-type') || 'application/octet-stream')
    res.setHeader('Content-Disposition', `inline; filename="${encodeURIComponent(doc.type || 'document')}"`)
    res.send(Buffer.from(await upstream.arrayBuffer()))
  } catch (err) {
    console.error(`[revenue-portal] document fetch errored: ${err.message}`)
    res.status(502).json({ error: 'could not retrieve the document from OneDesk' })
  }
})

api.post('/api/cases/:id/decision', requireAuth, async (req, res) => {
  const { decision, remark } = req.body || {}
  if (decision !== 'APPROVED' && decision !== 'REJECTED') {
    return res.status(400).json({ error: 'decision must be APPROVED or REJECTED' })
  }
  const { rows } = await pool.query('SELECT * FROM cases WHERE application_id = $1', [req.params.id])
  if (rows.length === 0) return res.status(404).json({ error: 'case not found' })
  if (rows[0].status !== 'PENDING_REVIEW') return res.status(409).json({ error: 'case already decided' })

  const decidedAt = new Date().toISOString()
  await pool.query(
    'UPDATE cases SET status = $2, remark = $3, decided_by = $4, decided_at = $5 WHERE application_id = $1',
    [req.params.id, decision, remark ?? '', req.officer.username, decidedAt],
  )
  await publishCase(req.params.id)
  await notifyOneDesk(req.params.id, decision, remark ?? '', req.officer.username, decidedAt)
  res.json({ ok: true })
})

// --- Officer UI (frontend port) -------------------------------------------------

const frontend = express()
// mammoth's browser build, served from this portal's own origin so the officer UI
// can render a .docx attachment inline (browsers have no native DOCX viewer the
// way they do for PDFs and images).
frontend.use('/vendor/mammoth.browser.min.js', express.static(require.resolve('mammoth/mammoth.browser.min.js')))
frontend.use(express.static(path.join(__dirname, 'public')))

async function main() {
  await waitForPostgres()
  await ensureSchema()
  api.listen(API_PORT, () => console.log(`[revenue-portal] API listening on ${API_PORT}`))
  frontend.listen(FRONTEND_PORT, () => console.log(`[revenue-portal] Officer UI listening on ${FRONTEND_PORT}`))
}

main()
