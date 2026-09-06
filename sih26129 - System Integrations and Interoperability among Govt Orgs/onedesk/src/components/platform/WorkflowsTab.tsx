import { Workflow } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { useApplications } from '@/context/ApplicationsContext'
import { formatDate } from '@/lib/utils'

const badgeForStatus = {
  done: 'Completed',
  active: 'In Progress',
  blocked: 'Failed',
  pending: 'Under Review',
} as const

export function WorkflowsTab() {
  const { t } = useTranslation()
  const { applications } = useApplications()
  const flagship = applications.find((a) => a.flagship)

  const eventForStatus = {
    done: t('workflowsTab.eventCompleted'),
    active: t('workflowsTab.eventInProgress'),
    blocked: t('workflowsTab.eventRetryScheduled'),
    pending: t('workflowsTab.eventQueued'),
  } as const

  if (!flagship) {
    return <p className="text-sm text-gray-400">{t('workflowsTab.noActiveWorkflow')}</p>
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start gap-3 rounded-md border border-brand-500/20 bg-brand-50 px-4 py-3">
        <Workflow className="mt-0.5 h-4 w-4 shrink-0 text-brand-600" />
        <p className="text-sm text-brand-700">
          {t('workflowsTab.orchestrationIntro', { service: flagship.service, id: flagship.id })}
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>{t('workflowsTab.orchestratedStepsTitle', { service: flagship.service })}</CardTitle>
        </CardHeader>
        <CardContent className="px-0 pb-0">
          <Table>
            <THead>
              <TR>
                <TH>{t('workflowsTab.colStep')}</TH>
                <TH>{t('workflowsTab.colDepartment')}</TH>
                <TH>{t('workflowsTab.colSystem')}</TH>
                <TH>{t('workflowsTab.colStatus')}</TH>
                <TH>{t('workflowsTab.colTimestamp')}</TH>
                <TH>{t('workflowsTab.colEvent')}</TH>
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
