// Runtime consent data now lives in core-api/Postgres (see ConsentsContext.tsx, which
// fetches from GET /consents and GET /consents/pending). This file keeps only the
// shared type contract.

export type ConsentStatus = 'Active' | 'Revoked' | 'Expired'

export interface Consent {
  id: string
  dataCategory: string
  department: string
  purpose: string
  status: ConsentStatus
  grantedOn: string
  validUntil: string
  citizenMasterId?: string
}

export interface PendingConsentRequest {
  id: string
  department: string
  purpose: string
  dataRequested: string[]
  requestedOn: string
  eligible: boolean
  eligibilityReasons: string[]
}
