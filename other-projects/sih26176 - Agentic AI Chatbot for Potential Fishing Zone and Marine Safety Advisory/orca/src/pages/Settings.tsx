import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Settings as SettingsIcon } from 'lucide-react'
import { AppShell } from '@/components/AppShell'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'

export default function Settings() {
  const [units, setUnits] = useState<'metric' | 'nautical'>('metric')
  const [notifyHazards, setNotifyHazards] = useState(true)
  const [notifyPfz, setNotifyPfz] = useState(true)

  return (
    <AppShell>
      <h1 className="mb-1 flex items-center gap-2 text-lg font-bold text-white"><SettingsIcon className="h-5 w-5 text-cyan-400" /> Settings</h1>
      <p className="mb-4 text-xs text-slate-400">Demo preferences — not persisted beyond this session.</p>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Preferences</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <p className="mb-1.5 text-xs text-slate-400">Language</p>
              <select disabled className="w-full rounded-lg border border-navy-600 bg-navy-900 px-3 py-2 text-sm text-slate-300">
                <option>English</option>
              </select>
              <p className="mt-1 text-[10px] text-slate-500">Additional languages are not wired up in this POC.</p>
            </div>

            <div>
              <p className="mb-1.5 text-xs text-slate-400">Distance units</p>
              <div className="flex overflow-hidden rounded-lg border border-navy-600">
                <button onClick={() => setUnits('metric')} className={`flex-1 py-2 text-xs font-medium ${units === 'metric' ? 'bg-cyan-600 text-white' : 'bg-navy-800 text-slate-300'}`}>Kilometers</button>
                <button onClick={() => setUnits('nautical')} className={`flex-1 py-2 text-xs font-medium ${units === 'nautical' ? 'bg-cyan-600 text-white' : 'bg-navy-800 text-slate-300'}`}>Nautical miles</button>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-xs text-slate-300">Hazard alert notifications</span>
              <button onClick={() => setNotifyHazards((v) => !v)} className={`h-5 w-9 rounded-full transition-colors ${notifyHazards ? 'bg-cyan-500' : 'bg-navy-600'}`}>
                <span className={`block h-4 w-4 translate-y-0.5 rounded-full bg-white transition-transform ${notifyHazards ? 'translate-x-[18px]' : 'translate-x-0.5'}`} />
              </button>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-xs text-slate-300">New PFZ notifications</span>
              <button onClick={() => setNotifyPfz((v) => !v)} className={`h-5 w-9 rounded-full transition-colors ${notifyPfz ? 'bg-cyan-500' : 'bg-navy-600'}`}>
                <span className={`block h-4 w-4 translate-y-0.5 rounded-full bg-white transition-transform ${notifyPfz ? 'translate-x-[18px]' : 'translate-x-0.5'}`} />
              </button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>About &amp; Help</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-xs text-slate-300">
            <p>ORCA is a marine intelligence assistant for potential fishing zone guidance, hazard alerts, and boundary awareness.</p>
            <Link to="/about" className="inline-block text-cyan-400 hover:text-cyan-300">Learn more about ORCA →</Link>
            <p className="pt-2 text-[11px] text-slate-500">SIH 2026 · PS 26176 · Frontend-only demo prototype.</p>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
