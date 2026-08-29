import { useMemo } from 'react'
import { AppShell } from '@/components/AppShell'
import { AlertsBanner } from '@/components/AlertsBanner'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { useOrcaChatContext } from '@/context/OrcaChatContext'
import { computeOrcaSnapshot } from '@/lib/orcaSnapshot'
import { todayISO } from '@/lib/utils'
import { ports } from '@/data/ports'

export default function AlertsPage() {
  const { messages } = useOrcaChatContext()
  const date = todayISO()

  const snapshots = useMemo(() => ports.map((p) => ({ port: p, snapshot: computeOrcaSnapshot(p.location, date) })), [date])

  const chatAlerts = messages.flatMap((m) => m.attachment?.alerts ?? [])
  const seen = new Set<string>()
  const mergedChatAlerts = chatAlerts.filter((a) => {
    const key = a.title + a.text
    if (seen.has(key)) return false
    seen.add(key)
    return true
  })

  return (
    <AppShell>
      <h1 className="mb-1 text-lg font-bold text-white">Alerts</h1>
      <p className="mb-4 text-xs text-slate-400">Active hazard alerts across monitored coastal stations.</p>

      {mergedChatAlerts.length > 0 && (
        <Card className="mb-4">
          <CardHeader>
            <CardTitle>From your recent conversation</CardTitle>
          </CardHeader>
          <CardContent>
            <AlertsBanner alerts={mergedChatAlerts} />
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        {snapshots.map(({ port, snapshot }) => (
          <Card key={port.name}>
            <CardHeader>
              <CardTitle>{port.name}, {port.state}</CardTitle>
              <span className="text-[11px] text-slate-500">{date}</span>
            </CardHeader>
            <CardContent>
              <AlertsBanner alerts={snapshot.alerts} compact />
            </CardContent>
          </Card>
        ))}
      </div>
    </AppShell>
  )
}
