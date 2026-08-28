import { Search } from 'lucide-react'
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent } from '@/components/ui/Card'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { useApplications } from '@/context/ApplicationsContext'
import type { ApplicationStatus } from '@/data/applications'
import { formatDate } from '@/lib/utils'

const statusOptions: { value: ApplicationStatus | 'all'; label: string }[] = [
  { value: 'all', label: 'All statuses' },
  { value: 'In Progress', label: 'In Progress' },
  { value: 'Under Review', label: 'Under Review' },
  { value: 'Approved', label: 'Approved' },
  { value: 'Completed', label: 'Completed' },
  { value: 'Rejected', label: 'Rejected' },
]

export default function Applications() {
  const { applications } = useApplications()
  const [query, setQuery] = useState('')
  const [status, setStatus] = useState<string>('all')

  const filtered = useMemo(() => {
    return applications.filter((a) => {
      const matchesStatus = status === 'all' || a.status === status
      const q = query.trim().toLowerCase()
      const matchesQuery =
        !q || a.id.toLowerCase().includes(q) || a.service.toLowerCase().includes(q) || a.department.toLowerCase().includes(q)
      return matchesStatus && matchesQuery
    })
  }, [query, status, applications])

  return (
    <div>
      <PageHeader title="My Applications" subtitle="Track every application you've submitted across connected departments." />

      <Card>
        <div className="flex flex-col gap-3 border-b border-gray-100 p-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="relative w-full max-w-xs">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search by ID, service, department…"
              className="pl-9"
            />
          </div>
          <Select value={status} onValueChange={setStatus} options={statusOptions} className="w-48" />
        </div>
        <CardContent className="px-0 pb-0">
          <Table>
            <THead>
              <TR>
                <TH>Application ID</TH>
                <TH>Service</TH>
                <TH>Department</TH>
                <TH>Status</TH>
                <TH>Last Updated</TH>
                <TH>Action</TH>
              </TR>
            </THead>
            <TBody>
              {filtered.map((app) => (
                <TR key={app.id}>
                  <TD className="font-medium text-gray-900">{app.id}</TD>
                  <TD>{app.service}</TD>
                  <TD>{app.department}</TD>
                  <TD>
                    <StatusBadge status={app.status} />
                  </TD>
                  <TD className="text-gray-500">{formatDate(app.lastUpdated)}</TD>
                  <TD>
                    <Link to={`/applications/${app.id}`} className="text-sm font-medium text-brand-600 hover:text-brand-700">
                      View details
                    </Link>
                  </TD>
                </TR>
              ))}
              {filtered.length === 0 && (
                <TR>
                  <TD colSpan={6} className="py-10 text-center text-sm text-gray-400">
                    No applications match your filters.
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
