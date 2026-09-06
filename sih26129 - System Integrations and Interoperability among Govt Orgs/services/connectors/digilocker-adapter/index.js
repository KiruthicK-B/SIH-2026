const fs = require('fs')
const path = require('path')
const express = require('express')
const multer = require('multer')
const { Pool } = require('pg')
const committedRows = require('./seed-data')

const app = express()
app.use(express.json())

const PORT = process.env.PORT || 4005
const UPLOAD_DIR = process.env.UPLOAD_DIR || '/app/uploads'
fs.mkdirSync(UPLOAD_DIR, { recursive: true })

const pool = new Pool({ connectionString: process.env.DATABASE_URL })

// Mock "UIDAI/govt identity registry" — genuinely separate Postgres database (see
// docker-compose's DATABASE_URL), not a fake in-memory list. A citizen's identifier
// must actually exist in this table for eKYC to succeed, matching real life: UIDAI
// either has your record or it doesn't, it never invents one on the fly.
async function ensureSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS govt_identity_records (
      aadhaar_number TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      date_of_birth DATE NOT NULL,
      gender TEXT NOT NULL,
      address TEXT NOT NULL,
      pan_number TEXT,
      phone_number TEXT,
      employment_status TEXT,
      employer_name TEXT,
      designation TEXT,
      highest_qualification TEXT,
      institution_name TEXT,
      photo_path TEXT
    )
  `)
  // Added after the table already existed live — explicit ALTERs, not just extending
  // the CREATE above, so a running database picks these up on next boot too.
  await pool.query(`
    ALTER TABLE govt_identity_records
      ADD COLUMN IF NOT EXISTS father_name TEXT,
      ADD COLUMN IF NOT EXISTS mother_name TEXT,
      ADD COLUMN IF NOT EXISTS parent_phone_number TEXT,
      ADD COLUMN IF NOT EXISTS siblings TEXT,
      ADD COLUMN IF NOT EXISTS occupation TEXT
  `)
  // DEMO / MOCK GOVERNMENT DATA — lets the admin console simulate a citizen's
  // authoritative identity status changing (e.g. ACTIVE -> DECEASED) after
  // registration, so the workflow's live-revalidation check has something real to
  // detect. Never implies a real government registry is writable this way.
  await pool.query(`
    ALTER TABLE govt_identity_records
      ADD COLUMN IF NOT EXISTS identity_status TEXT NOT NULL DEFAULT 'ACTIVE'
  `)
}

function loadSeedRows() {
  try {
    const localRows = require('./seed-data.local')
    return [...committedRows, ...localRows]
  } catch {
    return committedRows
  }
}

async function seedRegistry() {
  const rows = loadSeedRows()
  for (const r of rows) {
    await pool.query(
      `INSERT INTO govt_identity_records
         (aadhaar_number, name, date_of_birth, gender, address, pan_number, phone_number,
          employment_status, employer_name, designation, highest_qualification, institution_name,
          father_name, mother_name, parent_phone_number, siblings, occupation)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
       ON CONFLICT (aadhaar_number) DO NOTHING`,
      [
        r.aadhaarNumber, r.name, r.dateOfBirth, r.gender, r.address, r.panNumber, r.phoneNumber,
        r.employmentStatus, r.employerName, r.designation, r.highestQualification, r.institutionName,
        r.fatherName ?? null, r.motherName ?? null, r.parentPhoneNumber ?? null, r.siblings ?? null, r.occupation ?? null,
      ],
    )
  }
  console.log(`digilocker-adapter: registry seeded (${rows.length} rows considered)`)
}

function toApiRecord(row) {
  return {
    aadhaarNumber: row.aadhaar_number,
    name: row.name,
    dateOfBirth: row.date_of_birth.toISOString().slice(0, 10),
    gender: row.gender,
    address: row.address,
    panNumber: row.pan_number,
    phoneNumber: row.phone_number,
    employmentStatus: row.employment_status,
    employerName: row.employer_name,
    designation: row.designation,
    highestQualification: row.highest_qualification,
    institutionName: row.institution_name,
    fatherName: row.father_name,
    motherName: row.mother_name,
    parentPhoneNumber: row.parent_phone_number,
    siblings: row.siblings,
    occupation: row.occupation,
    identityStatus: row.identity_status,
    hasPhoto: row.photo_path != null,
    simulated: true,
  }
}

const LOOKUP_COLUMN = { aadhaar: 'aadhaar_number', pan: 'pan_number', phone: 'phone_number' }

function validateLookupValue(medium, value) {
  if (medium === 'aadhaar') {
    const digits = typeof value === 'string' ? value.replace(/\D/g, '') : ''
    return digits.length === 12 ? digits : null
  }
  if (medium === 'pan') {
    const upper = typeof value === 'string' ? value.trim().toUpperCase() : ''
    return /^[A-Z]{5}\d{4}[A-Z]$/.test(upper) ? upper : null
  }
  if (medium === 'phone') {
    const digits = typeof value === 'string' ? value.replace(/\D/g, '') : ''
    return digits.length === 10 ? digits : null
  }
  return null
}

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'digilocker-adapter' }))

// Real lookup against the mock registry, by whichever medium the citizen chose to
// identify themselves with — 404 if not on file, exactly like the real UIDAI/PAN/
// telecom-linked lookup would behave for an unregistered value. aadhaar_number is the
// table's primary key regardless of medium, so the returned record always carries a
// real Aadhaar number even when looked up by PAN or phone.
app.post('/ekyc', async (req, res) => {
  const { medium, value } = req.body
  const column = LOOKUP_COLUMN[medium]
  if (!column) {
    return res.status(422).json({ error: 'INVALID_MEDIUM', message: 'medium must be aadhaar, pan, or phone' })
  }
  const cleaned = validateLookupValue(medium, value)
  if (!cleaned) {
    return res.status(422).json({ error: 'INVALID_VALUE', message: `Enter a valid ${medium} value` })
  }
  const { rows } = await pool.query(`SELECT * FROM govt_identity_records WHERE ${column} = $1`, [cleaned])
  if (rows.length === 0) {
    return res.status(404).json({ error: 'NOT_FOUND', message: 'No record on file for this identifier' })
  }
  setTimeout(() => res.json(toApiRecord(rows[0])), 700)
})

// Express's bundled mime-db doesn't recognize .avif, so sendFile()'s automatic
// Content-Type inference falls back to application/octet-stream for it — set the
// type explicitly instead of trusting that inference, so both this response and
// core-api's copy-on-registration (which reads this header to pick a file
// extension) see the real format.
const CONTENT_TYPE_BY_EXTENSION = { '.avif': 'image/avif', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp', '.gif': 'image/gif' }

app.get('/photo/:aadhaarNumber', async (req, res) => {
  const { rows } = await pool.query('SELECT photo_path FROM govt_identity_records WHERE aadhaar_number = $1', [req.params.aadhaarNumber])
  if (rows.length === 0 || !rows[0].photo_path) return res.status(404).json({ error: 'NOT_FOUND' })
  const photoPath = rows[0].photo_path
  res.type(CONTENT_TYPE_BY_EXTENSION[path.extname(photoPath).toLowerCase()] ?? 'application/octet-stream')
  res.sendFile(photoPath)
})

// Admin-only surface for the platform console's Govt Identity Registry tab — no auth
// here (matches every other adapter; core-api's RolesGuard gates access before
// proxying these calls).
app.get('/admin/records', async (_req, res) => {
  const { rows } = await pool.query('SELECT * FROM govt_identity_records ORDER BY name')
  res.json(rows.map(toApiRecord))
})

app.post('/admin/records', async (req, res) => {
  const b = req.body
  const aadhaarNumber = validateLookupValue('aadhaar', b.aadhaarNumber)
  if (!aadhaarNumber) return res.status(422).json({ error: 'INVALID_AADHAAR', message: 'Aadhaar number must be 12 digits' })
  if (!b.name || !b.dateOfBirth || !b.gender || !b.address) {
    return res.status(422).json({ error: 'MISSING_FIELDS', message: 'name, dateOfBirth, gender, and address are required' })
  }
  try {
    await pool.query(
      `INSERT INTO govt_identity_records
         (aadhaar_number, name, date_of_birth, gender, address, pan_number, phone_number,
          employment_status, employer_name, designation, highest_qualification, institution_name,
          father_name, mother_name, parent_phone_number, siblings, occupation)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)`,
      [
        aadhaarNumber, b.name, b.dateOfBirth, b.gender, b.address, b.panNumber || null, b.phoneNumber || null,
        b.employmentStatus || null, b.employerName || null, b.designation || null, b.highestQualification || null, b.institutionName || null,
        b.fatherName || null, b.motherName || null, b.parentPhoneNumber || null, b.siblings || null, b.occupation || null,
      ],
    )
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'DUPLICATE', message: 'A record with this Aadhaar number already exists' })
    throw err
  }
  res.status(201).json({ ok: true, aadhaarNumber })
})

// DEMO / MOCK GOVERNMENT DATA — admin-only simulation of an authoritative identity
// status change (e.g. a citizen being reported deceased in the real UIDAI registry).
// This does NOT represent any real government system being writable by OneDesk;
// core-api's RBAC gates who can ever reach this, same as every other /admin route.
app.post('/admin/records/:aadhaarNumber/identity-status', async (req, res) => {
  const status = req.body.status
  if (status !== 'ACTIVE' && status !== 'DECEASED') {
    return res.status(422).json({ error: 'INVALID_STATUS', message: 'status must be ACTIVE or DECEASED' })
  }
  const { rowCount } = await pool.query('UPDATE govt_identity_records SET identity_status = $1 WHERE aadhaar_number = $2', [status, req.params.aadhaarNumber])
  if (rowCount === 0) return res.status(404).json({ error: 'NOT_FOUND' })
  res.json({ ok: true, identityStatus: status })
})

// Never build the on-disk path from the client-supplied filename — path.extname only
// ever reads past the last path separator, so it can't itself carry a traversal
// sequence, unlike concatenating file.originalname directly.
const upload = multer({
  storage: multer.diskStorage({ destination: UPLOAD_DIR, filename: (_req, file, cb) => cb(null, `${Date.now()}${path.extname(file.originalname)}`) }),
  limits: { fileSize: 5 * 1024 * 1024 },
})
app.post('/admin/records/:aadhaarNumber/photo', upload.single('photo'), async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'NO_FILE' })
  const { rowCount } = await pool.query('UPDATE govt_identity_records SET photo_path = $1 WHERE aadhaar_number = $2', [req.file.path, req.params.aadhaarNumber])
  if (rowCount === 0) return res.status(404).json({ error: 'NOT_FOUND' })
  res.json({ ok: true })
})

async function start() {
  await ensureSchema()
  await seedRegistry()
  app.listen(PORT, () => console.log(`digilocker-adapter (simulated UIDAI/DigiLocker registry) listening on ${PORT}`))
}

start()
