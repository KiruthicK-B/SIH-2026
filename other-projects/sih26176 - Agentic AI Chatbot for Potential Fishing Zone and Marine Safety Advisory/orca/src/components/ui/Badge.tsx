import { cn } from '@/lib/utils'
import type { AlertSeverity, PFZBand, SafetyCategory } from '@/data/types'

const toneClasses = {
  gray: 'bg-navy-600 text-slate-300',
  green: 'bg-success-500/15 text-success-500 border border-success-500/30',
  amber: 'bg-warning-500/15 text-warning-500 border border-warning-500/30',
  red: 'bg-danger-500/15 text-danger-500 border border-danger-500/30',
  cyan: 'bg-cyan-500/15 text-cyan-400 border border-cyan-500/30',
}

export function Badge({ tone = 'gray', className, children }: { tone?: keyof typeof toneClasses; className?: string; children: React.ReactNode }) {
  return <span className={cn('inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-[11px] font-semibold', toneClasses[tone], className)}>{children}</span>
}

export function SafetyBadge({ category }: { category: SafetyCategory }) {
  const tone = category === 'Safe' ? 'green' : category === 'Caution' ? 'amber' : 'red'
  return <Badge tone={tone}>{category}</Badge>
}

export function SeverityBadge({ severity }: { severity: AlertSeverity | string }) {
  const tone = severity === 'High' ? 'red' : severity === 'Medium' ? 'amber' : 'green'
  return <Badge tone={tone}>{severity}</Badge>
}

export function PFZBandBadge({ band }: { band: PFZBand }) {
  const tone = band === 'High' ? 'red' : band === 'Moderate' ? 'amber' : 'green'
  return <Badge tone={tone}>{band}</Badge>
}
