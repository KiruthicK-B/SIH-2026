import { ArrowLeft, Building2, CheckCircle2, Clock } from 'lucide-react'
import { Link, Navigate, useParams } from 'react-router-dom'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { getServiceById } from '@/data/services'

export default function ServiceDetails() {
  const { id } = useParams<{ id: string }>()
  const service = id ? getServiceById(id) : undefined

  if (!service) {
    return <Navigate to="/services" replace />
  }

  return (
    <div>
      <Link to="/services" className="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-700">
        <ArrowLeft className="h-4 w-4" /> Back to services
      </Link>

      <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div>
          <Badge tone="neutral" className="mb-2">
            {service.category}
          </Badge>
          <h1 className="text-xl font-semibold text-gray-900">{service.name}</h1>
          <p className="mt-1 flex items-center gap-1.5 text-sm text-gray-500">
            <Building2 className="h-4 w-4" /> {service.department}
          </p>
        </div>
        <Button asChild size="lg">
          <Link to={`/services/${service.id}/apply`}>Apply for {service.name}</Link>
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle>About this service</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm leading-relaxed text-gray-600">{service.description}</p>
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Processing Time</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="flex items-center gap-2 text-sm font-medium text-gray-900">
                <Clock className="h-4 w-4 text-gray-400" /> {service.processingTime}
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Required Documents</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {service.requiredDocuments.map((doc) => (
                <p key={doc} className="flex items-center gap-2 text-sm text-gray-600">
                  <CheckCircle2 className="h-4 w-4 shrink-0 text-success-600" /> {doc}
                </p>
              ))}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
