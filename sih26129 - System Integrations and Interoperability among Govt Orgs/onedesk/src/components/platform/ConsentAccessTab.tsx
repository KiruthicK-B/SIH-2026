import { AlertTriangle, Check, ShieldCheck, X } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { StatCard } from '@/components/shared/StatCard'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { useToast } from '@/components/ui/Toast'
import { useConsents } from '@/context/ConsentsContext'
import { useRole } from '@/context/RoleContext'
import { ApiError } from '@/lib/api'
import { formatDate } from '@/lib/utils'

export function ConsentAccessTab() {
  const { t } = useTranslation()
  const { consents, pendingRequests, allowRequest, denyRequest, revokeConsent } = useConsents()
  const { isAdminOnly } = useRole()
  const { showToast } = useToast()

  // A platform admin acting here is a distinct, real action on a citizen's
  // consent (not the citizen's own choice) — kept separate from the officer's
  // read-only monitoring view, which sees the same ledger with no buttons.
  const handleAllow = async (id: string, department: string, dataRequested: string[]) => {
    try {
      await allowRequest(id)
      showToast(t('consents.grantedToastTitle'), t('consents.grantedToastDescription', { department, data: dataRequested.join(', ') }))
    } catch (err) {
      showToast(t('consents.grantFailedTitle'), err instanceof ApiError ? err.message : t('consents.genericError'))
    }
  }

  const handleDeny = (id: string, department: string) => {
    denyRequest(id)
    showToast(t('consents.deniedToastTitle'), t('consents.deniedToastDescription', { department }))
  }

  const handleRevoke = (id: string, department: string, dataCategory: string) => {
    revokeConsent(id)
    showToast(t('consents.revokedToastTitle'), t('consents.revokedToastDescription', { department, dataCategory }))
  }

  const active = consents.filter((c) => c.status === 'Active').length
  const revoked = consents.filter((c) => c.status === 'Revoked').length
  const expired = consents.filter((c) => c.status === 'Expired').length

  return (
    <div className="space-y-6">
      <p className="text-sm text-gray-500">{t('consentAccessTab.intro')}</p>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard icon={ShieldCheck} label={t('consentAccessTab.activeGrants')} value={active} tone="success" />
        <StatCard icon={ShieldCheck} label={t('consentAccessTab.revoked')} value={revoked} tone="warning" />
        <StatCard icon={ShieldCheck} label={t('consentAccessTab.expired')} value={expired} tone="brand" />
      </div>

      {pendingRequests.length > 0 && (
        <Card className="border-consent-600/30 bg-consent-50/40">
          <CardHeader>
            <CardTitle>{t('consentAccessTab.pendingRequestsTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {pendingRequests.map((req) => (
              <div key={req.id} className="rounded-md border border-consent-600/20 bg-white px-4 py-3">
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div>
                    <p className="text-sm font-semibold text-gray-900">
                      {t('consentAccessTab.requesting', { department: req.department, data: req.dataRequested.join(' & ') })}
                    </p>
                    <p className="mt-0.5 text-xs text-gray-500">
                      {t('consentAccessTab.purposeRequested', { purpose: req.purpose, date: formatDate(req.requestedOn) })}
                    </p>
                    {!req.eligible && (
                      <p className="mt-1.5 flex items-start gap-1 text-xs font-medium text-danger-600">
                        <AlertTriangle className="mt-0.5 h-3.5 w-3.5 shrink-0" />
                        {t('consentAccessTab.notEligible')} {req.eligibilityReasons.join('; ')}
                      </p>
                    )}
                  </div>
                  {isAdminOnly && (
                    <div className="flex shrink-0 gap-2">
                      <Button
                        size="sm"
                        variant="outline"
                        disabled={!req.eligible}
                        onClick={() => void handleAllow(req.id, req.department, req.dataRequested)}
                      >
                        <Check className="h-3.5 w-3.5" /> {t('consents.allow')}
                      </Button>
                      <Button size="sm" variant="outline" onClick={() => handleDeny(req.id, req.department)}>
                        <X className="h-3.5 w-3.5" /> {t('consents.deny')}
                      </Button>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle>{t('consentAccessTab.ledgerTitle')}</CardTitle>
        </CardHeader>
        <CardContent className="px-0 pb-0">
          <Table>
            <THead>
              <TR>
                <TH>{t('consentAccessTab.colCitizen')}</TH>
                <TH>{t('consentAccessTab.colDepartment')}</TH>
                <TH>{t('consentAccessTab.colDataCategory')}</TH>
                <TH>{t('consentAccessTab.colPurpose')}</TH>
                <TH>{t('consentAccessTab.colStatus')}</TH>
                <TH>{t('consentAccessTab.colValidUntil')}</TH>
                {isAdminOnly && <TH></TH>}
              </TR>
            </THead>
            <TBody>
              {consents.map((c) => (
                <TR key={c.id}>
                  <TD className="font-mono text-xs text-gray-500">{c.citizenMasterId ?? '—'}</TD>
                  <TD>{c.department}</TD>
                  <TD>{c.dataCategory}</TD>
                  <TD className="text-gray-500">{c.purpose}</TD>
                  <TD>
                    <StatusBadge status={c.status} />
                  </TD>
                  <TD className="text-gray-500">{formatDate(c.validUntil)}</TD>
                  {isAdminOnly && (
                    <TD>
                      {c.status === 'Active' && (
                        <button
                          onClick={() => handleRevoke(c.id, c.department, c.dataCategory)}
                          className="text-xs font-medium text-danger-600 hover:text-danger-700"
                        >
                          {t('consents.revoke')}
                        </button>
                      )}
                    </TD>
                  )}
                </TR>
              ))}
            </TBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
