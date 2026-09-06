// Mock "License Authority" system — a genuine GraphQL API (graphql-yoga), the final
// approval step. Distinct from the other 4 adapters (OAuth/SOAP/REST/DB) so the 5
// live-connector departments together demonstrate 5 real, different integration
// protocols instead of one repeated REST shape.
const express = require('express')
const { createSchema, createYoga } = require('graphql-yoga')

const app = express()
const PORT = process.env.PORT || 4004

const typeDefs = /* GraphQL */ `
  type ApprovalResult {
    applicationId: ID!
    status: String!
  }

  type Query {
    health: String!
  }

  type Mutation {
    approveApplication(applicationId: ID!): ApprovalResult!
  }
`

const resolvers = {
  Query: {
    health: () => 'ok',
  },
  Mutation: {
    approveApplication: async (_parent, { applicationId }) => {
      const valid = /^[A-Za-z0-9-]{4,}$/.test(applicationId)
      await new Promise((resolve) => setTimeout(resolve, 1500))
      return { applicationId, status: valid ? 'APPROVED' : 'REJECTED' }
    },
  },
}

const yoga = createYoga({ schema: createSchema({ typeDefs, resolvers }), graphqlEndpoint: '/graphql' })

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'license-authority-adapter' }))
app.use('/graphql', yoga)

app.listen(PORT, () => console.log(`license-authority-adapter (GraphQL) listening on ${PORT}`))
