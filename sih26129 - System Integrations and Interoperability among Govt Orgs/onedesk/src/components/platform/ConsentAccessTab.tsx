import { AlertTriangle, ShieldCheck } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { StatCard } from '@/components/shared/StatCard'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { useConsents } from '@/context/ConsentsContext'
import { formatDate } from '@/lib/utils'

export function ConsentAccessTab() {
  const { t } = useTranslation()
  const { consents, pendingRequests } = useConsents()

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
                </TR>
              ))}
            </TBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
