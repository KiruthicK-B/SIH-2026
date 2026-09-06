// Mock "Business Registry" department system — legacy SOAP/XML, no REST API.
// core-api's ConnectorsService translates its canonical request into this XML shape
// and parses the XML response back — this is the whole point of the adapter pattern:
// the rest of the platform never sees SOAP, only ConnectorsService does.
const express = require('express')
const { parseStringPromise, Builder } = require('xml2js')

const app = express()
app.use(express.text({ type: '*/*' }))

const PORT = process.env.PORT || 4001
const builder = new Builder({ headless: true })

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'business-registry-adapter' }))

app.post('/verify', async (req, res) => {
  let applicationId = 'unknown'
  try {
    const parsed = await parseStringPromise(req.body)
    applicationId = parsed?.VerifyBusinessRequest?.ApplicationId?.[0] ?? 'unknown'
  } catch {
    // malformed XML — fall through, still respond so the demo doesn't hard-fail
  }

  const valid = /^[A-Za-z0-9-]{4,}$/.test(applicationId)

  setTimeout(() => {
    const xml = builder.buildObject({
      VerifyBusinessResponse: { ApplicationId: applicationId, Status: valid ? 'VERIFIED' : 'REJECTED' },
    })
    res.set('Content-Type', 'application/xml')
    res.send(xml)
  }, 1500)
})

app.listen(PORT, () => console.log(`business-registry-adapter (SOAP mock) listening on ${PORT}`))
