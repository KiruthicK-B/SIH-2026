import { useCallback } from 'react'
import { useParams } from 'react-router-dom'
import { AppShell } from '@/components/shared/AppShell'
import { DetailTabs } from '@/components/shared/DetailTabs'
import { FundusCanvas } from '@/components/shared/FundusCanvas'
import { Card, CardContent } from '@/components/ui/Card'
import { useScreenings } from '@/context/ScreeningsContext'
import { drawLandmarkMarkers, pixelToLabel } from '@/lib/canvasOverlays'

export default function AnatomicalLandmarksPage() {
  const { id } = useParams<{ id: string }>()
  const { getScreening } = useScreenings()
  const screening = getScreening(id ?? '')

  const draw = useCallback(
    (ctx: CanvasRenderingContext2D, w: number, h: number) => {
      if (!screening) return
      drawLandmarkMarkers(ctx, w, h, screening.landmarks)
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

  const size = 380
  const { landmarks } = screening

  return (
    <AppShell area="clinician">
      <div className="mx-auto max-w-2xl">
        <h1 className="mb-1 text-lg font-bold text-gray-900">Anatomical Landmarks</h1>
        <p className="mb-4 text-xs text-gray-500">Screening {screening.id} · Optic disc &amp; fovea localization</p>
        <DetailTabs id={screening.id} />

        <Card>
          <CardContent className="flex flex-col items-center">
            <div className="relative">
              <FundusCanvas imageDataUrl={screening.imageDataUrl} size={size} draw={draw} className="rounded-full" />
              <span
                className="pointer-events-none absolute -translate-x-1/2 -translate-y-full text-[10px] font-semibold text-success-600"
                style={{ left: landmarks.opticDisc.x * size, top: landmarks.opticDisc.y * size - size * 0.05 }}
              >
                Optic Disc
              </span>
              <span
                className="pointer-events-none absolute -translate-x-1/2 -translate-y-full text-[10px] font-semibold text-amber-600"
                style={{ left: landmarks.fovea.x * size, top: landmarks.fovea.y * size - size * 0.03 }}
              >
                Fovea
              </span>
            </div>

            <div className="mt-6 w-full">
              <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">Coordinates (pixels, 512×512 reference frame)</p>
              <div className="flex justify-between border-b border-gray-100 py-2 text-sm">
                <span className="text-gray-500">Optic Disc</span>
                <span className="font-semibold text-gray-900">{pixelToLabel(landmarks.opticDisc, 512, 512)}</span>
              </div>
              <div className="flex justify-between py-2 text-sm">
                <span className="text-gray-500">Fovea</span>
                <span className="font-semibold text-gray-900">{pixelToLabel(landmarks.fovea, 512, 512)}</span>
              </div>
            </div>

            <p className="mt-4 text-[11px] italic text-gray-400">
              Optic-disc localization helps distinguish the naturally bright disc region from possible hard
              exudates, which can also appear bright on fundus imaging.
            </p>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
