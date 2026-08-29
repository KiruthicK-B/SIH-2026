import { useMemo, useState } from 'react'
import { Navigation2 } from 'lucide-react'
import { AppShell } from '@/components/AppShell'
import { MapPanel } from '@/components/MapPanel'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { computeOrcaSnapshot } from '@/lib/orcaSnapshot'
import { todayISO } from '@/lib/utils'
import { ports } from '@/data/ports'

const VESSEL_SPEED_KNOTS = 8
const KM_PER_NM = 1.852

export default function RoutesNavigation() {
  const [portName, setPortName] = useState(ports[0].name)
  const port = ports.find((p) => p.name === portName) ?? ports[0]
  const date = todayISO()

  const snapshot = useMemo(() => computeOrcaSnapshot(port.location, date), [port, date])
  const pfz = snapshot.pfzResult

  const speedKmh = VESSEL_SPEED_KNOTS * KM_PER_NM
  const etaHours = pfz ? pfz.distanceKm / speedKmh : null

  return (
    <AppShell>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="flex items-center gap-2 text-lg font-bold text-white"><Navigation2 className="h-5 w-5 text-cyan-400" /> Routes &amp; Navigation</h1>
          <p className="text-xs text-slate-400">Suggested route to today&rsquo;s nearest PFZ, at a cruising speed of {VESSEL_SPEED_KNOTS} kn.</p>
        </div>
        <select
          value={portName}
          onChange={(e) => setPortName(e.target.value)}
          className="rounded-lg border border-navy-600 bg-navy-800 px-3 py-2 text-sm text-slate-100 outline-none focus:border-cyan-500"
        >
          {ports.map((p) => (
            <option key={p.name} value={p.name}>{p.name}, {p.state}</option>
          ))}
        </select>
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-[1.3fr_1fr]">
        <Card className="h-[500px] overflow-hidden">
          <CardContent className="h-full p-3">
            <MapPanel
              center={pfz?.center ?? port.location}
              zoom={8}
              layers={{ pfz: true, waves: false, lightning: false, boundaries: true }}
              pfzGrid={snapshot.pfzGrid}
              userLocation={port.location}
              pfzResult={pfz}
              boundaries={snapshot.boundaries}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Route Summary</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="flex justify-between"><span className="text-slate-400">From</span><span className="font-semibold text-white">{port.name}</span></div>
            <div className="flex justify-between"><span className="text-slate-400">To</span><span className="font-semibold text-white">Nearest PFZ ({pfz?.direction ?? '—'})</span></div>
            <div className="flex justify-between"><span className="text-slate-400">Distance</span><span className="font-semibold text-white">{pfz?.distanceKm ?? '—'} km</span></div>
            <div className="flex justify-between"><span className="text-slate-400">Est. cruising speed</span><span className="font-semibold text-white">{VESSEL_SPEED_KNOTS} kn ({Math.round(speedKmh)} km/h)</span></div>
            <div className="flex justify-between"><span className="text-slate-400">Estimated transit time</span><span className="font-semibold text-cyan-400">{etaHours ? `${etaHours.toFixed(1)} hrs` : '—'}</span></div>
            <p className="pt-2 text-[11px] leading-relaxed text-slate-500">
              Route is a straight-line estimate for planning purposes — always cross-check with current tide,
              weather, and boundary conditions before departure.
            </p>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
