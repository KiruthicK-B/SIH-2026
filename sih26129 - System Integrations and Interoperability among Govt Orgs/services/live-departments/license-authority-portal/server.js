// License Authority Portal — an independently-run system, not a OneDesk module.
// GraphQL submit API + its own MongoDB database + its own officer login,
// deliberately outside OneDesk's Keycloak trust boundary (see
// LIVE_DEPARTMENT_PORTALS_PLAN.md §6). Officer-facing endpoints are plain JSON —
// only the OneDesk-facing submit leg is actually GraphQL.
const path = require('node:path')
const crypto = require('node:crypto')
const { EventEmitter } = require('node:events')
const express = require('express')
const cors = require('cors')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')
const { MongoClient } = require('mongodb')
const { createSchema, createYoga } = require('graphql-yoga')

const API_PORT = process.env.PORT || 4302
const FRONTEND_PORT = process.env.FRONTEND_PORT || 5302
const JWT_SECRET = process.env.JWT_SECRET || 'license-authority-portal-jwt-dev-secret'
const CALLBACK_SECRET = process.env.CALLBACK_SECRET || 'license-authority-portal-dev-secret'
const ONEDESK_CALLBACK_URL = process.env.ONEDESK_CALLBACK_URL || 'http://core-api:3000/interop/dept-callback/license-authority'
const SEED_OFFICER_USERNAME = process.env.SEED_OFFICER_USERNAME || 'admin1'
const SEED_OFFICER_PASSWORD = process.env.SEED_OFFICER_PASSWORD || 'admin123'
const RETIRED_OFFICER_USERNAME = 'officer.licenseauthority'
const MONGO_URL = process.env.MONGO_URL || 'mongodb://license-authority-mongo:27017'
const MONGO_DB = process.env.MONGO_DB || 'license_authority_portal'

let db
const caseEvents = new EventEmitter()
caseEvents.setMaxListeners(50)

async function waitForMongo(retries = 20, delayMs = 1000) {
  for (let i = 0; i < retries; i++) {
    try {
      const client = new MongoClient(MONGO_URL, { serverSelectionTimeoutMS: 2000 })
      await client.connect()
      db = client.db(MONGO_DB)
      await db.command({ ping: 1 })
      return
    } catch {
      await new Promise((r) => setTimeout(r, delayMs))
    }
  }
  throw new Error('license-authority-portal: mongo never became ready')
}

async function ensureSeedOfficer() {
  const existing = await db.collection('officers').findOne({ username: SEED_OFFICER_USERNAME })
  if (!existing) {
    const passwordHash = await bcrypt.hash(SEED_OFFICER_PASSWORD, 10)
    await db.collection('officers').insertOne({ username: SEED_OFFICER_USERNAME, passwordHash })
    console.log(`[license-authority-portal] seeded officer "${SEED_OFFICER_USERNAME}"`)
  }
  await db.collection('cases').createIndex({ applicationId: 1 }, { unique: true })
  await db.collection('officers').deleteOne({ username: RETIRED_OFFICER_USERNAME })
}

/**
 * Strips each document's signed OneDesk URL before the row goes to a browser.
 * The officer UI fetches documents through this backend's own proxy route
 * instead, so the signed pointer never leaves the server — the department holds
 * the credential, not whoever is sitting in front of the screen.
 */
function sanitizeCase(c) {
  return {
    ...c,
    documents: (c.documents ?? []).map(({ url: _url, ...rest }) => rest),
  }
}

async function publishCase(applicationId) {
  const c = await db.collection('cases').findOne({ applicationId })
  if (c) caseEvents.emit('case', sanitizeCase(c))
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
    if (!res.ok) console.error(`[license-authority-portal] callback to OneDesk failed: ${res.status}`)
  } catch (err) {
    console.error(`[license-authority-portal] callback to OneDesk errored: ${err.message}`)
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

// --- GraphQL submit endpoint (OneDesk-facing) -----------------------------------

const typeDefs = /* GraphQL */ `
  type Query {
    health: String!
  }
  input DocumentInput {
    docId: String!
    type: String!
    mimeType: String
    """Signed pointer back to OneDesk — this portal's backend fetches through it;
    the file bytes never travel in the submit payload."""
    url: String
  }
  input SubmitCaseInput {
    applicationId: String!
    applicationType: String!
    submittedOn: String
    citizenMasterId: String!
    citizenName: String!
    consentedDataCategory: String
    address: String
    dateOfBirth: String
    phoneNumber: String
    employmentStatus: String
    documents: [DocumentInput!]
  }
  type SubmitCaseResult {
    accepted: Boolean!
  }
  type Mutation {
    submitCase(input: SubmitCaseInput!): SubmitCaseResult!
  }
`

const resolvers = {
  Query: { health: () => 'ok' },
  Mutation: {
    submitCase: async (_parent, { input }) => {
      await db.collection('cases').updateOne(
        { applicationId: input.applicationId },
        {
          $set: {
            applicationId: input.applicationId,
            applicationType: input.applicationType,
            submittedOn: input.submittedOn ?? null,
            citizenMasterId: input.citizenMasterId,
            citizenName: input.citizenName,
            consentedDataCategory: input.consentedDataCategory ?? null,
            address: input.address ?? null,
            dateOfBirth: input.dateOfBirth ?? null,
            phoneNumber: input.phoneNumber ?? null,
            employmentStatus: input.employmentStatus ?? null,
            documents: input.documents ?? [],
            status: 'PENDING_REVIEW',
            remark: null,
            decidedBy: null,
            decidedAt: null,
            receivedAt: new Date(),
          },
        },
        { upsert: true },
      )
      await publishCase(input.applicationId)
      return { accepted: true }
    },
  },
}

const yoga = createYoga({ schema: createSchema({ typeDefs, resolvers }), graphqlEndpoint: '/graphql' })

const api = express()
api.use(cors())
api.get('/health', (_req, res) => res.json({ status: 'ok', service: 'license-authority-portal' }))
api.use('/graphql', yoga)

// --- Officer REST API (internal, not part of the OneDesk-facing protocol) -------

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
  const officer = await db.collection('officers').findOne({ username })
  if (!officer || !(await bcrypt.compare(password, officer.passwordHash))) {
    return res.status(401).json({ error: 'invalid credentials' })
  }
  const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: '8h' })
  res.json({ token, username })
})

api.get('/api/cases', requireAuth, async (_req, res) => {
  const cases = await db.collection('cases').find({}).sort({ receivedAt: -1 }).toArray()
  res.json(cases.map(sanitizeCase))
})

api.get('/api/cases/:id', requireAuth, async (req, res) => {
  const c = await db.collection('cases').findOne({ applicationId: req.params.id })
  if (!c) return res.status(404).json({ error: 'case not found' })
  res.json(sanitizeCase(c))
})

/**
 * Serves a citizen document to the officer's browser by fetching it from OneDesk
 * with the signed URL stored on the case. Proxied rather than redirected so the
 * signature stays server-side and the officer UI can render the file from its own
 * origin (no cross-origin iframe/CORS problem to work around).
 */
api.get('/api/cases/:id/documents/:docId/file', requireAuth, async (req, res) => {
  const c = await db.collection('cases').findOne({ applicationId: req.params.id })
  if (!c) return res.status(404).json({ error: 'case not found' })
  const doc = (c.documents ?? []).find((d) => d.docId === req.params.docId)
  if (!doc?.url) return res.status(404).json({ error: 'document not available for this case' })

  try {
    const upstream = await fetch(doc.url, { signal: AbortSignal.timeout(10000) })
    if (!upstream.ok) {
      console.error(`[license-authority-portal] document fetch from OneDesk failed: ${upstream.status}`)
      return res.status(502).json({ error: 'could not retrieve the document from OneDesk' })
    }
    res.type(doc.mimeType || upstream.headers.get('content-type') || 'application/octet-stream')
    res.setHeader('Content-Disposition', `inline; filename="${encodeURIComponent(doc.type || 'document')}"`)
    res.send(Buffer.from(await upstream.arrayBuffer()))
  } catch (err) {
    console.error(`[license-authority-portal] document fetch errored: ${err.message}`)
    res.status(502).json({ error: 'could not retrieve the document from OneDesk' })
  }
})

api.post('/api/cases/:id/decision', requireAuth, async (req, res) => {
  const { decision, remark } = req.body || {}
  if (decision !== 'APPROVED' && decision !== 'REJECTED') {
    return res.status(400).json({ error: 'decision must be APPROVED or REJECTED' })
  }
  const c = await db.collection('cases').findOne({ applicationId: req.params.id })
  if (!c) return res.status(404).json({ error: 'case not found' })
  if (c.status !== 'PENDING_REVIEW') return res.status(409).json({ error: 'case already decided' })

  const decidedAt = new Date()
  await db.collection('cases').updateOne(
    { applicationId: req.params.id },
    { $set: { status: decision, remark: remark ?? '', decidedBy: req.officer.username, decidedAt } },
  )
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
  await waitForMongo()
  await ensureSeedOfficer()
  api.listen(API_PORT, () => console.log(`[license-authority-portal] API listening on ${API_PORT}`))
  frontend.listen(FRONTEND_PORT, () => console.log(`[license-authority-portal] Officer UI listening on ${FRONTEND_PORT}`))
}

main()
