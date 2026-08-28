import { AlertTriangle, CheckCircle2 } from 'lucide-react'
import { StatCard } from '@/components/shared/StatCard'
import { Card, CardContent } from '@/components/ui/Card'
import { Progress } from '@/components/ui/Progress'
import { overallSlaCompliance, slaEntries } from '@/data/sla'
import { cn } from '@/lib/utils'

export function SlaTab() {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <StatCard icon={CheckCircle2} label="Overall SLA Compliance" value={`${overallSlaCompliance}%`} tone="success" />
        <StatCard
          icon={AlertTriangle}
          label="Steps Currently Breaching SLA"
          value={slaEntries.filter((s) => !s.withinSla).length}
          tone="warning"
        />
      </div>

      <Card>
        <CardContent className="space-y-5 pt-5">
          {slaEntries.map((entry) => (
            <div key={entry.label}>
              <div className="mb-1.5 flex flex-wrap items-center justify-between gap-2">
                <p className="text-sm font-medium text-gray-900">{entry.label}</p>
                <span
                  className={cn(
                    'flex items-center gap-1.5 text-xs font-medium',
                    entry.withinSla ? 'text-success-600' : 'text-danger-600',
                  )}
                >
                  {entry.withinSla ? <CheckCircle2 className="h-3.5 w-3.5" /> : <AlertTriangle className="h-3.5 w-3.5" />}
                  {entry.withinSla ? 'Within SLA' : 'SLA breach'}
                </span>
              </div>
              <p className="mb-1.5 text-xs text-gray-500">
                Target: {entry.targetLabel} · Current: {entry.currentLabel}
              </p>
              <Progress
                value={Math.min(100, (entry.currentHours / entry.targetHours) * 100)}
                barClassName={entry.withinSla ? 'bg-success-600' : 'bg-danger-600'}
              />
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  )
}
