import { Link, useParams } from 'react-router-dom'
import { FileText, Layers, GitBranch, MapPin, Flame, HelpCircle } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { Card, CardContent } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { QualityBadge, ReferableBadge } from '@/components/shared/Badge'
import { useScreenings } from '@/context/ScreeningsContext'
import { formatPct } from '@/lib/utils'

export default function ResultSummary() {
  const { id } = useParams<{ id: string }>()
  const { getScreening } = useScreenings()
  const screening = getScreening(id ?? '')

  if (!screening) {
    return (
      <AppShell area="clinician">
        <p className="text-sm text-gray-500">Screening not found.</p>
      </AppShell>
    )
  }

  const gradeTone =
    screening.drGrade === 0 ? 'text-success-600 bg-success-50' : screening.drGrade <= 1 ? 'text-brand-600 bg-brand-50' : screening.drGrade === 2 ? 'text-warning-600 bg-warning-50' : 'text-danger-600 bg-danger-50'

  const quickLinks = [
    { label: 'Lesion Overlay', icon: Layers, to: `/app/screening/${screening.id}/lesions` },
    { label: 'Vessel Map', icon: GitBranch, to: `/app/screening/${screening.id}/vessels` },
    { label: 'OD & Fovea', icon: MapPin, to: `/app/screening/${screening.id}/anatomy` },
    { label: 'Grad-CAM', icon: Flame, to: `/app/screening/${screening.id}/gradcam` },
  ]

  return (
    <AppShell area="clinician">
      <div className="mx-auto max-w-xl">
        <h1 className="mb-1 text-lg font-bold text-gray-900">Screening Result Summary</h1>
        <p className="mb-5 text-xs text-gray-500">Screening {screening.id} · Patient {screening.patientName}</p>

        <Card>
          <CardContent>
            <div className={`flex items-center justify-between rounded-xl px-4 py-4 ${screening.referable ? 'bg-danger-50' : 'bg-success-50'}`}>
              <div>
                <p className={`text-xs font-semibold uppercase tracking-wide ${screening.referable ? 'text-danger-600' : 'text-success-700'}`}>DR Grade</p>
                <div className="flex items-center gap-2">
                  <span className={`flex h-11 w-11 items-center justify-center rounded-full text-xl font-bold ${gradeTone}`}>
                    {screening.drGrade}
                  </span>
                  <span className="text-sm font-semibold text-gray-800">{screening.severity}</span>
                </div>
              </div>
              <HelpCircle className={`h-5 w-5 ${screening.referable ? 'text-danger-400' : 'text-success-400'}`} />
            </div>

            <div className="mt-4 grid grid-cols-2 gap-3">
              <div className="rounded-lg border border-gray-100 px-3 py-2.5">
                <p className="text-[11px] text-gray-400">Confidence</p>
                <p className="text-lg font-bold text-gray-900">{formatPct(screening.calibratedConfidence)}</p>
              </div>
              <div className="rounded-lg border border-gray-100 px-3 py-2.5">
                <p className="text-[11px] text-gray-400">Referable</p>
                <div className="mt-0.5"><ReferableBadge referable={screening.referable} /></div>
              </div>
            </div>

            <p className="mb-2 mt-5 text-xs font-semibold uppercase tracking-wide text-gray-400">Clinical Evidence</p>
            <div className="space-y-1.5 text-sm">
              <div className="flex justify-between border-b border-gray-50 py-1.5">
                <span className="text-gray-500">Microaneurysms</span>
                <span className="font-semibold text-gray-800">{screening.lesionCounts.microaneurysms}</span>
              </div>
              <div className="flex justify-between border-b border-gray-50 py-1.5">
                <span className="text-gray-500">Hemorrhages</span>
                <span className="font-semibold text-gray-800">{screening.lesionCounts.hemorrhages}</span>
              </div>
              <div className="flex justify-between border-b border-gray-50 py-1.5">
                <span className="text-gray-500">Hard Exudates</span>
                <span className="font-semibold text-gray-800">{screening.lesionCounts.hardExudates}</span>
              </div>
              <div className="flex justify-between py-1.5">
                <span className="text-gray-500">Soft Exudates</span>
                <span className="font-semibold text-gray-800">{screening.lesionCounts.softExudates}</span>
              </div>
            </div>

            <div className="mt-4 grid grid-cols-2 gap-3">
              <div className="rounded-lg border border-gray-100 px-3 py-2.5">
                <p className="text-[11px] text-gray-400">Macular Risk</p>
                <p className={`text-sm font-bold ${screening.macular.macularRisk === 'Elevated' ? 'text-danger-600' : screening.macular.macularRisk === 'Moderate' ? 'text-warning-600' : 'text-success-600'}`}>
                  {screening.macular.macularRisk}
                </p>
              </div>
              <div className="rounded-lg border border-gray-100 px-3 py-2.5">
                <p className="text-[11px] text-gray-400">Image Quality</p>
                <div className="mt-0.5"><QualityBadge level={screening.quality.overall} /></div>
              </div>
            </div>

            <div className="mt-5 grid grid-cols-4 gap-2">
              {quickLinks.map((q) => (
                <Link
                  key={q.to}
                  to={q.to}
                  className="flex flex-col items-center gap-1.5 rounded-lg border border-gray-200 px-2 py-3 text-center hover:bg-gray-50"
                >
                  <q.icon className="h-4 w-4 text-brand-600" />
                  <span className="text-[10px] font-medium text-gray-600">{q.label}</span>
                </Link>
              ))}
            </div>

            <Link to={`/app/screening/${screening.id}/report`}>
              <Button className="mt-5 w-full">
                <FileText className="h-4 w-4" />
                View Full Report
              </Button>
            </Link>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
