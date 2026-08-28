import { useCallback } from 'react'
import { useParams } from 'react-router-dom'
import { AppShell } from '@/components/shared/AppShell'
import { DetailTabs } from '@/components/shared/DetailTabs'
import { FundusCanvas } from '@/components/shared/FundusCanvas'
import { Card, CardContent } from '@/components/ui/Card'
import { useScreenings } from '@/context/ScreeningsContext'
import { drawVesselMap } from '@/lib/canvasOverlays'

export default function VesselMap() {
  const { id } = useParams<{ id: string }>()
  const { getScreening } = useScreenings()
  const screening = getScreening(id ?? '')

  const draw = useCallback(
    (ctx: CanvasRenderingContext2D, w: number, h: number) => {
      if (!screening) return
      drawVesselMap(ctx, w, h, screening.landmarks, screening.seed)
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

  const { vessel } = screening
  const nvTone = vessel.neovascularAssessment === 'Detected' ? 'text-danger-600' : vessel.neovascularAssessment === 'Suspicious' ? 'text-warning-600' : 'text-success-600'

  return (
    <AppShell area="clinician">
      <div className="mx-auto max-w-2xl">
        <h1 className="mb-1 text-lg font-bold text-gray-900">Vessel Segmentation</h1>
        <p className="mb-4 text-xs text-gray-500">Screening {screening.id} · U-Net vessel segmentation (DRIVE-trained)</p>
        <DetailTabs id={screening.id} />

        <Card>
          <CardContent className="flex flex-col items-center">
            <FundusCanvas imageDataUrl={screening.imageDataUrl} background="black" size={380} draw={draw} className="rounded-full" />

            <div className="mt-6 w-full space-y-2">
              <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">Vessel Metrics</p>
              <div className="flex justify-between border-b border-gray-100 py-2 text-sm">
                <span className="text-gray-500">Vessel Density</span>
                <span className="font-semibold text-gray-900">{vessel.density}</span>
              </div>
              <div className="flex justify-between border-b border-gray-100 py-2 text-sm">
                <span className="text-gray-500">Vessel Tortuosity</span>
                <span className="font-semibold text-gray-900">{vessel.tortuosity}</span>
              </div>
              <div className="flex justify-between border-b border-gray-100 py-2 text-sm">
                <span className="text-gray-500">Avg. Vessel Width</span>
                <span className="font-semibold text-gray-900">{vessel.avgWidthMicrons} µm</span>
              </div>
              <div className="flex justify-between py-2 text-sm">
                <span className="text-gray-500">Neovascularization-Related Evidence</span>
                <span className={`font-semibold ${nvTone}`}>{vessel.neovascularAssessment}</span>
              </div>
            </div>

            <p className="mt-4 text-[11px] italic text-gray-400">
              Vascular structure supports neovascularization-related analysis; DRIVE does not provide direct
              neovascularization labels, so this is not a standalone PDR detector.
            </p>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
