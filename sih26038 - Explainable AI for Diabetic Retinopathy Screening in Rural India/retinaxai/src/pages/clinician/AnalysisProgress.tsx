import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { CheckCircle2, Circle, Loader2 } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { Card, CardContent } from '@/components/ui/Card'
import { useScreenings } from '@/context/ScreeningsContext'

const STEPS = [
  'Preprocessing',
  'Lesion Segmentation',
  'Vessel Segmentation',
  'DR Classification',
  'Explainability (Grad-CAM)',
  'Report Generation',
]

export default function AnalysisProgress() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { getScreening } = useScreenings()
  const screening = getScreening(id ?? '')
  const [progress, setProgress] = useState(0)
  const [activeStep, setActiveStep] = useState(0)

  useEffect(() => {
    if (!screening) return
    const totalDurationMs = 4200
    const tickMs = 60
    const increment = 100 / (totalDurationMs / tickMs)

    const interval = setInterval(() => {
      setProgress((p) => {
        const next = Math.min(100, p + increment)
        setActiveStep(Math.min(STEPS.length - 1, Math.floor((next / 100) * STEPS.length)))
        if (next >= 100) {
          clearInterval(interval)
          setTimeout(() => navigate(`/app/screening/${screening.id}/result`), 500)
        }
        return next
      })
    }, tickMs)

    return () => clearInterval(interval)
  }, [screening, navigate])

  if (!screening) {
    return (
      <AppShell area="clinician">
        <p className="text-sm text-gray-500">Screening not found.</p>
      </AppShell>
    )
  }

  const pct = Math.round(progress)
  const circumference = 2 * Math.PI * 54

  return (
    <AppShell area="clinician">
      <div className="mx-auto max-w-xl">
        <h1 className="mb-1 text-lg font-bold text-gray-900">AI Analysis in Progress</h1>
        <p className="mb-5 text-xs text-gray-500">Screening {screening.id}</p>

        <Card>
          <CardContent className="text-center">
            <div className="relative mx-auto mb-4 h-32 w-32">
              <svg viewBox="0 0 120 120" className="h-32 w-32 -rotate-90">
                <circle cx="60" cy="60" r="54" fill="none" stroke="#e5e7eb" strokeWidth="10" />
                <circle
                  cx="60"
                  cy="60"
                  r="54"
                  fill="none"
                  stroke="#2563eb"
                  strokeWidth="10"
                  strokeLinecap="round"
                  strokeDasharray={circumference}
                  strokeDashoffset={circumference - (pct / 100) * circumference}
                  style={{ transition: 'stroke-dashoffset 0.1s linear' }}
                />
              </svg>
              <div className="absolute inset-0 flex items-center justify-center text-xl font-bold text-gray-900">{pct}%</div>
            </div>

            <p className="text-sm font-semibold text-gray-900">Analyzing Image…</p>
            <p className="mt-1 text-xs text-gray-500">This may take a few seconds.</p>

            <div className="mt-6 space-y-2 text-left">
              {STEPS.map((step, i) => {
                const done = i < activeStep || pct >= 100
                const inProgress = i === activeStep && pct < 100
                return (
                  <div key={step} className="flex items-center justify-between rounded-lg border border-gray-100 px-3 py-2">
                    <span className={`text-xs ${done ? 'text-gray-700' : inProgress ? 'text-brand-700 font-medium' : 'text-gray-400'}`}>
                      {step}
                    </span>
                    {done ? (
                      <span className="flex items-center gap-1 text-xs font-medium text-success-600">
                        <CheckCircle2 className="h-3.5 w-3.5" /> Completed
                      </span>
                    ) : inProgress ? (
                      <span className="flex items-center gap-1 text-xs font-medium text-brand-600">
                        <Loader2 className="h-3.5 w-3.5 animate-spin" /> In Progress
                      </span>
                    ) : (
                      <span className="flex items-center gap-1 text-xs text-gray-300">
                        <Circle className="h-3.5 w-3.5" /> Pending
                      </span>
                    )}
                  </div>
                )
              })}
            </div>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
