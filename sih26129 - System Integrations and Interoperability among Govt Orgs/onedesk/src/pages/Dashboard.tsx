import { ArrowRight, Bell, Briefcase, Building2, CheckCircle2, Clock, FileText, HandHeart, Home as HomeIcon, MessageSquareWarning, ShieldCheck } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import { StatCard } from '@/components/shared/StatCard'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { useApplications } from '@/context/ApplicationsContext'
import { useConsents } from '@/context/ConsentsContext'
import { useDepartments } from '@/context/DepartmentsContext'
import { useNotifications } from '@/context/NotificationsContext'
import { cn, formatDate, formatDateTime } from '@/lib/utils'

export default function Dashboard() {
  const { t } = useTranslation()
  const { consents } = useConsents()
  const { notifications } = useNotifications()
  const { applications } = useApplications()
  const { citizenFacingDepartments: departments } = useDepartments()

  const quickServices = [
    { label: t('dashboard.quickServiceBusinessLicense'), to: '/services/svc-business-license', icon: Briefcase },
    { label: t('dashboard.quickServicePropertyRegistration'), to: '/services/svc-property-services', icon: HomeIcon },
    { label: t('dashboard.quickServiceScholarship'), to: '/services/svc-scholarship', icon: FileText },
    { label: t('dashboard.quickServiceWelfareBenefits'), to: '/services/svc-welfare-schemes', icon: HandHeart },
    { label: t('dashboard.quickServiceGrievance'), to: '/grievances', icon: MessageSquareWarning },
  ]

  const total = applications.length
  const inProgress = applications.filter((a) => a.status === 'In Progress' || a.status === 'Under Review').length
  const completed = applications.filter((a) => a.status === 'Completed' || a.status === 'Approved').length
  const activeConsents = consents.filter((c) => c.status === 'Active').length

  const flagshipApp = applications.find((a) => a.flagship)
  const recentApplications = applications.filter((a) => !a.flagship).slice(0, 5)
  const recentNotifications = notifications.slice(0, 4)

  return (
    <div>
      <div className="relative mb-6 overflow-hidden rounded-lg border border-gray-200 bg-gradient-to-r from-brand-50 to-slate-50">
        <img
          src="/dashboard-skyline.png"
          alt=""
          className="pointer-events-none absolute inset-y-0 right-0 hidden h-full w-auto max-w-[55%] object-contain object-right opacity-80 sm:block"
        />
        <div className="relative max-w-lg px-6 py-8">
          <h1 className="text-xl font-semibold text-gray-900">{t('dashboard.heroTitle')}</h1>
          <p className="mt-1.5 text-sm text-gray-600">{t('dashboard.heroSubtitle')}</p>
        </div>
      </div>

      <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-5">
        {quickServices.map((s) => (
          <Link
            key={s.label}
            to={s.to}
            className="flex flex-col items-center gap-2 rounded-lg border border-gray-200 bg-white px-3 py-4 text-center transition-shadow hover:shadow-sm"
          >
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-brand-50 text-brand-600">
              <s.icon className="h-4 w-4" />
            </div>
            <span className="text-xs font-medium text-gray-700">{s.label}</span>
          </Link>
        ))}
      </div>

      {flagshipApp && (
        <Link to={`/applications/${flagshipApp.id}`} className="mb-6 block">
          <Card className="border-brand-500/25 p-5 transition-shadow hover:shadow-sm">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-brand-600">{t('dashboard.oneApplicationInProgress')}</p>
                <p className="mt-1 text-base font-semibold text-gray-900">
                  {flagshipApp.service} <span className="font-normal text-gray-400">· {flagshipApp.id}</span>
                </p>
              </div>
              <StatusBadge status={flagshipApp.status} />
            </div>

            <div className="mt-4 flex items-center gap-1.5 overflow-x-auto">
              {flagshipApp.timeline.map((step, idx) => (
                <div key={step.label} className="flex items-center gap-1.5">
                  <div
                    className={cn(
                      'flex h-6 w-6 shrink-0 items-center justify-center rounded-full border-2 text-[10px] font-semibold',
                      step.status === 'done' && 'border-success-600 bg-success-600 text-white',
                      step.status === 'active' && 'border-brand-500 bg-brand-50 text-brand-600',
                      step.status === 'blocked' && 'border-warning-600 bg-warning-50 text-warning-600',
                      step.status === 'pending' && 'border-gray-200 bg-white text-gray-300',
                    )}
                    title={step.label}
                  >
                    {idx + 1}
                  </div>
                  {idx < flagshipApp.timeline.length - 1 && (
                    <div className={cn('h-px w-6 shrink-0', step.status === 'done' ? 'bg-success-600/50' : 'bg-gray-200')} />
                  )}
                </div>
              ))}
            </div>

            <p className="mt-3 flex items-center gap-1 text-xs font-medium text-brand-600">
              {t('dashboard.trackApplication')} <ArrowRight className="h-3.5 w-3.5" />
            </p>
          </Card>
        </Link>
      )}

      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard icon={FileText} label={t('dashboard.statTotalApplications')} value={total} tone="brand" to="/applications" />
        <StatCard icon={Clock} label={t('dashboard.statInProgress')} value={inProgress} tone="warning" to="/applications" />
        <StatCard icon={CheckCircle2} label={t('dashboard.statCompleted')} value={completed} tone="success" to="/applications" />
        <StatCard
          icon={ShieldCheck}
          label={t('dashboard.statActiveConsents')}
          value={activeConsents}
          tone="consent"
          to="/consents"
          linkLabel={t('dashboard.manageConsents')}
        />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle>{t('dashboard.applicationTracker')}</CardTitle>
              <Link to="/applications" className="text-xs font-medium text-brand-600 hover:text-brand-700">
                {t('dashboard.viewAllApplications')}
              </Link>
            </CardHeader>
            <CardContent className="px-0 pb-0">
              <Table>
                <THead>
                  <TR>
                    <TH>{t('dashboard.colApplicationId')}</TH>
                    <TH>{t('dashboard.colService')}</TH>
                    <TH>{t('dashboard.colDepartment')}</TH>
                    <TH>{t('dashboard.colStatus')}</TH>
                    <TH>{t('dashboard.colLastUpdated')}</TH>
                  </TR>
                </THead>
                <TBody>
                  {recentApplications.map((app) => (
                    <TR key={app.id} className="cursor-pointer">
                      <TD>
                        <Link to={`/applications/${app.id}`} className="font-medium text-brand-600 hover:text-brand-700">
                          {app.id}
                        </Link>
                      </TD>
                      <TD>{app.service}</TD>
                      <TD>{app.department}</TD>
                      <TD>
                        <StatusBadge status={app.status} />
                      </TD>
                      <TD className="text-gray-500">{formatDate(app.lastUpdated)}</TD>
                    </TR>
                  ))}
                </TBody>
              </Table>
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>{t('dashboard.recentNotifications')}</CardTitle>
              <Link to="/notifications" className="text-xs font-medium text-brand-600 hover:text-brand-700">
                {t('dashboard.viewAll')}
              </Link>
            </CardHeader>
            <CardContent className="space-y-3">
              {recentNotifications.map((n) => (
                <div key={n.id} className="flex items-start gap-2.5">
                  <div className="mt-1 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-brand-50 text-brand-600">
                    <Bell className="h-3.5 w-3.5" />
                  </div>
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium text-gray-900">{n.title}</p>
                    <p className="line-clamp-2 text-xs text-gray-500">{n.description}</p>
                    <p className="mt-0.5 text-[11px] text-gray-400">{formatDateTime(n.timestamp)}</p>
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>{t('dashboard.departmentsCardTitle')}</CardTitle>
              <Link to="/departments" className="text-xs font-medium text-brand-600 hover:text-brand-700">
                {t('dashboard.viewAll')}
              </Link>
            </CardHeader>
            <CardContent className="space-y-3">
              {departments.slice(0, 5).map((d) => (
                <Link
                  key={d.id}
                  to={`/departments/${d.id}`}
                  className="flex items-center justify-between gap-2 rounded-md px-1 py-1 hover:bg-gray-50"
                >
                  <div className="flex items-center gap-2.5">
                    <div className="flex h-8 w-8 items-center justify-center rounded-md bg-navy-800/5 text-navy-800">
                      <Building2 className="h-4 w-4" />
                    </div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">{d.name}</p>
                      <p className="text-xs text-gray-500">{t('dashboard.servicesCount', { count: d.serviceCount })}</p>
                    </div>
                  </div>
                  <span
                    className={`flex items-center gap-1 text-xs font-medium ${d.hasLiveConnector ? 'text-success-600' : 'text-gray-500'}`}
                  >
                    <span className={`h-1.5 w-1.5 rounded-full ${d.hasLiveConnector ? 'bg-success-600' : 'bg-gray-400'}`} /> {d.health}
                  </span>
                </Link>
              ))}
            </CardContent>
          </Card>
        </div>
      </div>

      <div className="mt-6">
        <Card>
          <CardHeader>
            <CardTitle>{t('dashboard.myConsents')}</CardTitle>
            <Button variant="outline" size="sm" asChild>
              <Link to="/consents">{t('dashboard.manageConsents')}</Link>
            </Button>
          </CardHeader>
          <CardContent className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {consents.slice(0, 3).map((c) => (
              <div key={c.id} className="rounded-md border border-gray-200 p-4">
                <div className="mb-2 flex items-start justify-between gap-2">
                  <p className="text-sm font-medium text-gray-900">{c.dataCategory}</p>
                  <StatusBadge status={c.status} />
                </div>
                <p className="text-xs text-gray-500">{c.department}</p>
                <p className="mt-2 text-xs text-gray-400">{t('dashboard.validUntil', { date: formatDate(c.validUntil) })}</p>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
