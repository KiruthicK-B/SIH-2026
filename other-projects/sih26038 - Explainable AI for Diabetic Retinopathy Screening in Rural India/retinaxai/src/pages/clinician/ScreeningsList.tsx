import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Search, FileText } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { ReferableBadge, ReviewStatusBadge } from '@/components/shared/Badge'
import { useScreenings } from '@/context/ScreeningsContext'
import { formatDateTime } from '@/lib/utils'

export default function ScreeningsList({ reportsMode = false, area = 'clinician' }: { reportsMode?: boolean; area?: 'clinician' | 'operator' }) {
  const { screenings, ready } = useScreenings()
  const [query, setQuery] = useState('')

  const filtered = screenings.filter(
    (s) => s.id.toLowerCase().includes(query.toLowerCase()) || s.patientName.toLowerCase().includes(query.toLowerCase()),
  )

  return (
    <AppShell area={area}>
      <h1 className="mb-1 text-lg font-bold text-gray-900">{reportsMode ? 'Reports' : 'Screenings'}</h1>
      <p className="mb-5 text-xs text-gray-500">
        {reportsMode ? 'Structured screening reports for every processed case.' : 'All fundus screenings processed by RetinaXAI.'}
      </p>

      <Card>
        <CardHeader>
          <CardTitle>{filtered.length} {reportsMode ? 'Reports' : 'Screenings'}</CardTitle>
          <div className="relative">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-gray-400" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search by ID or patient…"
              className="rounded-lg border border-gray-200 py-1.5 pl-8 pr-3 text-xs outline-none focus:border-brand-400"
            />
          </div>
        </CardHeader>
        <CardContent className="space-y-2">
          {!ready && <p className="py-8 text-center text-xs text-gray-400">Loading…</p>}
          {ready && filtered.length === 0 && <p className="py-8 text-center text-xs text-gray-400">No matching screenings.</p>}
          {filtered.map((s) => (
            <Link
              key={s.id}
              to={`/app/screening/${s.id}/${reportsMode ? 'report' : 'result'}`}
              className="flex items-center gap-3 rounded-lg border border-gray-100 p-3 hover:bg-gray-50"
            >
              <img src={s.imageDataUrl} alt="" className="h-11 w-11 shrink-0 rounded-full border border-gray-200 object-cover" />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-gray-900">{s.id} <span className="font-normal text-gray-400">· {s.patientName}</span></p>
                <p className="text-[11px] text-gray-400">{formatDateTime(s.timestamp)}</p>
              </div>
              <div className="hidden sm:block"><ReviewStatusBadge status={s.reviewStatus} /></div>
              <ReferableBadge referable={s.referable} />
              {reportsMode && <FileText className="h-3.5 w-3.5 shrink-0 text-gray-300" />}
            </Link>
          ))}
        </CardContent>
      </Card>
    </AppShell>
  )
}
