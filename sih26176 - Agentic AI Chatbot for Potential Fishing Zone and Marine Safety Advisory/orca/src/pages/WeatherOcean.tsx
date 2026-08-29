import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Wind, Waves, CloudLightning, Thermometer, Gauge, Eye, Leaf } from 'lucide-react'
import { AppShell } from '@/components/AppShell'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { SeverityBadge } from '@/components/ui/Badge'
import { useOrcaChatContext } from '@/context/OrcaChatContext'
import { computeOrcaSnapshot } from '@/lib/orcaSnapshot'
import { todayISO } from '@/lib/utils'
import { ports } from '@/data/ports'
import { MarineDataAgent } from '@/agents/MarineDataAgent'

export default function WeatherOcean() {
  const navigate = useNavigate()
  const { sendMessage } = useOrcaChatContext()
  const [portName, setPortName] = useState(ports[0].name)
  const port = ports.find((p) => p.name === portName) ?? ports[0]
  const date = todayISO()

  const snapshot = useMemo(() => computeOrcaSnapshot(port.location, date), [port, date])
  const sst = MarineDataAgent.getSST(port.location.lat, port.location.lon, date)
  const chlorophyll = MarineDataAgent.getChlorophyll(port.location.lat, port.location.lon, date)

  function askExploration() {
    sendMessage('Which regions show high chlorophyll and favorable SST today?')
    navigate('/chat')
  }

  const cards = [
    { label: 'Wave Height', value: `${snapshot.weather.waveHeightM.toFixed(1)} m`, icon: Waves },
    { label: 'Wind', value: `${snapshot.weather.windSpeedKmh} km/h ${snapshot.weather.windDirection}`, icon: Wind },
    { label: 'Sea Surface Temp', value: `${snapshot.weather.seaSurfaceTempC.toFixed(1)} °C`, icon: Thermometer },
    { label: 'Pressure', value: `${snapshot.weather.pressureHpa} hPa`, icon: Gauge },
    { label: 'Visibility', value: `${snapshot.weather.visibilityKm} km`, icon: Eye },
    { label: 'Chlorophyll-A', value: `${chlorophyll.toFixed(2)} mg/m³`, icon: Leaf },
  ]

  return (
    <AppShell>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-lg font-bold text-white">Weather &amp; Ocean</h1>
          <p className="text-xs text-slate-400">Marine conditions for {port.name}, {port.state} — {date}</p>
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

      <div className="mb-4 grid grid-cols-2 gap-3 lg:grid-cols-3">
        {cards.map((c) => (
          <div key={c.label} className="rounded-xl border border-navy-600 bg-navy-800/60 p-4">
            <p className="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wide text-slate-400">
              <c.icon className="h-3.5 w-3.5 text-cyan-400" /> {c.label}
            </p>
            <p className="mt-1.5 text-xl font-bold text-white">{c.value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Hazard Indicators</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="flex items-center justify-between">
              <span className="flex items-center gap-2 text-slate-300"><CloudLightning className="h-4 w-4" /> Lightning risk</span>
              <SeverityBadge severity={snapshot.weather.lightningRisk} />
            </div>
            <div className="flex items-center justify-between">
              <span className="text-slate-300">Cyclone alert</span>
              <SeverityBadge severity={snapshot.weather.cycloneAlert ? 'High' : 'Low'} />
            </div>
            <div className="flex items-center justify-between">
              <span className="text-slate-300">Overall wave/wind hazard</span>
              <SeverityBadge severity={snapshot.weather.waveHeightM > 2.5 ? 'High' : snapshot.weather.waveHeightM > 1.5 ? 'Medium' : 'Low'} />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Chlorophyll / SST Exploration</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <p className="text-xs leading-relaxed text-slate-300">
              SST of {sst.toFixed(1)}°C and chlorophyll-a of {chlorophyll.toFixed(2)} mg/m³ near {port.name} today
              {chlorophyll > 1.0 ? ' indicate a favorable nutrient signal for PFZ formation.' : ' are near baseline — limited PFZ signal.'}
            </p>
            <button onClick={askExploration} className="rounded-lg bg-cyan-600 px-4 py-2 text-xs font-semibold text-white hover:bg-cyan-500">
              Ask ORCA to explore regions
            </button>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
