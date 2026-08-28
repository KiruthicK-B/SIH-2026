import { cn } from '@/lib/utils'
import type { DRSeverity, QualityLevel } from '@/lib/types'

const toneClasses: Record<string, string> = {
  gray: 'bg-gray-100 text-gray-700',
  green: 'bg-success-100 text-success-700',
  amber: 'bg-warning-100 text-warning-700',
  red: 'bg-danger-100 text-danger-700',
  blue: 'bg-brand-100 text-brand-700',
}

export function Badge({ tone = 'gray', className, children }: { tone?: keyof typeof toneClasses; className?: string; children: React.ReactNode }) {
  return (
    <span className={cn('inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold', toneClasses[tone], className)}>
      {children}
    </span>
  )
}

export function ReferableBadge({ referable }: { referable: boolean }) {
  return <Badge tone={referable ? 'red' : 'green'}>{referable ? 'Referable' : 'Non-Referable'}</Badge>
}

export function QualityBadge({ level }: { level: QualityLevel }) {
  const tone = level === 'Good' ? 'green' : level === 'Borderline' ? 'amber' : 'red'
  return <Badge tone={tone}>{level}</Badge>
}

export function SeverityBadge({ severity, grade }: { severity: DRSeverity; grade: number }) {
  const tone = grade === 0 ? 'green' : grade <= 1 ? 'blue' : grade <= 2 ? 'amber' : 'red'
  return (
    <Badge tone={tone}>
      Grade {grade} · {severity}
    </Badge>
  )
}

export function ReviewStatusBadge({ status }: { status: 'Pending Review' | 'Reviewed' | 'Not Required' }) {
  const tone = status === 'Pending Review' ? 'amber' : status === 'Reviewed' ? 'blue' : 'gray'
  return <Badge tone={tone}>{status}</Badge>
}
