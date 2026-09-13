import { useCallback } from 'react'
import { useParams } from 'react-router-dom'
import { AppShell } from '@/components/shared/AppShell'
import { DetailTabs } from '@/components/shared/DetailTabs'
import { FundusCanvas } from '@/components/shared/FundusCanvas'
import { Card, CardContent } from '@/components/ui/Card'
import { Badge } from '@/components/shared/Badge'
import { useScreenings } from '@/context/ScreeningsContext'
import { drawGradCam } from '@/lib/canvasOverlays'

export default function GradCamView() {
  const { id } = useParams<{ id: string }>()
  const { getScreening } = useScreenings()
  const screening = getScreening(id ?? '')

  const draw = useCallback(
    (ctx: CanvasRenderingContext2D, w: number, h: number) => {
      if (!screening) return
      drawGradCam(ctx, w, h, screening.explainability.attentionCenter, screening.explainability.attentionRadius, screening.seed)
    },
    [screening],
  )

  if (!screening) {
    return (
      <AppShell area="clinician">
        <p className="text-sm text-gray-500">Screening not found.</p>
      </AppShell>
    )
  }

  const { explainability } = screening
  const consistencyTone = explainability.consistency === 'HIGH' ? 'green' : explainability.consistency === 'MODERATE' ? 'amber' : 'red'

  return (
    <AppShell area="clinician">
      <div className="mx-auto max-w-2xl">
        <h1 className="mb-1 text-lg font-bold text-gray-900">Grad-CAM Interpretation</h1>
        <p className="mb-4 text-xs text-gray-500">Screening {screening.id} · Attention heatmap over DR classifier</p>
        <DetailTabs id={screening.id} />

        <Card>
          <CardContent className="flex flex-col items-center">
            <FundusCanvas imageDataUrl={screening.imageDataUrl} size={380} draw={draw} className="rounded-full" />

            <div className="mt-6 w-full">
              <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">Lesion-Attention Agreement</p>
              <div className="mb-2 h-2.5 w-full overflow-hidden rounded-full bg-gray-100">
                <div
                  className="h-full rounded-full bg-success-600"
                  style={{ width: `${explainability.lesionAgreementPct}%` }}
                />
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm font-bold text-gray-900">{explainability.lesionAgreementPct}%</span>
                <span className="flex items-center gap-2 text-xs text-gray-500">
                  Consistency: <Badge tone={consistencyTone}>{explainability.consistency}</Badge>
                </span>
              </div>
              <p className="mt-3 text-[11px] leading-relaxed text-gray-400">
                Grad-CAM attention is compared against the U-Net lesion segmentation mask. A high overlap
                indicates the classifier's attention is grounded in regions containing detected retinal
                abnormalities, rather than incidental image features.
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
