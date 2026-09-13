import { useCallback } from 'react'
import { useParams } from 'react-router-dom'
import { AppShell } from '@/components/shared/AppShell'
import { DetailTabs } from '@/components/shared/DetailTabs'
import { FundusCanvas } from '@/components/shared/FundusCanvas'
import { Card, CardContent } from '@/components/ui/Card'
import { useScreenings } from '@/context/ScreeningsContext'
import { drawLesionOverlay, lesionLegend } from '@/lib/canvasOverlays'

export default function LesionOverlay() {
  const { id } = useParams<{ id: string }>()
  const { getScreening } = useScreenings()
  const screening = getScreening(id ?? '')

  const draw = useCallback(
    (ctx: CanvasRenderingContext2D, w: number, h: number) => {
      if (!screening) return
      drawLesionOverlay(ctx, w, h, screening.lesionPoints)
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

  return (
    <AppShell area="clinician">
      <div className="mx-auto max-w-2xl">
        <h1 className="mb-1 text-lg font-bold text-gray-900">Lesion Overlay</h1>
        <p className="mb-4 text-xs text-gray-500">Screening {screening.id} · U-Net lesion segmentation</p>
        <DetailTabs id={screening.id} />

        <Card>
          <CardContent className="flex flex-col items-center">
            <FundusCanvas imageDataUrl={screening.imageDataUrl} size={380} draw={draw} className="rounded-full" />

            <div className="mt-6 grid w-full grid-cols-2 gap-3 sm:grid-cols-4">
              {lesionLegend().map((l) => (
                <div key={l.key} className="flex items-center gap-2 rounded-lg border border-gray-100 px-3 py-2">
                  <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ backgroundColor: l.color }} />
                  <span className="text-xs text-gray-600">{l.label}</span>
                </div>
              ))}
            </div>

            <div className="mt-4 grid w-full grid-cols-4 gap-2 text-center">
              <div className="rounded-lg bg-gray-50 py-2">
                <p className="text-lg font-bold text-gray-900">{screening.lesionCounts.microaneurysms}</p>
                <p className="text-[10px] text-gray-500">MA regions</p>
              </div>
              <div className="rounded-lg bg-gray-50 py-2">
                <p className="text-lg font-bold text-gray-900">{screening.lesionCounts.hemorrhages}</p>
                <p className="text-[10px] text-gray-500">HE regions</p>
              </div>
              <div className="rounded-lg bg-gray-50 py-2">
                <p className="text-lg font-bold text-gray-900">{screening.lesionCounts.hardExudates}</p>
                <p className="text-[10px] text-gray-500">EX regions</p>
              </div>
              <div className="rounded-lg bg-gray-50 py-2">
                <p className="text-lg font-bold text-gray-900">{screening.lesionCounts.softExudates}</p>
                <p className="text-[10px] text-gray-500">SE regions</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
