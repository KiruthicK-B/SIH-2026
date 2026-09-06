import { ArrowRight, Building2, FileText, UserCheck } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import { PageHeader } from '@/components/shared/PageHeader'
import { Button } from '@/components/ui/Button'
import { Card, CardContent } from '@/components/ui/Card'
import { useToast } from '@/components/ui/Toast'
import type { Application } from '@/data/applications'
import { useApplications } from '@/context/ApplicationsContext'
import { useNotifications } from '@/context/NotificationsContext'
import { useRole } from '@/context/RoleContext'
import { api } from '@/lib/api'

export default function OfficerDashboard() {
  const { t } = useTranslation()
  const { role, department } = useRole()
  const roleLabel = t(`roles.${role}`, { defaultValue: role })
  const { advanceApplication, approveMunicipalReview } = useApplications()
  const { refresh: refreshNotifications } = useNotifications()
  const { showToast } = useToast()
  const [assigned, setAssigned] = useState<Application[]>([])
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState<string | null>(null)

  const load = () => {
    setLoading(true)
    api
      .get<Application[]>('/applications/assigned')
      .then(setAssigned)
      .finally(() => setLoading(false))
  }

  useEffect(load, [])

  const handleAction = async (app: Application, step: NonNullable<Application['timeline'][number]>) => {
    setBusy(app.id)
    try {
      const event =
        step.department === 'Municipal Corporation' ? await approveMunicipalReview(app.id) : await advanceApplication(app.id)
      if (event) {
        showToast(event.title, event.description)
        void refreshNotifications()
      }
      load()
    } catch {
      showToast(t('officerDashboard.actionFailedTitle'), t('officerDashboard.actionFailedDescription'))
    } finally {
      setBusy(null)
    }
  }

  return (
    <div>
      <PageHeader
        title={t('officerDashboard.title')}
        subtitle={
          department
            ? t('officerDashboard.subtitleDepartment', { department })
            : t('officerDashboard.subtitleAll')
        }
      />

      {loading && <p className="text-sm text-gray-400">{t('officerDashboard.loading')}</p>}

      {!loading && assigned.length === 0 && (
        <Card>
          <CardContent className="flex flex-col items-center justify-center gap-2 py-12 text-center">
            <UserCheck className="h-8 w-8 text-gray-300" />
            <p className="text-sm font-medium text-gray-900">{t('officerDashboard.emptyTitle')}</p>
            <p className="text-xs text-gray-400">
              {t('officerDashboard.signedInAs', { role: roleLabel })}
              {department ? ` — ${department}` : ''}.
            </p>
          </CardContent>
        </Card>
      )}

      <div className="space-y-3">
        {assigned.map((app) => {
          const step = app.timeline.find((s) => s.status === 'active')
          if (!step) return null
          return (
            <Card key={app.id}>
              <CardContent className="flex flex-wrap items-center justify-between gap-4 pt-5">
                <div>
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-semibold text-gray-900">{app.service}</p>
                    {app.flagship && (
                      <span className="rounded-full bg-brand-50 px-2 py-0.5 text-[10px] font-semibold text-brand-700">FLAGSHIP</span>
                    )}
                  </div>
                  <p className="mt-0.5 flex items-center gap-1.5 text-xs text-gray-500">
                    <FileText className="h-3 w-3" /> {app.id} · {app.citizenName}
                  </p>
                  <p className="mt-1 flex items-center gap-1.5 text-xs text-gray-500">
                    <Building2 className="h-3 w-3" /> {t('officerDashboard.waitingStep')}{' '}
                    <span className="font-medium text-gray-700">{step.label}</span>
                    {step.systemType && <span className="text-gray-400">({step.systemType})</span>}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <Link to={`/applications/${app.id}`} className="text-xs font-medium text-gray-500 hover:text-gray-700">
                    {t('officerDashboard.viewDetails')}
                  </Link>
                  <Button size="sm" disabled={busy === app.id} onClick={() => handleAction(app, step)}>
                    {step.department === 'Municipal Corporation' ? t('officerDashboard.approve') : t('officerDashboard.process')}{' '}
                    <ArrowRight className="h-3.5 w-3.5" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          )
        })}
      </div>
    </div>
  )
}
