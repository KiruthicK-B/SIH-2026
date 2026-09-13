import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { ChevronDown, Download, Share2 } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { DetailTabs } from '@/components/shared/DetailTabs'
import { Card, CardContent } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { ReferableBadge, QualityBadge } from '@/components/shared/Badge'
import { useScreenings } from '@/context/ScreeningsContext'
import { formatDateTime, formatPct, cn } from '@/lib/utils'

function Section({ title, defaultOpen = false, children }: { title: string; defaultOpen?: boolean; children: React.ReactNode }) {
  const [open, setOpen] = useState(defaultOpen)
  return (
    <div className="border-b border-gray-100 last:border-b-0">
      <button
        onClick={() => setOpen((o) => !o)}
        className="flex w-full items-center justify-between py-3 text-left text-sm font-semibold text-gray-800"
      >
        {title}
        <ChevronDown className={cn('h-4 w-4 text-gray-400 transition-transform', open && 'rotate-180')} />
      </button>
      {open && <div className="pb-4">{children}</div>}
    </div>
  )
}

function Row({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex justify-between py-1.5 text-sm">
      <span className="text-gray-500">{label}</span>
      <span className="font-medium text-gray-800">{value}</span>
    </div>
  )
}

export default function FullReport() {
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

  async function handleShare() {
    const shareData = {
      title: `RetinaXAI Report — ${screening!.id}`,
      text: `DR Grade ${screening!.drGrade} (${screening!.severity}) · Referable: ${screening!.referable ? 'Yes' : 'No'}`,
    }
    if (navigator.share) {
      try {
        await navigator.share(shareData)
      } catch {
        /* user cancelled */
      }
    } else {
      await navigator.clipboard.writeText(`${shareData.title} — ${shareData.text}`)
      alert('Report summary copied to clipboard.')
    }
  }

  return (
    <AppShell area="clinician">
      <div className="mx-auto max-w-2xl">
        <h1 className="mb-1 text-lg font-bold text-gray-900">Full Screening Report</h1>
        <p className="mb-4 text-xs text-gray-500">Screening {screening.id}</p>
        <DetailTabs id={screening.id} />

        <Card>
          <CardContent>
            <div className="grid grid-cols-2 gap-x-4 border-b border-gray-100 pb-4 text-sm">
              <Row label="Patient ID" value={screening.patientId} />
              <Row label="Date / Time" value={formatDateTime(screening.timestamp)} />
              <Row label="Image Quality" value={<QualityBadge level={screening.quality.overall} />} />
              <Row label="DR Grade" value={`${screening.drGrade} (${screening.severity})`} />
              <Row label="Confidence" value={formatPct(screening.calibratedConfidence)} />
              <Row label="Referable" value={<ReferableBadge referable={screening.referable} />} />
            </div>

            <Section title="Lesion Analysis" defaultOpen>
              <Row label="Microaneurysms" value={`${screening.lesionCounts.microaneurysms} regions`} />
              <Row label="Hemorrhages" value={`${screening.lesionCounts.hemorrhages} regions`} />
              <Row label="Hard Exudates" value={`${screening.lesionCounts.hardExudates} regions`} />
              <Row label="Soft Exudates" value={`${screening.lesionCounts.softExudates} regions`} />
            </Section>

            <Section title="Vascular Analysis">
              <Row label="Vessel Segmentation" value="Completed" />
              <Row label="Vessel Density" value={screening.vessel.density} />
              <Row label="Vessel Tortuosity" value={screening.vessel.tortuosity} />
              <Row label="NV Assessment" value={screening.vessel.neovascularAssessment} />
            </Section>

            <Section title="Macular Analysis">
              <Row label="Fovea Localized" value={screening.macular.foveaLocalized ? 'Yes' : 'No'} />
              <Row label="Exudate Proximity" value={screening.macular.exudateProximity} />
              <Row label="Macular Risk" value={screening.macular.macularRisk} />
            </Section>

            <Section title="Explainability">
              <Row label="Grad-CAM" value={screening.explainability.gradCamAvailable ? 'Available' : 'Unavailable'} />
              <Row label="Lesion Agreement" value={`${screening.explainability.lesionAgreementPct}%`} />
              <Row label="Confidence" value="Calibrated" />
            </Section>

            <div className="mt-4 rounded-lg bg-brand-50 px-4 py-3 text-xs text-brand-800">
              <p className="font-semibold">Recommendation</p>
              <p className="mt-0.5">
                {screening.referable ? 'Ophthalmologist Review Required' : 'Routine follow-up screening recommended per local protocol'}
              </p>
            </div>

            <div className="mt-5 flex gap-3">
              <Button variant="outline" className="flex-1" onClick={() => window.print()}>
                <Download className="h-4 w-4" />
                Download PDF
              </Button>
              <Button variant="outline" className="flex-1" onClick={handleShare}>
                <Share2 className="h-4 w-4" />
                Share
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
