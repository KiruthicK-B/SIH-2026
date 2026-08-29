import { AlertTriangle, CloudLightning, Wind, ShieldAlert } from 'lucide-react'
import { SeverityBadge } from './ui/Badge'
import type { OrcaAlert } from '@/data/types'
import { cn } from '@/lib/utils'

const ICONS: Record<OrcaAlert['kind'], typeof AlertTriangle> = {
  wave: Wind,
  lightning: CloudLightning,
  cyclone: AlertTriangle,
  boundary: ShieldAlert,
}

const SEVERITY_BORDER: Record<string, string> = {
  High: 'border-l-danger-500',
  Medium: 'border-l-warning-500',
  Low: 'border-l-success-500',
}

export function AlertsBanner({ alerts, compact = false }: { alerts: OrcaAlert[]; compact?: boolean }) {
  if (alerts.length === 0) {
    return (
      <div className="rounded-lg border border-navy-600 bg-navy-800/60 px-3 py-2.5 text-xs text-slate-400">
        No active hazard alerts.
      </div>
    )
  }

  return (
    <div className="space-y-2">
      {alerts.map((alert) => {
        const Icon = ICONS[alert.kind]
        return (
          <div
            key={alert.id}
            className={cn(
              'flex items-start gap-2.5 rounded-lg border-l-4 bg-navy-700/50 px-3 py-2.5',
              SEVERITY_BORDER[alert.severity] ?? 'border-l-slate-500',
            )}
          >
            <Icon className="mt-0.5 h-4 w-4 shrink-0 text-slate-300" />
            <div className="min-w-0 flex-1">
              <div className="flex items-center justify-between gap-2">
                <p className="text-xs font-semibold text-white">{alert.title}</p>
                <SeverityBadge severity={alert.severity} />
              </div>
              {!compact && <p className="mt-0.5 text-[11px] text-slate-400">{alert.text}</p>}
              <p className="mt-0.5 text-[10px] text-slate-500">Valid until {alert.validUntil}</p>
            </div>
          </div>
        )
      })}
    </div>
  )
}
