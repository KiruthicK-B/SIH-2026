import { Stethoscope, Mail, Building2 } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { Card, CardContent } from '@/components/ui/Card'
import { StatCard } from '@/components/shared/StatCard'
import { ScanEye, AlertTriangle, Gauge } from 'lucide-react'
import { useAuth } from '@/context/AuthContext'
import { useScreenings } from '@/context/ScreeningsContext'
import { formatPct } from '@/lib/utils'

export default function Profile() {
  const { clinicianName, role } = useAuth()
  const { stats } = useScreenings()

  return (
    <AppShell area="clinician">
      <h1 className="mb-1 text-lg font-bold text-gray-900">Profile</h1>
      <p className="mb-5 text-xs text-gray-500">Clinician account details.</p>

      <Card className="mb-6">
        <CardContent className="flex items-center gap-4">
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-brand-100 text-lg font-bold text-brand-700">
            {clinicianName.split(' ').map((s) => s[0]).join('')}
          </div>
          <div>
            <p className="text-base font-bold text-gray-900">{clinicianName}</p>
            <p className="flex items-center gap-1.5 text-xs text-gray-500"><Stethoscope className="h-3.5 w-3.5" /> {role}</p>
            <p className="flex items-center gap-1.5 text-xs text-gray-500"><Building2 className="h-3.5 w-3.5" /> Rural Telemedicine Screening Center</p>
            <p className="flex items-center gap-1.5 text-xs text-gray-500"><Mail className="h-3.5 w-3.5" /> {clinicianName.toLowerCase().replace(/\s+/g, '.')}@retinaxai.demo</p>
          </div>
        </CardContent>
      </Card>

      <h2 className="mb-3 text-sm font-semibold text-gray-700">Activity Summary</h2>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard icon={ScanEye} label="Screens Completed" value={stats.screensCompleted} tone="brand" />
        <StatCard icon={AlertTriangle} label="Referable Cases" value={stats.referableCases} tone="danger" />
        <StatCard icon={Gauge} label="Avg. Confidence" value={formatPct(stats.avgConfidence)} tone="success" />
      </div>
    </AppShell>
  )
}
