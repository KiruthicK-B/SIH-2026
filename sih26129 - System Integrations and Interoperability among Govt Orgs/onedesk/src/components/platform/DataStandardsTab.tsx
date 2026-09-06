import { ArrowRight, CheckCircle2 } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { useIdentity } from '@/context/IdentityContext'
import { type FieldMapping } from '@/data/dataStandards'
import { SchemaMappingSuggestions } from './SchemaMappingSuggestions'

function legacyDate(iso: string) {
  const [y, m, d] = iso.split('-')
  return `${d}/${m}/${y}`
}

export function DataStandardsTab() {
  const { t } = useTranslation()
  const { identity } = useIdentity()
  const transformationChecks = [
    t('dataStandardsTab.checkSchemaValidated'),
    t('dataStandardsTab.checkFieldsMapped'),
    t('dataStandardsTab.checkIdentifierResolved'),
  ]

  // Illustrates the mapping engine's field-level transform using this account's own
  // real identity record — not a fabricated example record.
  const transformationExample: FieldMapping[] = identity
    ? [
        { sourceField: 'full_name', sourceValue: identity.citizenName, commonField: 'name', commonValue: identity.citizenName },
        {
          sourceField: 'dob',
          sourceValue: identity.dateOfBirth ? legacyDate(identity.dateOfBirth) : '—',
          commonField: 'dateOfBirth',
          commonValue: identity.dateOfBirth ?? '—',
        },
        { sourceField: 'citizen_identifier', sourceValue: identity.masterId, commonField: 'citizenId', commonValue: identity.masterId },
      ]
    : []

  return (
    <div className="space-y-6">
      <SchemaMappingSuggestions />

      <Card>
        <CardHeader>
          <CardTitle>{t('dataStandardsTab.transformationTitle')}</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="mb-4 text-sm text-gray-500">{t('dataStandardsTab.transformationIntro')}</p>
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-[1fr_auto_1fr] lg:items-center">
            <div className="rounded-md border border-gray-200 p-4">
              <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-400">{t('dataStandardsTab.sourceSystemLabel')}</p>
              <div className="space-y-2 font-mono text-xs text-gray-600">
                {transformationExample.map((f) => (
                  <p key={f.sourceField}>
                    {f.sourceField}: <span className="text-gray-900">{f.sourceValue}</span>
                  </p>
                ))}
              </div>
            </div>

            <ArrowRight className="mx-auto hidden h-5 w-5 text-gray-300 lg:block" />

            <div className="rounded-md border border-brand-500/20 bg-brand-50/40 p-4">
              <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-brand-700">{t('dataStandardsTab.commonModelLabel')}</p>
              <div className="space-y-2 font-mono text-xs text-gray-700">
                {transformationExample.map((f) => (
                  <p key={f.commonField}>
                    {f.commonField}: <span className="text-gray-900">{f.commonValue}</span>
                  </p>
                ))}
              </div>
            </div>
          </div>

          <div className="mt-4 flex flex-wrap gap-4">
            {transformationChecks.map((check) => (
              <span key={check} className="flex items-center gap-1.5 text-xs font-medium text-success-600">
                <CheckCircle2 className="h-3.5 w-3.5" /> {check}
              </span>
            ))}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>{t('dataStandardsTab.masterDataTitle')}</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="mb-4 text-sm text-gray-500">
            {t('dataStandardsTab.identifiersResolved', { count: identity?.departmentIdentifiers.length ?? 0 })}
          </p>
          <div className="flex flex-col items-center gap-4 lg:flex-row lg:justify-center">
            <div className="grid grid-cols-2 gap-2 lg:grid-cols-1">
              {identity?.departmentIdentifiers.map((d) => (
                <div key={d.department} className="rounded-md border border-gray-200 px-3 py-2 text-xs">
                  <p className="text-gray-400">{d.department}</p>
                  <p className="font-mono font-medium text-gray-800">{d.identifier}</p>
                </div>
              ))}
            </div>
            <ArrowRight className="h-5 w-5 rotate-90 text-gray-300 lg:rotate-0" />
            <div className="rounded-md border border-consent-600/30 bg-consent-50 px-5 py-4 text-center">
              <p className="text-xs font-semibold uppercase tracking-wide text-consent-700">{t('dataStandardsTab.masterCitizenRecord')}</p>
              <p className="mt-1 font-mono text-lg font-semibold text-consent-700">{identity?.masterId ?? '—'}</p>
              <p className="mt-0.5 text-xs text-consent-700/80">{identity?.citizenName ?? ''}</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
