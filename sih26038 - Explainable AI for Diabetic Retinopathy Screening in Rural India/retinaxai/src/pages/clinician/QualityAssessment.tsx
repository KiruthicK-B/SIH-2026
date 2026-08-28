import { useNavigate, useParams } from 'react-router-dom'
import { CheckCircle2, AlertTriangle, XCircle } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { Card, CardContent } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { QualityBadge } from '@/components/shared/Badge'
import { useScreenings } from '@/context/ScreeningsContext'

export default function QualityAssessment() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { getScreening } = useScreenings()
  const screening = getScreening(id ?? '')

  if (!screening) {
    return (
      <AppShell area="clinician">
        <p className="text-sm text-gray-500">Screening not found.</p>
      </AppShell>
    )
  }

  const { quality } = screening
  const Icon = quality.overall === 'Good' ? CheckCircle2 : quality.overall === 'Borderline' ? AlertTriangle : XCircle
  const iconTone = quality.overall === 'Good' ? 'text-success-600 bg-success-50' : quality.overall === 'Borderline' ? 'text-warning-600 bg-warning-50' : 'text-danger-600 bg-danger-50'

  return (
    <AppShell area="clinician">
      <div className="mx-auto max-w-xl">
        <h1 className="mb-1 text-lg font-bold text-gray-900">Image Quality Assessment</h1>
        <p className="mb-5 text-xs text-gray-500">Screening {screening.id}</p>

        <Card>
          <CardContent className="text-center">
            <img src={screening.imageDataUrl} alt="" className="mx-auto mb-5 h-40 w-40 rounded-full border border-gray-200 object-cover" />

            <div className={`mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-full ${iconTone}`}>
              <Icon className="h-7 w-7" />
            </div>
            <p className="text-sm font-semibold text-gray-900">Image Quality: {quality.overall}</p>
            <p className="mt-1 text-xs text-gray-500">{quality.recommendation}</p>

            <div className="mt-6 space-y-2 text-left">
              <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">Quality Metrics</p>
              {quality.metrics.map((m) => (
                <div key={m.label} className="flex items-center justify-between rounded-lg border border-gray-100 px-3 py-2">
                  <span className="text-xs text-gray-600">{m.label}</span>
                  <QualityBadge level={m.level} />
                </div>
              ))}
            </div>

            <Button
              className="mt-6 w-full"
              disabled={quality.overall === 'Poor'}
              onClick={() => navigate(`/app/screening/${screening.id}/analyzing`)}
            >
              Proceed to Analysis
            </Button>
            {quality.overall === 'Poor' && (
              <p className="mt-2 text-xs font-medium text-danger-600">
                Image quality is too low to proceed. Please recapture and re-upload.
              </p>
            )}
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
