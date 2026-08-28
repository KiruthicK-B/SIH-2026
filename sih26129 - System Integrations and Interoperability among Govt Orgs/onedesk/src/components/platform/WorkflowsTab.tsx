import { Workflow } from 'lucide-react'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { useApplications } from '@/context/ApplicationsContext'
import { formatDate } from '@/lib/utils'

const eventForStatus = {
  done: 'Completed',
  active: 'In progress',
  blocked: 'Retry scheduled',
  pending: 'Queued',
} as const

const badgeForStatus = {
  done: 'Completed',
  active: 'In Progress',
  blocked: 'Failed',
  pending: 'Under Review',
} as const

export function WorkflowsTab() {
  const { applications } = useApplications()
  const flagship = applications.find((a) => a.flagship)

  if (!flagship) {
    return <p className="text-sm text-gray-400">No active cross-department workflow right now.</p>
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start gap-3 rounded-md border border-brand-500/20 bg-brand-50 px-4 py-3">
        <Workflow className="mt-0.5 h-4 w-4 shrink-0 text-brand-600" />
        <p className="text-sm text-brand-700">
          The platform orchestrates every step of <span className="font-semibold">{flagship.service}</span> (
          {flagship.id}) across departments — each step below runs independently, in order, with its own system
          and retry policy.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>{flagship.service} — Orchestrated Steps</CardTitle>
        </CardHeader>
        <CardContent className="px-0 pb-0">
          <Table>
            <THead>
              <TR>
                <TH>Step</TH>
                <TH>Department</TH>
                <TH>System</TH>
                <TH>Status</TH>
                <TH>Timestamp</TH>
                <TH>Event</TH>
              </TR>
            </THead>
            <TBody>
              {flagship.timeline.map((step, idx) => (
                <TR key={step.label}>
                  <TD className="font-medium text-gray-900">
                    {idx + 1}. {step.label}
                  </TD>
                  <TD>{step.department}</TD>
                  <TD className="text-gray-500">{step.systemType ?? '—'}</TD>
                  <TD>
                    <StatusBadge status={badgeForStatus[step.status]} />
                  </TD>
                  <TD className="text-gray-500">{step.date ? formatDate(step.date) : '—'}</TD>
                  <TD className="font-mono text-xs text-gray-500">{eventForStatus[step.status]}</TD>
                </TR>
              ))}
            </TBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
