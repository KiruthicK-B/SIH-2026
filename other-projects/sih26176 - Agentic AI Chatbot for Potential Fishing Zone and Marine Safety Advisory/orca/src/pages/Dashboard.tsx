import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  Thermometer,
  Leaf,
  Wind,
  Waves,
  AlertTriangle,
  Radio,
  ExternalLink,
  Fish,
  ShieldCheck,
  Navigation2,
  Clock,
  HelpCircle,
  FileWarning,
} from 'lucide-react'
import { AppShell } from '@/components/AppShell'
import { ChatInterface } from '@/components/ChatInterface'
import { MapPanel } from '@/components/MapPanel'
import { AlertsBanner } from '@/components/AlertsBanner'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { computeOrcaSnapshot } from '@/lib/orcaSnapshot'
import { todayISO } from '@/lib/utils'
import { ports } from '@/data/ports'

const HOME_PORT = ports[0] // Chennai

const DATA_LAYER_ITEMS = [
  { key: 'sst', label: 'Sea Surface Temperature', icon: Thermometer, color: 'text-danger-500' },
  { key: 'chl', label: 'Chlorophyll-A', icon: Leaf, color: 'text-success-500' },
  { key: 'wind', label: 'Wind', icon: Wind, color: 'text-cyan-400' },
  { key: 'wave', label: 'Wave Height', icon: Waves, color: 'text-ocean-blue' },
  { key: 'currents', label: 'Currents', icon: Navigation2, color: 'text-warning-500' },
  { key: 'rain', label: 'Rainfall', icon: Radio, color: 'text-slate-400' },
] as const

const QUICK_ACTIONS = [
  { label: 'PFZ Finder', sub: 'Find best fishing zones', icon: Fish, to: '/pfz-finder' },
  { label: 'Safety Check', sub: 'Is it safe to go?', icon: ShieldCheck, to: '/chat' },
  { label: 'Route Planner', sub: 'Plan safe route', icon: Navigation2, to: '/routes' },
  { label: 'Tide Info', sub: 'Check tides', icon: Clock, to: '/tides' },
  { label: 'Report Issue', sub: 'Submit observation', icon: FileWarning, to: '/reports' },
  { label: 'Help', sub: 'User guide', icon: HelpCircle, to: '/settings' },
]

export default function Dashboard() {
  const date = todayISO()
  const snapshot = useMemo(() => computeOrcaSnapshot(HOME_PORT.location, date), [date])
  const [enabledLayers, setEnabledLayers] = useState<Record<string, boolean>>({ sst: true, chl: true, wind: true, wave: true, currents: true, rain: false })

  const stats = [
    { key: 'sst', label: 'Sea Surface Temp', value: snapshot.weather.seaSurfaceTempC.toFixed(1), unit: '°C', icon: Thermometer, tone: 'text-danger-400', sub: '28.0 – 32.5 °C' },
    { key: 'chl', label: 'Chlorophyll-A', value: snapshot.pfzResult?.likelihood ? (0.4 + snapshot.pfzResult.likelihood * 1.4).toFixed(2) : '—', unit: 'mg/m³', icon: Leaf, tone: 'text-success-400', sub: '0.2 – 2.5 mg/m³' },
    { key: 'wind', label: 'Wind Speed', value: String(snapshot.weather.windSpeedKmh), unit: 'km/h', icon: Wind, tone: 'text-cyan-400', sub: `${snapshot.weather.windDirection} · Moderate Breeze` },
    { key: 'wave', label: 'Wave Height', value: snapshot.weather.waveHeightM.toFixed(1), unit: 'm', icon: Waves, tone: 'text-ocean-blue', sub: snapshot.weather.waveHeightM > 1.5 ? 'Rough' : 'Moderate' },
    { key: 'hazards', label: 'Active Hazards', value: String(snapshot.alerts.length), unit: '', icon: AlertTriangle, tone: 'text-danger-500', sub: 'View Details →', link: '/alerts' },
    { key: 'stations', label: 'Stations Online', value: '8/8', unit: '', icon: Radio, tone: 'text-success-500', sub: 'All Stations Online' },
  ]

  return (
    <AppShell>
      <div className="mb-5 grid grid-cols-2 gap-3 lg:grid-cols-6">
        {stats.map((s) => {
          const inner = (
            <div className="rounded-xl border border-navy-600 bg-navy-800/60 p-3.5">
              <p className="flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wide text-slate-400">
                <s.icon className={`h-3.5 w-3.5 ${s.tone}`} /> {s.label}
              </p>
              <p className="mt-1.5 text-2xl font-bold text-white">
                {s.value} <span className="text-xs font-normal text-slate-400">{s.unit}</span>
              </p>
              <p className="mt-1 text-[10px] text-slate-500">{s.sub}</p>
            </div>
          )
          return s.link ? (
            <Link key={s.key} to={s.link}>
              {inner}
            </Link>
          ) : (
            <div key={s.key}>{inner}</div>
          )
        })}
      </div>

      <div className="mb-5 grid grid-cols-1 gap-4 xl:grid-cols-[1.4fr_1fr]">
        <Card className="flex flex-col overflow-hidden">
          <CardHeader>
            <CardTitle>Potential Fishing Zones (PFZ) — Today</CardTitle>
            <Link to="/marine-map" className="flex items-center gap-1 text-[11px] font-medium text-cyan-400 hover:text-cyan-300">
              View Full Map <ExternalLink className="h-3 w-3" />
            </Link>
          </CardHeader>
          <CardContent className="h-[420px] p-3">
            <MapPanel
              center={snapshot.pfzResult?.center ?? HOME_PORT.location}
              zoom={8}
              layers={{ pfz: true, waves: false, lightning: false, boundaries: true }}
              pfzGrid={snapshot.pfzGrid}
              userLocation={HOME_PORT.location}
              pfzResult={snapshot.pfzResult}
              boundaries={snapshot.boundaries}
            />
          </CardContent>
        </Card>

        <Card className="flex h-[480px] flex-col overflow-hidden">
          <ChatInterface compact />
        </Card>
      </div>

      <div className="mb-5 grid grid-cols-1 gap-4 lg:grid-cols-4">
        <Card>
          <CardHeader>
            <CardTitle>Weather &amp; Sea Conditions</CardTitle>
          </CardHeader>
          <CardContent className="grid grid-cols-2 gap-3 text-xs">
            <div>
              <p className="flex items-center gap-1.5 text-slate-400"><Wind className="h-3.5 w-3.5" /> Wind</p>
              <p className="mt-0.5 font-semibold text-white">{snapshot.weather.windSpeedKmh} km/h {snapshot.weather.windDirection}</p>
            </div>
            <div>
              <p className="text-slate-400">Weather</p>
              <p className="mt-0.5 font-semibold text-white">{snapshot.weather.lightningRisk === 'Low' ? 'Partly Cloudy' : 'Stormy'}</p>
            </div>
            <div>
              <p className="text-slate-400">Pressure</p>
              <p className="mt-0.5 font-semibold text-white">{snapshot.weather.pressureHpa} hPa</p>
            </div>
            <div>
              <p className="text-slate-400">Visibility</p>
              <p className="mt-0.5 font-semibold text-white">{snapshot.weather.visibilityKm} km</p>
            </div>
            <div className="col-span-2 flex items-center gap-1.5">
              <Waves className="h-3.5 w-3.5 text-slate-400" />
              <p className="font-semibold text-white">Wave Height {snapshot.weather.waveHeightM.toFixed(1)} m</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Tides ({HOME_PORT.name} Coast)</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-xs">
            {snapshot.tides.events.map((e, i) => (
              <div key={i} className="flex items-center justify-between border-b border-navy-700 pb-1.5 last:border-0">
                <span className="text-slate-400">{e.type}</span>
                <span className="font-semibold text-white">{e.time}</span>
                <span className="text-cyan-400">{e.heightM} m</span>
              </div>
            ))}
            <p className="pt-1 text-slate-400">
              Current Tide: <span className="font-semibold text-cyan-400">{snapshot.tides.currentTrend}</span>
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Active Alerts</CardTitle>
            <Link to="/alerts" className="text-[11px] font-medium text-cyan-400 hover:text-cyan-300">
              View All →
            </Link>
          </CardHeader>
          <CardContent>
            <AlertsBanner alerts={snapshot.alerts} compact />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Data Layers</CardTitle>
            <span className="text-[11px] text-slate-500">Customize</span>
          </CardHeader>
          <CardContent className="space-y-2.5">
            {DATA_LAYER_ITEMS.map((item) => (
              <div key={item.key} className="flex items-center justify-between">
                <span className="flex items-center gap-2 text-xs text-slate-300">
                  <item.icon className={`h-3.5 w-3.5 ${item.color}`} /> {item.label}
                </span>
                <button
                  onClick={() => setEnabledLayers((prev) => ({ ...prev, [item.key]: !prev[item.key] }))}
                  className={`h-5 w-9 rounded-full transition-colors ${enabledLayers[item.key] ? 'bg-cyan-500' : 'bg-navy-600'}`}
                >
                  <span className={`block h-4 w-4 translate-y-0.5 rounded-full bg-white transition-transform ${enabledLayers[item.key] ? 'translate-x-[18px]' : 'translate-x-0.5'}`} />
                </button>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Quick Actions</CardTitle>
        </CardHeader>
        <CardContent className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
          {QUICK_ACTIONS.map((a) => (
            <Link
              key={a.label}
              to={a.to}
              className="flex flex-col items-center gap-1.5 rounded-lg border border-navy-600 px-3 py-3 text-center hover:border-cyan-500/40 hover:bg-navy-700/40"
            >
              <a.icon className="h-4.5 w-4.5 text-cyan-400" />
              <span className="text-xs font-semibold text-white">{a.label}</span>
              <span className="text-[10px] text-slate-500">{a.sub}</span>
            </Link>
          ))}
        </CardContent>
      </Card>
    </AppShell>
  )
}
