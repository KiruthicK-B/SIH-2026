import { ArrowLeft, Building2, Calendar, Plug } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Link, Navigate, useParams } from 'react-router-dom'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { useApplications } from '@/context/ApplicationsContext'
import { useDepartments } from '@/context/DepartmentsContext'
import { useServices } from '@/context/ServicesContext'
import { formatDate } from '@/lib/utils'

export default function DepartmentDetails() {
  const { t } = useTranslation()
  const { id } = useParams<{ id: string }>()
  const { getDepartmentById } = useDepartments()
  const department = id ? getDepartmentById(id) : undefined
  const { applications } = useApplications()
  const { services } = useServices()

  if (!department) {
    return <Navigate to="/departments" replace />
  }

  const departmentServices = services.filter((s) => s.department === department.name)
  const departmentApplications = applications.filter((a) => a.department === department.name)

  return (
    <div>
      <Link to="/departments" className="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-700">
        <ArrowLeft className="h-4 w-4" /> {t('departmentDetails.backToDepartments')}
      </Link>

      <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-md bg-navy-800/5 text-navy-800">
            <Building2 className="h-6 w-6" />
          </div>
          <div>
            <h1 className="text-xl font-semibold text-gray-900">{department.name}</h1>
            <p className="mt-1 text-sm text-gray-500">{department.description}</p>
          </div>
        </div>
        <span
          className={`flex items-center gap-1.5 text-sm font-medium ${department.killSwitchEnabled ? 'text-danger-600' : department.hasLiveConnector ? 'text-success-600' : 'text-gray-500'}`}
        >
          <span
            className={`h-2 w-2 rounded-full ${department.killSwitchEnabled ? 'bg-danger-600' : department.hasLiveConnector ? 'bg-success-600' : 'bg-gray-400'}`}
          />
          {department.health}
        </span>
      </div>

      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Card className="p-4">
          <p className="flex items-center gap-1.5 text-xs text-gray-500">
            <Plug className="h-3.5 w-3.5" /> {t('departmentDetails.interfaceType')}
          </p>
          <p className="mt-1 text-sm font-semibold text-gray-900">{department.interfaceType}</p>
        </Card>
        <Card className="p-4">
          <p className="text-xs text-gray-500">{t('departmentDetails.services')}</p>
          <p className="mt-1 text-sm font-semibold text-gray-900">{department.serviceCount}</p>
        </Card>
        <Card className="p-4">
          <p className="flex items-center gap-1.5 text-xs text-gray-500">
            <Calendar className="h-3.5 w-3.5" /> {t('departmentDetails.onboardedOn')}
          </p>
          <p className="mt-1 text-sm font-semibold text-gray-900">{formatDate(department.onboardedOn)}</p>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>{t('departmentDetails.servicesOfferedTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {departmentServices.map((s) => (
              <Link
                key={s.id}
                to={`/services/${s.id}`}
                className="flex items-center justify-between rounded-md px-2 py-2 text-sm text-gray-700 hover:bg-gray-50"
              >
                {s.name}
                <span className="text-xs text-gray-400">{s.processingTime}</span>
              </Link>
            ))}
            {departmentServices.length === 0 && <p className="text-sm text-gray-400">{t('departmentDetails.noListedServices')}</p>}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t('departmentDetails.yourApplicationsTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {departmentApplications.map((a) => (
              <Link
                key={a.id}
                to={`/applications/${a.id}`}
                className="flex items-center justify-between rounded-md px-2 py-2 text-sm text-gray-700 hover:bg-gray-50"
              >
                <span>
                  {a.id} <span className="text-gray-400">· {a.service}</span>
                </span>
                <StatusBadge status={a.status} />
              </Link>
            ))}
            {departmentApplications.length === 0 && (
              <p className="text-sm text-gray-400">{t('departmentDetails.noApplicationsYet')}</p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
