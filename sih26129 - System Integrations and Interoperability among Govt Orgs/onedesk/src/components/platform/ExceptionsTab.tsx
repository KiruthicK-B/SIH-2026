import { AlertTriangle, CheckCircle2, RotateCcw } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/Button'
import { Card, CardContent } from '@/components/ui/Card'
import { useToast } from '@/components/ui/Toast'
import { useApplications } from '@/context/ApplicationsContext'
import { useRole } from '@/context/RoleContext'
import { api } from '@/lib/api'

export function ExceptionsTab() {
  const { t } = useTranslation()
  const { applications, refresh } = useApplications()
  const { isPlatformRole } = useRole()
  const { showToast } = useToast()
  const [retrying, setRetrying] = useState<string | null>(null)

  const blockedSteps = applications.flatMap((app) =>
    app.timeline
      .filter((step) => step.status === 'blocked')
      .map((step) => ({ appId: app.id, appService: app.service, step })),
  )

  const handleRetry = async (appId: string) => {
    setRetrying(appId)
    try {
      await api.post(`/applications/${appId}/retry`)
      showToast(t('exceptionsTab.retryTriggeredTitle'), t('exceptionsTab.retryTriggeredDescription'))
      await refresh()
    } finally {
      setRetrying(null)
    }
  }

  return (
    <div className="space-y-4">
      <p className="text-sm text-gray-500">{t('exceptionsTab.intro')}</p>

      {blockedSteps.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-2 py-10 text-center">
            <CheckCircle2 className="h-6 w-6 text-success-600" />
            <p className="text-sm font-medium text-gray-700">{t('exceptionsTab.noExceptionsTitle')}</p>
            <p className="text-xs text-gray-400">{t('exceptionsTab.noExceptionsSubtitle')}</p>
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
                    {step.note ?? t('exceptionsTab.defaultUnavailableNote', { department: step.department })}
                  </p>
                  {!isPlatformRole && (
                    <p className="mt-2 flex items-center gap-1.5 text-xs font-medium text-warning-700">
                      <RotateCcw className="h-3.5 w-3.5" /> {t('exceptionsTab.retryScheduledNote')}
                    </p>
                  )}
                  {isPlatformRole && (
                    <Button
                      size="sm"
                      variant="outline"
                      className="mt-3"
                      disabled={retrying === appId}
                      onClick={() => handleRetry(appId)}
                    >
                      <RotateCcw className="h-3.5 w-3.5" /> {t('exceptionsTab.retryNow')}
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
