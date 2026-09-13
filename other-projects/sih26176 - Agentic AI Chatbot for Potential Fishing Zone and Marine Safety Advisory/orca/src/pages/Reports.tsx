import { useState } from 'react'
import { FileWarning, Send } from 'lucide-react'
import { AppShell } from '@/components/AppShell'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { ports } from '@/data/ports'
import { formatTime } from '@/lib/utils'

interface ObservationReport {
  id: string
  portName: string
  category: string
  notes: string
  timestamp: string
}

const CATEGORIES = ['Hazard sighting', 'Unusual catch', 'Boundary concern', 'Equipment issue', 'Other']

export default function Reports() {
  const [reports, setReports] = useState<ObservationReport[]>([])
  const [portName, setPortName] = useState(ports[0].name)
  const [category, setCategory] = useState(CATEGORIES[0])
  const [notes, setNotes] = useState('')

  function submit() {
    if (!notes.trim()) return
    setReports((prev) => [
      { id: `RPT-${prev.length + 1}`, portName, category, notes: notes.trim(), timestamp: new Date().toISOString() },
      ...prev,
    ])
    setNotes('')
  }

  return (
    <AppShell>
      <h1 className="mb-1 flex items-center gap-2 text-lg font-bold text-white"><FileWarning className="h-5 w-5 text-cyan-400" /> Reports</h1>
      <p className="mb-4 text-xs text-slate-400">Submit a field observation — stored for this session only in this demo.</p>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[1fr_1.3fr]">
        <Card>
          <CardHeader>
            <CardTitle>Submit Observation</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div>
              <label className="mb-1 block text-xs text-slate-400">Nearest port</label>
              <select value={portName} onChange={(e) => setPortName(e.target.value)} className="w-full rounded-lg border border-navy-600 bg-navy-900 px-3 py-2 text-sm text-slate-100 outline-none focus:border-cyan-500">
                {ports.map((p) => <option key={p.name} value={p.name}>{p.name}, {p.state}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs text-slate-400">Category</label>
              <select value={category} onChange={(e) => setCategory(e.target.value)} className="w-full rounded-lg border border-navy-600 bg-navy-900 px-3 py-2 text-sm text-slate-100 outline-none focus:border-cyan-500">
                {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-xs text-slate-400">Notes</label>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                rows={4}
                placeholder="Describe what you observed..."
                className="w-full resize-none rounded-lg border border-navy-600 bg-navy-900 px-3 py-2 text-sm text-slate-100 outline-none focus:border-cyan-500"
              />
            </div>
            <button onClick={submit} className="flex items-center gap-1.5 rounded-lg bg-cyan-600 px-4 py-2 text-xs font-semibold text-white hover:bg-cyan-500">
              <Send className="h-3.5 w-3.5" /> Submit Report
            </button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Session Reports ({reports.length})</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2.5">
            {reports.length === 0 && <p className="text-xs text-slate-400">No reports submitted yet.</p>}
            {reports.map((r) => (
              <div key={r.id} className="rounded-lg border border-navy-600 bg-navy-800/50 p-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-white">{r.category}</span>
                  <span className="text-[10px] text-slate-500">{formatTime(r.timestamp)}</span>
                </div>
                <p className="mt-1 text-[11px] text-slate-400">{r.portName}</p>
                <p className="mt-1.5 text-xs text-slate-300">{r.notes}</p>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
