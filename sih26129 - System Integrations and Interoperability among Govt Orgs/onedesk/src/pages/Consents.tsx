import { Building2, Check, ShieldCheck, X } from 'lucide-react'
import { useState } from 'react'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/Button'
import { Card, CardContent } from '@/components/ui/Card'
import { Modal } from '@/components/ui/Modal'
import { useToast } from '@/components/ui/Toast'
import { useConsents } from '@/context/ConsentsContext'
import { formatDate } from '@/lib/utils'

export default function Consents() {
  const { consents, pendingRequests, allowRequest, denyRequest, revokeConsent } = useConsents()
  const { showToast } = useToast()
  const [activeRequestId, setActiveRequestId] = useState<string | null>(null)

  const activeRequest = pendingRequests.find((r) => r.id === activeRequestId) ?? null

  const handleAllow = () => {
    if (!activeRequest) return
    allowRequest(activeRequest.id)
    showToast(
      'Consent granted successfully',
      `${activeRequest.department} can now access ${activeRequest.dataRequested.join(', ')} for the selected purpose.`,
    )
    setActiveRequestId(null)
  }

  const handleDeny = () => {
    if (!activeRequest) return
    denyRequest(activeRequest.id)
    showToast('Consent request denied', `${activeRequest.department} was not granted access.`)
    setActiveRequestId(null)
  }

  return (
    <div>
      <PageHeader title="My Consents" subtitle="Review and manage which departments can access your data, and for what purpose." />

      {pendingRequests.length > 0 && (
        <div className="mb-6 space-y-3">
          {pendingRequests.map((req) => (
            <Card key={req.id} className="border-consent-600/30 bg-consent-50/40">
              <CardContent className="flex flex-wrap items-center justify-between gap-3 pt-5">
                <div className="flex items-start gap-3">
                  <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0 text-consent-600" />
                  <div>
                    <p className="text-sm font-semibold text-gray-900">
                      {req.department} requested access to {req.dataRequested.join(' & ')}
                    </p>
                    <p className="mt-0.5 text-xs text-gray-500">Purpose: {req.purpose}</p>
                  </div>
                </div>
                <Button size="sm" onClick={() => setActiveRequestId(req.id)}>
                  Manage Consent
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {consents.map((c) => (
          <Card key={c.id} className="p-5">
            <div className="mb-2 flex items-start justify-between gap-2">
              <p className="text-sm font-semibold text-gray-900">{c.dataCategory}</p>
              <StatusBadge status={c.status} />
            </div>
            <p className="flex items-center gap-1.5 text-xs text-gray-500">
              <Building2 className="h-3.5 w-3.5" /> {c.department}
            </p>
            <p className="mt-3 text-xs text-gray-500">Purpose</p>
            <p className="text-sm text-gray-700">{c.purpose}</p>
            <div className="mt-4 flex items-center justify-between border-t border-gray-100 pt-3">
              <p className="text-xs text-gray-400">Valid until {formatDate(c.validUntil)}</p>
              {c.status === 'Active' && (
                <button
                  onClick={() => {
                    revokeConsent(c.id)
                    showToast('Consent revoked', `${c.department} no longer has access to ${c.dataCategory}.`)
                  }}
                  className="text-xs font-medium text-danger-600 hover:text-danger-700"
                >
                  Revoke
                </button>
              )}
            </div>
          </Card>
        ))}
      </div>

      <Modal
        open={!!activeRequest}
        onOpenChange={(open) => !open && setActiveRequestId(null)}
        title="Manage Consent"
        description="Review the data being requested before allowing access."
      >
        {activeRequest && (
          <div className="space-y-4">
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-gray-400">Data Requested</p>
              <ul className="mt-1.5 space-y-1">
                {activeRequest.dataRequested.map((d) => (
                  <li key={d} className="text-sm text-gray-700">
                    {d}
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-gray-400">Requesting Department</p>
              <p className="mt-1 text-sm text-gray-700">{activeRequest.department}</p>
            </div>
            <div>
              <p className="text-xs font-semibold uppercase tracking-wide text-gray-400">Purpose</p>
              <p className="mt-1 text-sm text-gray-700">{activeRequest.purpose}</p>
            </div>
            <div className="flex gap-3 pt-2">
              <Button onClick={handleAllow} className="flex-1">
                <Check className="h-4 w-4" /> Allow
              </Button>
              <Button onClick={handleDeny} variant="outline" className="flex-1">
                <X className="h-4 w-4" /> Deny
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  )
}
