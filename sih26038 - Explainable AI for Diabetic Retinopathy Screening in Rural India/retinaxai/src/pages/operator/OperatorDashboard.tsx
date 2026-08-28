import { Link } from 'react-router-dom'
import { ScanEye, AlertTriangle, Clock, Timer, ArrowRight } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { StatCard } from '@/components/shared/StatCard'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { ReferableBadge } from '@/components/shared/Badge'
import { useScreenings } from '@/context/ScreeningsContext'
import { formatDateTime } from '@/lib/utils'
import { mulberry32 } from '@/lib/rng'

const PROGRAMME_STATS = {
  totalScreenings: 1256,
  referableCases: 372,
  pendingReview: 56,
  avgTurnaroundMins: 28,
}

function ActivityChart() {
  const rng = mulberry32(20260518)
  const points: number[] = []
  let v = 40
  for (let i = 0; i < 25; i++) {
    v += (rng() - 0.5) * 26
    v = Math.max(10, Math.min(95, v))
    points.push(v)
  }
  const w = 620
  const h = 160
  const stepX = w / (points.length - 1)
  const path = points.map((p, i) => `${i === 0 ? 'M' : 'L'}${i * stepX},${h - (p / 100) * h}`).join(' ')
  const areaPath = `${path} L${w},${h} L0,${h} Z`

  return (
    <svg viewBox={`0 0 ${w} ${h + 24}`} className="w-full">
      <defs>
        <linearGradient id="activityFill" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#2563eb" stopOpacity="0.25" />
          <stop offset="100%" stopColor="#2563eb" stopOpacity="0" />
        </linearGradient>
      </defs>
      <path d={areaPath} fill="url(#activityFill)" />
      <path d={path} fill="none" stroke="#2563eb" strokeWidth="2.5" strokeLinejoin="round" strokeLinecap="round" />
      {['00:00', '06:00', '12:00', '18:00', '24:00'].map((label, i) => (
        <text key={label} x={(i / 4) * w} y={h + 18} fontSize="10" fill="#9ca3af" textAnchor={i === 0 ? 'start' : i === 4 ? 'end' : 'middle'}>
          {label}
        </text>
      ))}
    </svg>
  )
}

export default function OperatorDashboard() {
  const { screenings, ready } = useScreenings()

  return (
    <AppShell area="operator">
      <h1 className="mb-1 text-lg font-bold text-gray-900">Operator Dashboard</h1>
      <p className="mb-5 text-xs text-gray-500">Programme-wide screening operations and throughput.</p>

      <div className="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard icon={ScanEye} label="Total Screenings" value={PROGRAMME_STATS.totalScreenings.toLocaleString()} tone="brand" />
        <StatCard icon={AlertTriangle} label="Referable Cases" value={PROGRAMME_STATS.referableCases.toLocaleString()} tone="danger" />
        <StatCard icon={Clock} label="Pending Review" value={PROGRAMME_STATS.pendingReview} tone="warning" />
        <StatCard icon={Timer} label="Avg. Turnaround" value={`${PROGRAMME_STATS.avgTurnaroundMins} mins`} tone="info" />
      </div>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Today&rsquo;s Activity</CardTitle>
          <span className="text-[11px] text-gray-400">Screenings processed per hour</span>
        </CardHeader>
        <CardContent>
          <ActivityChart />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Recent Screenings (this session)</CardTitle>
          <Link to="/operator/screenings" className="text-xs font-medium text-brand-600 hover:text-brand-700">
            View all →
          </Link>
        </CardHeader>
        <CardContent className="space-y-2">
          {!ready && <p className="py-6 text-center text-xs text-gray-400">Loading…</p>}
          {screenings.slice(0, 5).map((s) => (
            <div key={s.id} className="flex items-center gap-3 rounded-lg border border-gray-100 p-2.5">
              <img src={s.imageDataUrl} alt="" className="h-10 w-10 shrink-0 rounded-full border border-gray-200 object-cover" />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-gray-900">{s.id} <span className="font-normal text-gray-400">· {s.patientName}</span></p>
                <p className="text-[11px] text-gray-400">{formatDateTime(s.timestamp)}</p>
              </div>
              <ReferableBadge referable={s.referable} />
              <Link to={`/app/screening/${s.id}/report`}><ArrowRight className="h-3.5 w-3.5 shrink-0 text-gray-300" /></Link>
            </div>
          ))}
        </CardContent>
      </Card>
    </AppShell>
  )
}
