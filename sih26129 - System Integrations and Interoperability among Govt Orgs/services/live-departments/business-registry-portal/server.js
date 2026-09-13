// Business Registry Portal — an independently-run system, not a OneDesk module.
// Legacy SOAP/XML submit API + its own MySQL database + its own officer login,
// deliberately outside OneDesk's Keycloak trust boundary (see
// LIVE_DEPARTMENT_PORTALS_PLAN.md §6). Officer-facing endpoints are plain JSON —
// only the OneDesk-facing submit leg is actually SOAP, matching what a real legacy
// system's outward integration point would look like.
const path = require('node:path')
const crypto = require('node:crypto')
const { EventEmitter } = require('node:events')
const express = require('express')
const cors = require('cors')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')
const mysql = require('mysql2/promise')
const { parseStringPromise, Builder } = require('xml2js')

const API_PORT = process.env.PORT || 4301
const FRONTEND_PORT = process.env.FRONTEND_PORT || 5301
const JWT_SECRET = process.env.JWT_SECRET || 'business-registry-portal-jwt-dev-secret'
const CALLBACK_SECRET = process.env.CALLBACK_SECRET || 'business-registry-portal-dev-secret'
const ONEDESK_CALLBACK_URL = process.env.ONEDESK_CALLBACK_URL || 'http://core-api:3000/interop/dept-callback/business-registry'
const SEED_OFFICER_USERNAME = process.env.SEED_OFFICER_USERNAME || 'admin1'
const SEED_OFFICER_PASSWORD = process.env.SEED_OFFICER_PASSWORD || 'admin123'
const RETIRED_OFFICER_USERNAME = 'officer.businessregistry'

const pool = mysql.createPool(process.env.DATABASE_URL)
const xmlBuilder = new Builder({ headless: true })

const caseEvents = new EventEmitter()
caseEvents.setMaxListeners(50)

async function waitForMysql(retries = 20, delayMs = 1000) {
  for (let i = 0; i < retries; i++) {
    try {
      await pool.query('SELECT 1')
      return
    } catch {
      await new Promise((r) => setTimeout(r, delayMs))
    }
  }
  throw new Error('business-registry-portal: mysql never became ready')
}

async function ensureSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS officers (
      username VARCHAR(191) PRIMARY KEY,
      password_hash VARCHAR(191) NOT NULL
    )
  `)
  await pool.query(`
    CREATE TABLE IF NOT EXISTS cases (
      application_id VARCHAR(191) PRIMARY KEY,
      application_type VARCHAR(191) NOT NULL,
      citizen_master_id VARCHAR(191) NOT NULL,
      citizen_name VARCHAR(191) NOT NULL,
      address TEXT,
      consented_data_category VARCHAR(191),
      documents JSON NOT NULL,
      status VARCHAR(32) NOT NULL DEFAULT 'PENDING_REVIEW',
      remark TEXT,
      decided_by VARCHAR(191),
      decided_at DATETIME NULL,
      received_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `)
  // Added after the first cases table shipped — additive so an existing volume
  // keeps its rows instead of needing a wipe. MySQL has no ADD COLUMN IF NOT
  // EXISTS, so a duplicate-column error here is the expected no-op on re-run.
  for (const col of [
    'submitted_on VARCHAR(32)',
    'date_of_birth VARCHAR(32)',
    'phone_number VARCHAR(32)',
    'employment_status VARCHAR(64)',
  ]) {
    try {
      await pool.query(`ALTER TABLE cases ADD COLUMN ${col}`)
    } catch (err) {
      if (err.code !== 'ER_DUP_FIELDNAME') throw err
    }
  }

  const [rows] = await pool.query('SELECT 1 FROM officers WHERE username = ?', [SEED_OFFICER_USERNAME])
  if (rows.length === 0) {
    const hash = await bcrypt.hash(SEED_OFFICER_PASSWORD, 10)
    await pool.query('INSERT INTO officers (username, password_hash) VALUES (?, ?)', [SEED_OFFICER_USERNAME, hash])
    console.log(`[business-registry-portal] seeded officer "${SEED_OFFICER_USERNAME}"`)
  }
  await pool.query('DELETE FROM officers WHERE username = ?', [RETIRED_OFFICER_USERNAME])
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
  const [rows] = await pool.query('SELECT * FROM cases WHERE application_id = ?', [applicationId])
  if (rows.length > 0) caseEvents.emit('case', sanitizeCase(rows[0]))
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
    if (!res.ok) console.error(`[business-registry-portal] callback to OneDesk failed: ${res.status}`)
  } catch (err) {
    console.error(`[business-registry-portal] callback to OneDesk errored: ${err.message}`)
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

const api = express()
api.use(cors())

api.get('/health', (_req, res) => res.json({ status: 'ok', service: 'business-registry-portal' }))

// Inbound from OneDesk core-api — SOAP/XML, matching connectors.service.ts's submitSoap.
api.post('/soap/submit', express.text({ type: '*/*' }), async (req, res) => {
  let parsed
  try {
    parsed = await parseStringPromise(req.body)
  } catch {
    res.set('Content-Type', 'application/xml')
    return res.status(400).send(xmlBuilder.buildObject({ SubmitCaseResponse: { Accepted: 'false' } }))
  }
  const r = parsed?.SubmitCaseRequest
  const applicationId = r?.ApplicationId?.[0]
  const citizenMasterId = r?.CitizenMasterId?.[0]
  if (!applicationId || !citizenMasterId) {
    res.set('Content-Type', 'application/xml')
    return res.status(400).send(xmlBuilder.buildObject({ SubmitCaseResponse: { Accepted: 'false' } }))
  }
  const documents = (r?.Documents?.[0]?.Document ?? []).map((d) => ({
    docId: d.DocId?.[0],
    type: d.Type?.[0],
    mimeType: d.MimeType?.[0] || null,
    url: d.Url?.[0] || null,
  }))

  // xml2js gives '' for a self-closed/empty element — normalize to null so the
  // officer UI's "—" placeholder shows instead of a blank-looking value.
  const orNull = (v) => (v === undefined || v === '' ? null : v)

  await pool.query(
    `INSERT INTO cases (application_id, application_type, submitted_on, citizen_master_id, citizen_name, address,
       consented_data_category, date_of_birth, phone_number, employment_status, documents, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING_REVIEW')
     ON DUPLICATE KEY UPDATE application_type = VALUES(application_type), submitted_on = VALUES(submitted_on),
       citizen_name = VALUES(citizen_name), address = VALUES(address),
       consented_data_category = VALUES(consented_data_category), date_of_birth = VALUES(date_of_birth),
       phone_number = VALUES(phone_number), employment_status = VALUES(employment_status),
       documents = VALUES(documents), status = 'PENDING_REVIEW', remark = NULL, decided_by = NULL, decided_at = NULL`,
    [
      applicationId,
      r?.ApplicationType?.[0] ?? 'Unknown',
      orNull(r?.SubmittedOn?.[0]),
      citizenMasterId,
      r?.CitizenName?.[0] ?? 'Unknown',
      orNull(r?.Address?.[0]),
      orNull(r?.ConsentedDataCategory?.[0]),
      orNull(r?.DateOfBirth?.[0]),
      orNull(r?.PhoneNumber?.[0]),
      orNull(r?.EmploymentStatus?.[0]),
      JSON.stringify(documents),
    ],
  )

  await publishCase(applicationId)
  res.set('Content-Type', 'application/xml')
  res.send(xmlBuilder.buildObject({ SubmitCaseResponse: { Accepted: 'true' } }))
})

api.use(express.json())

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
  const [rows] = await pool.query('SELECT * FROM officers WHERE username = ?', [username])
  if (rows.length === 0 || !(await bcrypt.compare(password, rows[0].password_hash))) {
    return res.status(401).json({ error: 'invalid credentials' })
  }
  const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: '8h' })
  res.json({ token, username })
})

api.get('/api/cases', requireAuth, async (_req, res) => {
  const [rows] = await pool.query('SELECT * FROM cases ORDER BY received_at DESC')
  res.json(rows.map(sanitizeCase))
})

api.get('/api/cases/:id', requireAuth, async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM cases WHERE application_id = ?', [req.params.id])
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
  const [rows] = await pool.query('SELECT documents FROM cases WHERE application_id = ?', [req.params.id])
  if (rows.length === 0) return res.status(404).json({ error: 'case not found' })
  const docs = typeof rows[0].documents === 'string' ? JSON.parse(rows[0].documents) : (rows[0].documents ?? [])
  const doc = docs.find((d) => d.docId === req.params.docId)
  if (!doc?.url) return res.status(404).json({ error: 'document not available for this case' })

  try {
    const upstream = await fetch(doc.url, { signal: AbortSignal.timeout(10000) })
    if (!upstream.ok) {
      console.error(`[business-registry-portal] document fetch from OneDesk failed: ${upstream.status}`)
      return res.status(502).json({ error: 'could not retrieve the document from OneDesk' })
    }
    res.type(doc.mimeType || upstream.headers.get('content-type') || 'application/octet-stream')
    res.setHeader('Content-Disposition', `inline; filename="${encodeURIComponent(doc.type || 'document')}"`)
    res.send(Buffer.from(await upstream.arrayBuffer()))
  } catch (err) {
    console.error(`[business-registry-portal] document fetch errored: ${err.message}`)
    res.status(502).json({ error: 'could not retrieve the document from OneDesk' })
  }
})

api.post('/api/cases/:id/decision', requireAuth, async (req, res) => {
  const { decision, remark } = req.body || {}
  if (decision !== 'APPROVED' && decision !== 'REJECTED') {
    return res.status(400).json({ error: 'decision must be APPROVED or REJECTED' })
  }
  const [rows] = await pool.query('SELECT * FROM cases WHERE application_id = ?', [req.params.id])
  if (rows.length === 0) return res.status(404).json({ error: 'case not found' })
  if (rows[0].status !== 'PENDING_REVIEW') return res.status(409).json({ error: 'case already decided' })

  const decidedAt = new Date()
  await pool.query('UPDATE cases SET status = ?, remark = ?, decided_by = ?, decided_at = ? WHERE application_id = ?', [
    decision,
    remark ?? '',
    req.officer.username,
    decidedAt,
    req.params.id,
  ])
  await publishCase(req.params.id)
  await notifyOneDesk(req.params.id, decision, remark ?? '', req.officer.username, decidedAt.toISOString())
  res.json({ ok: true })
})

const frontend = express()
// mammoth's browser build, served from this portal's own origin so the officer UI
// can render a .docx attachment inline (browsers have no native DOCX viewer the
// way they do for PDFs and images).
frontend.use('/vendor/mammoth.browser.min.js', express.static(require.resolve('mammoth/mammoth.browser.min.js')))
frontend.use(express.static(path.join(__dirname, 'public')))

async function main() {
  await waitForMysql()
  await ensureSchema()
  api.listen(API_PORT, () => console.log(`[business-registry-portal] API listening on ${API_PORT}`))
  frontend.listen(FRONTEND_PORT, () => console.log(`[business-registry-portal] Officer UI listening on ${FRONTEND_PORT}`))
}

main()
