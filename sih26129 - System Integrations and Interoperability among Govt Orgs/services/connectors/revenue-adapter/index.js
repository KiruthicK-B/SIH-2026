// Mock "Revenue Department" system — modern REST/JSON.
// Phase 3 adds real consent enforcement here (reject the call if the citizen hasn't
// granted a valid, unexpired consent token for tax data) — for now it just verifies.
const express = require('express')

const app = express()
app.use(express.json())

const PORT = process.env.PORT || 4002

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'revenue-adapter' }))

app.post('/verify-tax', (req, res) => {
  const { applicationId } = req.body
  const valid = typeof applicationId === 'string' && /^[A-Za-z0-9-]{4,}$/.test(applicationId)
  setTimeout(() => {
    res.json({ applicationId, status: valid ? 'VERIFIED' : 'REJECTED' })
  }, 1800)
})

app.listen(PORT, () => console.log(`revenue-adapter (REST mock) listening on ${PORT}`))
