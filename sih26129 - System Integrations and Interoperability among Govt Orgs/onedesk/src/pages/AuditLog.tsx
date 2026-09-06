import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent } from '@/components/ui/Card'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { type AuditLogEntry, auditResults } from '@/data/auditLogs'
import { api } from '@/lib/api'
import { formatDateTime } from '@/lib/utils'

export default function AuditLog() {
  const { t } = useTranslation()
  const [department, setDepartment] = useState('all')
  const [action, setAction] = useState('all')
  const [result, setResult] = useState('all')
  const [date, setDate] = useState('')

  const [departments, setDepartments] = useState<string[]>([])
  const [actions, setActions] = useState<string[]>([])
  const [logs, setLogs] = useState<AuditLogEntry[]>([])

  useEffect(() => {
    Promise.all([api.get<string[]>('/audit/departments'), api.get<string[]>('/audit/actions')]).then(([d, a]) => {
      setDepartments(d)
      setActions(a)
    })
  }, [])

  useEffect(() => {
    const params = new URLSearchParams()
    if (department !== 'all') params.set('department', department)
    if (action !== 'all') params.set('action', action)
    if (result !== 'all') params.set('result', result)
    if (date) params.set('date', date)
    const qs = params.toString()
    api.get<AuditLogEntry[]>(`/audit${qs ? `?${qs}` : ''}`).then(setLogs)
  }, [department, action, result, date])

  return (
    <div>
      <PageHeader title={t('auditLog.title')} subtitle={t('auditLog.subtitle')} />

      <Card>
        <div className="flex flex-wrap items-center gap-3 border-b border-gray-100 p-4">
          <Select
            value={department}
            onValueChange={setDepartment}
            className="w-52"
            options={[{ value: 'all', label: t('auditLog.allDepartments') }, ...departments.map((d) => ({ value: d, label: d }))]}
          />
          <Select
            value={action}
            onValueChange={setAction}
            className="w-44"
            options={[{ value: 'all', label: t('auditLog.allActions') }, ...actions.map((a) => ({ value: a, label: a }))]}
          />
          <Select
            value={result}
            onValueChange={setResult}
            className="w-40"
            options={[{ value: 'all', label: t('auditLog.allResults') }, ...auditResults.map((r) => ({ value: r, label: t(`status.${r}`, { defaultValue: r }) }))]}
          />
          <Input type="date" value={date} onChange={(e) => setDate(e.target.value)} className="w-40" />
        </div>
        <CardContent className="px-0 pb-0">
          <Table>
            <THead>
              <TR>
                <TH>{t('auditLog.colTimestamp')}</TH>
                <TH>{t('auditLog.colActor')}</TH>
                <TH>{t('auditLog.colDepartment')}</TH>
                <TH>{t('auditLog.colAction')}</TH>
                <TH>{t('auditLog.colResource')}</TH>
                <TH>{t('auditLog.colResult')}</TH>
              </TR>
            </THead>
            <TBody>
              {logs.map((log) => (
                <TR key={log.id}>
                  <TD className="text-gray-500">{formatDateTime(log.timestamp)}</TD>
                  <TD className="font-medium text-gray-900">{log.actor}</TD>
                  <TD>{log.department}</TD>
                  <TD className="font-mono text-xs">{log.action}</TD>
                  <TD>{log.resource}</TD>
                  <TD>
                    <StatusBadge status={log.result} />
                  </TD>
                </TR>
              ))}
              {logs.length === 0 && (
                <TR>
                  <TD colSpan={6} className="py-10 text-center text-sm text-gray-400">
                    {t('auditLog.noMatches')}
                  </TD>
                </TR>
              )}
            </TBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
