import { useState } from 'react'
import { Search, User } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { mockPatients } from '@/data/mockPatients'
import { useScreenings } from '@/context/ScreeningsContext'

export default function PatientsList({ area = 'clinician' }: { area?: 'clinician' | 'operator' }) {
  const { screenings } = useScreenings()
  const [query, setQuery] = useState('')

  const filtered = mockPatients.filter(
    (p) => p.name.toLowerCase().includes(query.toLowerCase()) || p.id.toLowerCase().includes(query.toLowerCase()),
  )

  return (
    <AppShell area={area}>
      <h1 className="mb-1 text-lg font-bold text-gray-900">Patients</h1>
      <p className="mb-5 text-xs text-gray-500">Registered patients across the screening program.</p>

      <Card>
        <CardHeader>
          <CardTitle>{filtered.length} Patients</CardTitle>
          <div className="relative">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-gray-400" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search by name or ID…"
              className="rounded-lg border border-gray-200 py-1.5 pl-8 pr-3 text-xs outline-none focus:border-brand-400"
            />
          </div>
        </CardHeader>
        <CardContent className="space-y-2">
          {filtered.map((p) => {
            const count = screenings.filter((s) => s.patientId === p.id).length
            return (
              <div key={p.id} className="flex items-center gap-3 rounded-lg border border-gray-100 p-3">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-brand-50 text-brand-600">
                  <User className="h-4.5 w-4.5" />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold text-gray-900">{p.name}</p>
                  <p className="text-[11px] text-gray-400">
                    {p.id} · {p.age} yrs · {p.gender} · {p.diabetesType} · {p.village}
                  </p>
                </div>
                <span className="shrink-0 text-xs font-medium text-gray-500">{count} screening{count === 1 ? '' : 's'}</span>
              </div>
            )
          })}
        </CardContent>
      </Card>
    </AppShell>
  )
}
