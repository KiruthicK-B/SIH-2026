// Mock "Identity Service" — OAuth/OIDC token-introspection endpoint (RFC 7662 shape).
// This department doesn't hand core-api a citizen record; it confirms whether the
// presented application/session token is currently valid — a real adapter service
// instead of the inline stub ConnectorsService.verifyIdentity() used to be.
const express = require('express')

const app = express()
app.use(express.json())

const PORT = process.env.PORT || 4000

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'identity-adapter' }))

app.post('/introspect', (req, res) => {
  const { applicationId } = req.body
  const valid = typeof applicationId === 'string' && /^[A-Za-z0-9-]{4,}$/.test(applicationId)

  setTimeout(() => {
    if (!valid) {
      res.json({ active: false })
      return
    }
    res.json({ active: true, sub: applicationId, token_type: 'Bearer' })
  }, 800)
})

app.listen(PORT, () => console.log(`identity-adapter (OAuth introspection mock) listening on ${PORT}`))
