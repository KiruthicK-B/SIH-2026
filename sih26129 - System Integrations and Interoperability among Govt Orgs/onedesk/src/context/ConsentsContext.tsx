import { createContext, type ReactNode, useContext, useState } from 'react'
import {
  type Consent,
  initialConsents,
  type PendingConsentRequest,
  pendingConsentRequests,
} from '@/data/consents'

interface ConsentsContextValue {
  consents: Consent[]
  pendingRequests: PendingConsentRequest[]
  allowRequest: (requestId: string) => void
  denyRequest: (requestId: string) => void
  revokeConsent: (consentId: string) => void
}

const ConsentsContext = createContext<ConsentsContextValue | null>(null)

export function ConsentsProvider({ children }: { children: ReactNode }) {
  const [consents, setConsents] = useState<Consent[]>(initialConsents)
  const [pendingRequests, setPendingRequests] = useState<PendingConsentRequest[]>(pendingConsentRequests)

  const allowRequest = (requestId: string) => {
    const request = pendingRequests.find((r) => r.id === requestId)
    if (!request) return
    const newConsent: Consent = {
      id: `con-${Date.now()}`,
      dataCategory: request.dataRequested.join(', '),
      department: request.department,
      purpose: request.purpose,
      status: 'Active',
      grantedOn: new Date().toISOString().slice(0, 10),
      validUntil: new Date(Date.now() + 1000 * 60 * 60 * 24 * 60).toISOString().slice(0, 10),
    }
    setConsents((prev) => [newConsent, ...prev])
    setPendingRequests((prev) => prev.filter((r) => r.id !== requestId))
  }

  const denyRequest = (requestId: string) => {
    setPendingRequests((prev) => prev.filter((r) => r.id !== requestId))
  }

  const revokeConsent = (consentId: string) => {
    setConsents((prev) => prev.map((c) => (c.id === consentId ? { ...c, status: 'Revoked' } : c)))
  }

  return (
    <ConsentsContext.Provider value={{ consents, pendingRequests, allowRequest, denyRequest, revokeConsent }}>
      {children}
    </ConsentsContext.Provider>
  )
}

export function useConsents() {
  const ctx = useContext(ConsentsContext)
  if (!ctx) throw new Error('useConsents must be used within ConsentsProvider')
  return ctx
}
