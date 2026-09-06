import { Check, Plus, Sparkles, Trash2, X } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Input } from '@/components/ui/Input'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { useToast } from '@/components/ui/Toast'
import { useIdentity } from '@/context/IdentityContext'
import { useRole } from '@/context/RoleContext'
import { api, mdmApi } from '@/lib/api'

interface SampleField {
  field: string
  sampleValue: string
}

interface MappingSuggestion {
  sourceField: string
  sourceSystem: string
  suggestedTarget: string | null
  confidence: number
  rationale: string
}

const DEFAULT_SOURCE_SYSTEM = 'Food & Civil Supplies — Legacy DB'

type SuggestionStatus = 'pending' | 'approved' | 'rejected'

// The PPT's own architecture diagram draws a "RAG lookup" from the workflow engine
// into the policy/schema layer — this is that arrow, made real. Onboarding a new
// department connector normally means someone manually writing field mappings; this
// suggests them instead, with a confidence score and an editable approval step.
export function SchemaMappingSuggestions() {
  const { t } = useTranslation()
  const { role } = useRole()
  const { showToast } = useToast()
  const { identity } = useIdentity()
  const [sourceSystem, setSourceSystem] = useState(DEFAULT_SOURCE_SYSTEM)
  const [fields, setFields] = useState<SampleField[]>([])
  const [suggestions, setSuggestions] = useState<MappingSuggestion[]>([])
  const [statuses, setStatuses] = useState<Record<string, SuggestionStatus>>({})
  const [loading, setLoading] = useState(false)

  // Sample record for the onboarding demo — this account's own real identity fields,
  // not a fabricated citizen. addr_line1/ration_card_type stay generic since this
  // department connector doesn't exist in the platform's identity data yet.
  useEffect(() => {
    if (!identity || fields.length > 0) return
    setFields([
      { field: 'full_name', sampleValue: identity.citizenName },
      { field: 'dob', sampleValue: identity.dateOfBirth ?? '' },
      { field: 'citizen_identifier', sampleValue: identity.masterId },
      { field: 'addr_line1', sampleValue: identity.address ?? '' },
      { field: 'ration_card_type', sampleValue: 'APL' },
    ])
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [identity])

  const isAdmin = role === 'Platform Administrator'
  if (!isAdmin) return null

  const updateField = (idx: number, key: keyof SampleField, value: string) => {
    setFields((prev) => prev.map((f, i) => (i === idx ? { ...f, [key]: value } : f)))
  }
  const addField = () => setFields((prev) => [...prev, { field: '', sampleValue: '' }])
  const removeField = (idx: number) => setFields((prev) => prev.filter((_, i) => i !== idx))

  const runSuggest = async () => {
    setLoading(true)
    try {
      const results = await mdmApi.post<MappingSuggestion[]>('/suggest-mapping', {
        sourceSystem,
        fields: fields.filter((f) => f.field.trim()),
      })
      setSuggestions(results)
      setStatuses({})
    } finally {
      setLoading(false)
    }
  }

  const approve = async (s: MappingSuggestion) => {
    if (!s.suggestedTarget) return
    await api.post('/schema/field-mappings', {
      sourceField: s.sourceField,
      sourceSystem: s.sourceSystem,
      targetField: s.suggestedTarget,
      confidence: s.confidence,
      rationale: s.rationale,
    })
    setStatuses((prev) => ({ ...prev, [s.sourceField]: 'approved' }))
    showToast(t('schemaMappingSuggestions.mappingApprovedTitle'), t('schemaMappingSuggestions.mappingApprovedDescription', { source: s.sourceField, target: s.suggestedTarget }))
  }

  const reject = (s: MappingSuggestion) => {
    setStatuses((prev) => ({ ...prev, [s.sourceField]: 'rejected' }))
  }

  return (
    <Card className="border-brand-500/20 bg-brand-50/20">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Sparkles className="h-4 w-4 text-brand-600" /> {t('schemaMappingSuggestions.title')}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-sm text-gray-500">{t('schemaMappingSuggestions.intro')}</p>

        <div>
          <label className="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-400">
            {t('schemaMappingSuggestions.sourceSystemLabel')}
          </label>
          <Input value={sourceSystem} onChange={(e) => setSourceSystem(e.target.value)} className="max-w-md" />
        </div>

        <div className="space-y-2">
          <label className="block text-xs font-semibold uppercase tracking-wide text-gray-400">
            {t('schemaMappingSuggestions.sampleFieldsLabel')}
          </label>
          {fields.map((f, idx) => (
            <div key={idx} className="flex items-center gap-2">
              <Input
                placeholder={t('schemaMappingSuggestions.fieldNamePlaceholder')}
                value={f.field}
                onChange={(e) => updateField(idx, 'field', e.target.value)}
                className="w-56 font-mono text-xs"
              />
              <Input
                placeholder={t('schemaMappingSuggestions.sampleValuePlaceholder')}
                value={f.sampleValue}
                onChange={(e) => updateField(idx, 'sampleValue', e.target.value)}
                className="flex-1"
              />
              <button onClick={() => removeField(idx)} className="text-gray-300 hover:text-danger-600">
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          ))}
          <Button variant="outline" size="sm" onClick={addField}>
            <Plus className="h-3.5 w-3.5" /> {t('schemaMappingSuggestions.addField')}
          </Button>
        </div>

        <Button onClick={runSuggest} disabled={loading}>
          <Sparkles className="h-4 w-4" /> {loading ? t('schemaMappingSuggestions.suggesting') : t('schemaMappingSuggestions.suggestMappings')}
        </Button>

        {suggestions.length > 0 && (
          <Table>
            <THead>
              <TR>
                <TH>{t('schemaMappingSuggestions.colSourceField')}</TH>
                <TH>{t('schemaMappingSuggestions.colSuggestedField')}</TH>
                <TH>{t('schemaMappingSuggestions.colConfidence')}</TH>
                <TH>{t('schemaMappingSuggestions.colRationale')}</TH>
                <TH>{t('schemaMappingSuggestions.colAction')}</TH>
              </TR>
            </THead>
            <TBody>
              {suggestions.map((s) => {
                const status = statuses[s.sourceField] ?? 'pending'
                return (
                  <TR key={s.sourceField}>
                    <TD className="font-mono text-xs">{s.sourceField}</TD>
                    <TD className="font-mono text-xs">
                      {s.suggestedTarget ?? <span className="text-gray-400">{t('schemaMappingSuggestions.noConfidentMatch')}</span>}
                    </TD>
                    <TD>
                      <span
                        className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
                          s.confidence >= 0.8
                            ? 'bg-success-50 text-success-700'
                            : s.confidence >= 0.5
                              ? 'bg-warning-50 text-warning-700'
                              : 'bg-gray-100 text-gray-500'
                        }`}
                      >
                        {Math.round(s.confidence * 100)}%
                      </span>
                    </TD>
                    <TD className="max-w-xs text-xs text-gray-500">{s.rationale}</TD>
                    <TD>
                      {status === 'approved' && (
                        <span className="flex items-center gap-1 text-xs font-medium text-success-600">
                          <Check className="h-3.5 w-3.5" /> {t('schemaMappingSuggestions.approved')}
                        </span>
                      )}
                      {status === 'rejected' && (
                        <span className="flex items-center gap-1 text-xs font-medium text-gray-400">
                          <X className="h-3.5 w-3.5" /> {t('schemaMappingSuggestions.rejected')}
                        </span>
                      )}
                      {status === 'pending' && (
                        <div className="flex gap-1.5">
                          <Button size="sm" variant="outline" disabled={!s.suggestedTarget} onClick={() => approve(s)}>
                            {t('schemaMappingSuggestions.approve')}
                          </Button>
                          <Button size="sm" variant="outline" onClick={() => reject(s)}>
                            {t('schemaMappingSuggestions.reject')}
                          </Button>
                        </div>
                      )}
                    </TD>
                  </TR>
                )
              })}
            </TBody>
          </Table>
        )}
      </CardContent>
    </Card>
  )
}
