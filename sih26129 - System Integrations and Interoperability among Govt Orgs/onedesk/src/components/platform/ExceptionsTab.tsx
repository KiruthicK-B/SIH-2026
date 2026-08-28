import { AlertTriangle, CheckCircle2, RotateCcw } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/Card'
import { useApplications } from '@/context/ApplicationsContext'

export function ExceptionsTab() {
  const { applications } = useApplications()

  const blockedSteps = applications.flatMap((app) =>
    app.timeline
      .filter((step) => step.status === 'blocked')
      .map((step) => ({ appId: app.id, appService: app.service, step })),
  )

  return (
    <div className="space-y-4">
      <p className="text-sm text-gray-500">
        Not every department system is available every second. When one is unreachable mid-workflow, the
        platform holds that step, keeps the rest of the application moving, and retries automatically instead
        of failing the whole request.
      </p>

      {blockedSteps.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-2 py-10 text-center">
            <CheckCircle2 className="h-6 w-6 text-success-600" />
            <p className="text-sm font-medium text-gray-700">No active exceptions</p>
            <p className="text-xs text-gray-400">All connected systems are responding normally.</p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {blockedSteps.map(({ appId, appService, step }) => (
            <Card key={`${appId}-${step.label}`} className="border-warning-600/30 bg-warning-50/40">
              <CardContent className="flex items-start gap-3 pt-5">
                <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-warning-600" />
                <div className="flex-1">
                  <p className="text-sm font-semibold text-gray-900">
                    {step.department} — {step.label}
                  </p>
                  <p className="mt-0.5 text-xs text-gray-500">
                    {appService} ({appId}){step.systemType ? ` · ${step.systemType}` : ''}
                  </p>
                  <p className="mt-2 text-sm text-warning-700">
                    {step.note ?? `${step.department} system is temporarily unavailable.`}
                  </p>
                  <p className="mt-2 flex items-center gap-1.5 text-xs font-medium text-warning-700">
                    <RotateCcw className="h-3.5 w-3.5" /> Retry scheduled — other workflow steps continue normally
                  </p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
