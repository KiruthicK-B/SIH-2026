import { useMemo, useState } from 'react'
import { AppShell } from '@/components/AppShell'
import { MapPanel } from '@/components/MapPanel'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { useOrcaChatContext } from '@/context/OrcaChatContext'
import { computeOrcaSnapshot } from '@/lib/orcaSnapshot'
import { todayISO } from '@/lib/utils'
import { ports } from '@/data/ports'
import type { MapLayers } from '@/data/types'

const HOME_PORT = ports[0]

const LAYER_LABELS: Record<keyof MapLayers, string> = {
  pfz: 'Potential Fishing Zones',
  waves: 'Wave Height',
  lightning: 'Lightning / Hazards',
  boundaries: 'Boundaries',
}

export default function MarineMap() {
  const { messages } = useOrcaChatContext()
  const lastWithAttachment = [...messages].reverse().find((m) => m.attachment?.mapCenter)

  const date = todayISO()
  const fallback = useMemo(() => computeOrcaSnapshot(HOME_PORT.location, date), [date])

  const center = lastWithAttachment?.attachment?.mapCenter ?? fallback.pfzResult?.center ?? HOME_PORT.location
  const pfzResult = lastWithAttachment?.attachment?.pfzResult ?? fallback.pfzResult
  const boundaries = fallback.boundaries
  const pfzGrid = fallback.pfzGrid

  const [layers, setLayers] = useState<MapLayers>(lastWithAttachment?.attachment?.layers ?? { pfz: true, waves: true, lightning: true, boundaries: true })

  return (
    <AppShell>
      <div className="mb-4 flex items-center justify-between">
        <div>
          <h1 className="text-lg font-bold text-white">Marine Map</h1>
          <p className="text-xs text-slate-400">PFZ, hazards, and maritime boundaries for {HOME_PORT.name}, {HOME_PORT.state}.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-[1fr_260px]">
        <Card className="h-[calc(100vh-190px)] overflow-hidden">
          <CardContent className="h-full p-3">
            <MapPanel
              center={center}
              zoom={8}
              layers={layers}
              pfzGrid={pfzGrid}
              userLocation={HOME_PORT.location}
              pfzResult={pfzResult}
              boundaries={boundaries}
              waveHeightM={fallback.weather.waveHeightM}
            />
          </CardContent>
        </Card>

        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Layers</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2.5">
              {(Object.keys(LAYER_LABELS) as (keyof MapLayers)[]).map((key) => (
                <label key={key} className="flex items-center justify-between text-xs text-slate-300">
                  {LAYER_LABELS[key]}
                  <input
                    type="checkbox"
                    checked={layers[key]}
                    onChange={(e) => setLayers((prev) => ({ ...prev, [key]: e.target.checked }))}
                    className="h-4 w-4 accent-cyan-500"
                  />
                </label>
              ))}
            </CardContent>
          </Card>

          {pfzResult && (
            <Card>
              <CardHeader>
                <CardTitle>Nearest PFZ</CardTitle>
              </CardHeader>
              <CardContent className="space-y-1.5 text-xs text-slate-300">
                <p>{pfzResult.distanceKm} km {pfzResult.direction} from {HOME_PORT.name}</p>
                <p>Likelihood: {Math.round(pfzResult.likelihood * 100)}% ({pfzResult.band})</p>
              </CardContent>
            </Card>
          )}

          <Card>
            <CardHeader>
              <CardTitle>Legend</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-[11px] text-slate-400">
              <p className="flex items-center gap-2"><span className="h-2.5 w-2.5 rounded-full" style={{ background: '#ef4444' }} /> High PFZ likelihood</p>
              <p className="flex items-center gap-2"><span className="h-2.5 w-2.5 rounded-full" style={{ background: '#eab308' }} /> Moderate likelihood</p>
              <p className="flex items-center gap-2"><span className="h-2.5 w-2.5 rounded-full" style={{ background: '#3882f6' }} /> Low likelihood</p>
              <p className="flex items-center gap-2"><span className="h-2.5 w-2.5 rounded-full border border-cyan-400" /> International boundary</p>
              <p className="flex items-center gap-2"><span className="h-2.5 w-2.5 rounded-full border border-danger-500" /> Restricted zone</p>
              <p className="flex items-center gap-2"><span className="h-2.5 w-2.5 rounded-full border border-success-500" /> Marine protected area</p>
            </CardContent>
          </Card>
        </div>
      </div>
    </AppShell>
  )
}
