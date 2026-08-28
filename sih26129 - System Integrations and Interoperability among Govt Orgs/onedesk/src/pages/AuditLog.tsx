import { useMemo, useState } from 'react'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent } from '@/components/ui/Card'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { auditActions, auditDepartments, auditLogs, auditResults } from '@/data/auditLogs'
import { formatDateTime } from '@/lib/utils'

export default function AuditLog() {
  const [department, setDepartment] = useState('all')
  const [action, setAction] = useState('all')
  const [result, setResult] = useState('all')
  const [date, setDate] = useState('')

  const filtered = useMemo(() => {
    return auditLogs.filter((log) => {
      const matchesDept = department === 'all' || log.department === department
      const matchesAction = action === 'all' || log.action === action
      const matchesResult = result === 'all' || log.result === result
      const matchesDate = !date || log.timestamp.startsWith(date)
      return matchesDept && matchesAction && matchesResult && matchesDate
    })
  }, [department, action, result, date])

  return (
    <div>
      <PageHeader title="Audit & Compliance" subtitle="Immutable log of every data access and consent event across the platform." />

      <Card>
        <div className="flex flex-wrap items-center gap-3 border-b border-gray-100 p-4">
          <Select
            value={department}
            onValueChange={setDepartment}
            className="w-52"
            options={[{ value: 'all', label: 'All departments' }, ...auditDepartments.map((d) => ({ value: d, label: d }))]}
          />
          <Select
            value={action}
            onValueChange={setAction}
            className="w-44"
            options={[{ value: 'all', label: 'All actions' }, ...auditActions.map((a) => ({ value: a, label: a }))]}
          />
          <Select
            value={result}
            onValueChange={setResult}
            className="w-40"
            options={[{ value: 'all', label: 'All results' }, ...auditResults.map((r) => ({ value: r, label: r }))]}
          />
          <Input type="date" value={date} onChange={(e) => setDate(e.target.value)} className="w-40" />
        </div>
        <CardContent className="px-0 pb-0">
          <Table>
            <THead>
              <TR>
                <TH>Timestamp</TH>
                <TH>Actor</TH>
                <TH>Department</TH>
                <TH>Action</TH>
                <TH>Resource</TH>
                <TH>Result</TH>
              </TR>
            </THead>
            <TBody>
              {filtered.map((log) => (
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
              {filtered.length === 0 && (
                <TR>
                  <TD colSpan={6} className="py-10 text-center text-sm text-gray-400">
                    No audit entries match your filters.
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
