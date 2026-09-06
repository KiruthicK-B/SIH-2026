import { Building2, Clock, FileStack } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Link } from 'react-router-dom'
import { PageHeader } from '@/components/shared/PageHeader'
import { Card } from '@/components/ui/Card'
import { useServices } from '@/context/ServicesContext'

export default function Services() {
  const { t } = useTranslation()
  const { categories, getServicesByCategory } = useServices()

  return (
    <div>
      <PageHeader title={t('services.title')} subtitle={t('services.subtitle')} />

      <div className="space-y-8">
        {categories.map((category) => (
          <section key={category}>
            <h2 className="mb-3 text-sm font-semibold text-gray-900">{category}</h2>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {getServicesByCategory(category).map((service) => (
                <Link key={service.id} to={`/services/${service.id}`}>
                  <Card className="h-full p-5 transition-shadow hover:shadow-sm">
                    <p className="text-sm font-semibold text-gray-900">{service.name}</p>
                    <p className="mt-1 flex items-center gap-1.5 text-xs text-gray-500">
                      <Building2 className="h-3.5 w-3.5" /> {service.department}
                    </p>
                    <p className="mt-3 line-clamp-2 text-xs text-gray-500">{service.description}</p>
                    <div className="mt-4 flex items-center justify-between border-t border-gray-100 pt-3">
                      <span className="flex items-center gap-1.5 text-xs text-gray-500">
                        <Clock className="h-3.5 w-3.5" /> {service.processingTime}
                      </span>
                      <span className="flex items-center gap-1.5 text-xs text-gray-500">
                        <FileStack className="h-3.5 w-3.5" /> {t('services.docsCount', { count: service.requiredDocuments.length })}
                      </span>
                    </div>
                  </Card>
                </Link>
              ))}
            </div>
          </section>
        ))}
      </div>
    </div>
  )
}
