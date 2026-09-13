import { useMemo, useState } from 'react'
import { Waves } from 'lucide-react'
import { AppShell } from '@/components/AppShell'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { WeatherAgent } from '@/agents/WeatherAgent'
import { todayISO } from '@/lib/utils'
import { ports } from '@/data/ports'

export default function Tides() {
  const [portName, setPortName] = useState(ports[0].name)
  const port = ports.find((p) => p.name === portName) ?? ports[0]
  const date = todayISO()

  const tides = useMemo(() => WeatherAgent.getTides(port.location.lat, port.location.lon, date), [port, date])

  const maxHeight = Math.max(...tides.events.map((e) => e.heightM))

  return (
    <AppShell>
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="flex items-center gap-2 text-lg font-bold text-white"><Waves className="h-5 w-5 text-cyan-400" /> Tides</h1>
          <p className="text-xs text-slate-400">{port.name} Coast — {date}</p>
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

      <Card>
        <CardHeader>
          <CardTitle>Today&rsquo;s Tide Chart</CardTitle>
          <span className="text-[11px] text-slate-400">
            Current Tide: <span className="font-semibold text-cyan-400">{tides.currentTrend}</span>
          </span>
        </CardHeader>
        <CardContent>
          <svg viewBox="0 0 600 180" className="w-full">
            <path
              d={buildTidePath(tides.events, maxHeight)}
              fill="none"
              stroke="#22d3ee"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            {tides.events.map((e, i) => {
              const x = (i / (tides.events.length - 1)) * 560 + 20
              const y = 160 - (e.heightM / maxHeight) * 130
              return (
                <g key={i}>
                  <circle cx={x} cy={y} r="4" fill="#22d3ee" />
                  <text x={x} y={y - 12} fontSize="11" fill="#e2e8f0" textAnchor="middle">{e.type} {e.heightM}m</text>
                  <text x={x} y="176" fontSize="10" fill="#64748b" textAnchor="middle">{e.time}</text>
                </g>
              )
            })}
          </svg>
        </CardContent>
      </Card>

      <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
        {tides.events.map((e, i) => (
          <div key={i} className="rounded-xl border border-navy-600 bg-navy-800/60 p-4 text-center">
            <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-400">{e.type} Tide</p>
            <p className="mt-1 text-xl font-bold text-white">{e.heightM} m</p>
            <p className="text-xs text-slate-500">{e.time}</p>
          </div>
        ))}
      </div>
    </AppShell>
  )
}

function buildTidePath(events: { heightM: number }[], maxHeight: number) {
  return events
    .map((e, i) => {
      const x = (i / (events.length - 1)) * 560 + 20
      const y = 160 - (e.heightM / maxHeight) * 130
      return `${i === 0 ? 'M' : 'L'}${x},${y}`
    })
    .join(' ')
}
