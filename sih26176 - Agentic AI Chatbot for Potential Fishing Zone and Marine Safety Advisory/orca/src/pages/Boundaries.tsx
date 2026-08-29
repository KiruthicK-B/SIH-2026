import { useMemo, useState } from 'react'
import { ShieldAlert } from 'lucide-react'
import { AppShell } from '@/components/AppShell'
import { MapPanel } from '@/components/MapPanel'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { getBoundaries } from '@/data/mockBoundaries'
import { GeospatialAgent } from '@/agents/GeospatialAgent'
import { ports } from '@/data/ports'

const TYPE_TONE = { International: 'cyan', Restricted: 'red', MPA: 'green' } as const

export default function Boundaries() {
  const [portName, setPortName] = useState(ports[0].name)
  const port = ports.find((p) => p.name === portName) ?? ports[0]
  const boundaries = useMemo(() => getBoundaries(), [])
  const hits = useMemo(() => GeospatialAgent.checkGeofencing(port.location.lat, port.location.lon, boundaries), [port, boundaries])

  return (
    <AppShell>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="flex items-center gap-2 text-lg font-bold text-white"><ShieldAlert className="h-5 w-5 text-cyan-400" /> Boundaries</h1>
          <p className="text-xs text-slate-400">Maritime boundaries, restricted zones, and marine protected areas.</p>
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
        <Card className="h-[520px] overflow-hidden">
          <CardContent className="h-full p-3">
            <MapPanel
              center={port.location}
              zoom={7}
              layers={{ pfz: false, waves: false, lightning: false, boundaries: true }}
              pfzGrid={[]}
              userLocation={port.location}
              boundaries={boundaries}
            />
          </CardContent>
        </Card>

        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Proximity from {port.name}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2.5">
              {hits.length === 0 && <p className="text-xs text-slate-400">No boundaries within 8 km.</p>}
              {hits.map((h) => (
                <div key={h.boundary.name} className="flex items-center justify-between text-xs">
                  <span className="text-slate-300">{h.boundary.name}</span>
                  <span className="text-slate-400">{h.inside ? 'Inside' : `${h.distanceKm} km`}</span>
                </div>
              ))}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>All Boundaries</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {boundaries.map((b) => (
                <div key={b.name} className="flex items-start justify-between gap-2 border-b border-navy-700 pb-2.5 last:border-0">
                  <span className="text-xs text-slate-300">{b.name}</span>
                  <Badge tone={TYPE_TONE[b.type]}>{b.type}</Badge>
                </div>
              ))}
            </CardContent>
          </Card>
        </div>
      </div>
    </AppShell>
  )
}
