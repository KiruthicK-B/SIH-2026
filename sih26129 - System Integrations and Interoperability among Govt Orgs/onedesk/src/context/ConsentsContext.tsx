import { createContext, type ReactNode, useContext, useEffect, useState } from 'react'
import { useAuth } from '@/context/AuthContext'
import type { Consent, PendingConsentRequest } from '@/data/consents'
import { api } from '@/lib/api'

interface ConsentsContextValue {
  consents: Consent[]
  pendingRequests: PendingConsentRequest[]
  allowRequest: (requestId: string) => Promise<void>
  denyRequest: (requestId: string) => Promise<void>
  revokeConsent: (consentId: string) => Promise<void>
}

const ConsentsContext = createContext<ConsentsContextValue | null>(null)

export function ConsentsProvider({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth()
  const [consents, setConsents] = useState<Consent[]>([])
  const [pendingRequests, setPendingRequests] = useState<PendingConsentRequest[]>([])

  const refresh = async () => {
    const [c, p] = await Promise.all([api.get<Consent[]>('/consents'), api.get<PendingConsentRequest[]>('/consents/pending')])
    setConsents(c)
    setPendingRequests(p)
  }

  useEffect(() => {
    if (!isAuthenticated) return
    refresh()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated])

  const allowRequest = async (requestId: string) => {
    await api.post(`/consents/pending/${requestId}/allow`)
    await refresh()
  }

  const denyRequest = async (requestId: string) => {
    await api.post(`/consents/pending/${requestId}/deny`)
    setPendingRequests((prev) => prev.filter((r) => r.id !== requestId))
  }

  const revokeConsent = async (consentId: string) => {
    await api.post(`/consents/${consentId}/revoke`)
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
