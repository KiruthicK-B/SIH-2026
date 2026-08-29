import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Fish } from 'lucide-react'
import { AppShell } from '@/components/AppShell'
import { MapPanel } from '@/components/MapPanel'
import { PFZSafetyCard } from '@/components/PFZSafetyCard'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { useOrcaChatContext } from '@/context/OrcaChatContext'
import { computeOrcaSnapshot } from '@/lib/orcaSnapshot'
import { ports } from '@/data/ports'

export default function PFZFinder() {
  const navigate = useNavigate()
  const { sendMessage } = useOrcaChatContext()
  const [portName, setPortName] = useState(ports[0].name)
  const [dayOffset, setDayOffset] = useState(0)

  const port = ports.find((p) => p.name === portName) ?? ports[0]
  const date = useMemo(() => {
    const d = new Date()
    d.setDate(d.getDate() + dayOffset)
    return d.toISOString().slice(0, 10)
  }, [dayOffset])

  const snapshot = useMemo(() => computeOrcaSnapshot(port.location, date), [port, date])

  function askOrca() {
    sendMessage(`Where is the nearest PFZ ${dayOffset === 0 ? 'today' : dayOffset === 1 ? 'tomorrow' : 'in ' + dayOffset + ' days'} from ${port.name}? Is it safe?`)
    navigate('/chat')
  }

  return (
    <AppShell>
      <h1 className="mb-1 flex items-center gap-2 text-lg font-bold text-white">
        <Fish className="h-5 w-5 text-cyan-400" /> PFZ Finder
      </h1>
      <p className="mb-4 text-xs text-slate-400">Find the nearest high-likelihood potential fishing zone from any port.</p>

      <div className="mb-4 flex flex-wrap items-center gap-3">
        <select
          value={portName}
          onChange={(e) => setPortName(e.target.value)}
          className="rounded-lg border border-navy-600 bg-navy-800 px-3 py-2 text-sm text-slate-100 outline-none focus:border-cyan-500"
        >
          {ports.map((p) => (
            <option key={p.name} value={p.name}>
              {p.name}, {p.state}
            </option>
          ))}
        </select>

        <div className="flex overflow-hidden rounded-lg border border-navy-600">
          {['Today', 'Tomorrow', 'Day after'].map((label, i) => (
            <button
              key={label}
              onClick={() => setDayOffset(i)}
              className={`px-3 py-2 text-xs font-medium ${dayOffset === i ? 'bg-cyan-600 text-white' : 'bg-navy-800 text-slate-300 hover:bg-navy-700'}`}
            >
              {label}
            </button>
          ))}
        </div>

        <button onClick={askOrca} className="ml-auto rounded-lg bg-cyan-600 px-4 py-2 text-xs font-semibold text-white hover:bg-cyan-500">
          Ask ORCA about this
        </button>
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-[1.3fr_1fr]">
        <Card className="h-[520px] overflow-hidden">
          <CardContent className="h-full p-3">
            <MapPanel
              center={snapshot.pfzResult?.center ?? port.location}
              zoom={8}
              layers={{ pfz: true, waves: false, lightning: false, boundaries: true }}
              pfzGrid={snapshot.pfzGrid}
              userLocation={port.location}
              pfzResult={snapshot.pfzResult}
              boundaries={snapshot.boundaries}
            />
          </CardContent>
        </Card>

        <div className="space-y-4">
          <PFZSafetyCard pfzResult={snapshot.pfzResult ?? undefined} safety={snapshot.safety} date={date} />
          <Card>
            <CardHeader>
              <CardTitle>Top zones today</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {[...snapshot.pfzGrid]
                .sort((a, b) => b.likelihood - a.likelihood)
                .slice(0, 5)
                .map((cell, i) => (
                  <div key={i} className="flex items-center justify-between text-xs text-slate-300">
                    <span>Zone {i + 1}</span>
                    <span className="text-slate-400">SST {cell.sst.toFixed(1)}°C · Chl {cell.chlorophyll.toFixed(2)}</span>
                    <span className="font-semibold text-white">{Math.round(cell.likelihood * 100)}%</span>
                  </div>
                ))}
            </CardContent>
          </Card>
        </div>
      </div>
    </AppShell>
  )
}
