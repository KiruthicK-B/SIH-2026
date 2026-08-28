import { ShieldCheck } from 'lucide-react'
import { StatCard } from '@/components/shared/StatCard'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { useConsents } from '@/context/ConsentsContext'
import { masterIdentity } from '@/data/identity'
import { formatDate } from '@/lib/utils'

export function ConsentAccessTab() {
  const { consents, pendingRequests } = useConsents()

  const active = consents.filter((c) => c.status === 'Active').length
  const revoked = consents.filter((c) => c.status === 'Revoked').length
  const expired = consents.filter((c) => c.status === 'Expired').length

  return (
    <div className="space-y-6">
      <p className="text-sm text-gray-500">
        Every cross-department data access is gated by a consent record — purpose-bound, time-limited, and
        revocable by the citizen at any time. This view is the platform-wide ledger of that access.
      </p>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard icon={ShieldCheck} label="Active Grants" value={active} tone="success" />
        <StatCard icon={ShieldCheck} label="Revoked" value={revoked} tone="warning" />
        <StatCard icon={ShieldCheck} label="Expired" value={expired} tone="brand" />
      </div>

      {pendingRequests.length > 0 && (
        <Card className="border-consent-600/30 bg-consent-50/40">
          <CardHeader>
            <CardTitle>Pending Consent Requests</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {pendingRequests.map((req) => (
              <div key={req.id} className="rounded-md border border-consent-600/20 bg-white px-4 py-3">
                <p className="text-sm font-semibold text-gray-900">
                  {req.department} requesting {req.dataRequested.join(' & ')}
                </p>
                <p className="mt-0.5 text-xs text-gray-500">
                  Purpose: {req.purpose} · Requested {formatDate(req.requestedOn)}
                </p>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Consent Ledger</CardTitle>
        </CardHeader>
        <CardContent className="px-0 pb-0">
          <Table>
            <THead>
              <TR>
                <TH>Citizen</TH>
                <TH>Department</TH>
                <TH>Data Category</TH>
                <TH>Purpose</TH>
                <TH>Status</TH>
                <TH>Valid Until</TH>
              </TR>
            </THead>
            <TBody>
              {consents.map((c) => (
                <TR key={c.id}>
                  <TD className="font-mono text-xs text-gray-500">{masterIdentity.masterId}</TD>
                  <TD>{c.department}</TD>
                  <TD>{c.dataCategory}</TD>
                  <TD className="text-gray-500">{c.purpose}</TD>
                  <TD>
                    <StatusBadge status={c.status} />
                  </TD>
                  <TD className="text-gray-500">{formatDate(c.validUntil)}</TD>
                </TR>
              ))}
            </TBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
