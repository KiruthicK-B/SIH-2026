import { Link } from 'react-router-dom'
import { ScanEye, AlertTriangle, Users, Gauge, Upload as UploadIcon, ArrowRight } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { StatCard } from '@/components/shared/StatCard'
import { ReferableBadge } from '@/components/shared/Badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { useAuth } from '@/context/AuthContext'
import { useScreenings } from '@/context/ScreeningsContext'
import { formatDateTime, formatPct } from '@/lib/utils'

export default function Dashboard() {
  const { clinicianName } = useAuth()
  const { screenings, stats, ready } = useScreenings()

  return (
    <AppShell area="clinician">
      <div className="mb-6 flex flex-wrap items-center justify-between gap-3 rounded-xl bg-gradient-to-r from-brand-700 to-brand-500 px-6 py-5 text-white">
        <div>
          <p className="text-xs font-medium text-brand-100">Hello, {clinicianName}</p>
          <h1 className="text-lg font-bold">Welcome to RetinaXAI</h1>
        </div>
        <Link to="/app/upload">
          <Button variant="outline" className="border-white/40 bg-white/10 text-white hover:bg-white/20">
            <UploadIcon className="h-4 w-4" />
            Upload Fundus Image
          </Button>
        </Link>
      </div>

      <h2 className="mb-3 text-sm font-semibold text-gray-700">Today&rsquo;s Overview</h2>
      <div className="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard icon={ScanEye} label="Screens Completed" value={stats.screensCompleted} tone="brand" />
        <StatCard icon={AlertTriangle} label="Referable Cases" value={stats.referableCases} tone="danger" />
        <StatCard icon={Users} label="Patients" value={stats.patients} tone="info" />
        <StatCard icon={Gauge} label="Avg. Confidence" value={ready ? formatPct(stats.avgConfidence) : '—'} tone="success" />
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Recent Screenings</CardTitle>
          <Link to="/app/screenings" className="text-xs font-medium text-brand-600 hover:text-brand-700">
            View all →
          </Link>
        </CardHeader>
        <CardContent className="space-y-2">
          {!ready && <p className="py-6 text-center text-xs text-gray-400">Loading recent screenings…</p>}
          {ready && screenings.length === 0 && (
            <p className="py-6 text-center text-xs text-gray-400">No screenings yet. Upload a fundus image to get started.</p>
          )}
          {screenings.slice(0, 5).map((s) => (
            <Link
              key={s.id}
              to={`/app/screening/${s.id}/result`}
              className="flex items-center gap-3 rounded-lg border border-gray-100 p-2.5 hover:bg-gray-50"
            >
              <img src={s.imageDataUrl} alt="" className="h-12 w-12 shrink-0 rounded-full border border-gray-200 object-cover" />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-gray-900">{s.id}</p>
                <p className="text-[11px] text-gray-400">{formatDateTime(s.timestamp)}</p>
              </div>
              <ReferableBadge referable={s.referable} />
              <ArrowRight className="h-3.5 w-3.5 shrink-0 text-gray-300" />
            </Link>
          ))}
        </CardContent>
      </Card>
    </AppShell>
  )
}
