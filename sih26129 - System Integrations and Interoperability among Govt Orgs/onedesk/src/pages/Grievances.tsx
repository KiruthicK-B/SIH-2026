import { Building2, Calendar } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card } from '@/components/ui/Card'
import type { Grievance } from '@/data/grievances'
import { api } from '@/lib/api'
import { formatDate } from '@/lib/utils'

export default function Grievances() {
  const { t } = useTranslation()
  const [grievances, setGrievances] = useState<Grievance[]>([])

  useEffect(() => {
    api.get<Grievance[]>('/grievances').then(setGrievances)
  }, [])

  return (
    <div>
      <PageHeader title={t('grievances.title')} subtitle={t('grievances.subtitle')} />

      <div className="space-y-3">
        {grievances.map((g) => (
          <Card key={g.id} className="p-5">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div>
                <p className="text-xs font-medium text-gray-400">{g.id}</p>
                <p className="mt-0.5 text-sm font-semibold text-gray-900">{g.subject}</p>
              </div>
              <StatusBadge status={g.status} />
            </div>
            <p className="mt-2 text-sm text-gray-600">{g.description}</p>
            <div className="mt-3 flex flex-wrap items-center gap-4 border-t border-gray-100 pt-3 text-xs text-gray-500">
              <span className="flex items-center gap-1.5">
                <Building2 className="h-3.5 w-3.5" /> {g.department}
              </span>
              <span className="flex items-center gap-1.5">
                <Calendar className="h-3.5 w-3.5" /> {t('grievances.filedOn', { date: formatDate(g.filedOn) })}
              </span>
              {g.relatedApplication && (
                <Link to={`/applications/${g.relatedApplication}`} className="font-medium text-brand-600 hover:text-brand-700">
                  {g.relatedApplication}
                </Link>
              )}
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}
