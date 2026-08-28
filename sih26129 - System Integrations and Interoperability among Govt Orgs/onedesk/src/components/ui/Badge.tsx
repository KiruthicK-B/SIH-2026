import type { HTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

export type BadgeTone = 'success' | 'warning' | 'danger' | 'info' | 'consent' | 'neutral'

interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  tone?: BadgeTone
}

const toneClasses: Record<BadgeTone, string> = {
  success: 'bg-success-50 text-success-700 ring-1 ring-inset ring-success-600/20',
  warning: 'bg-warning-50 text-warning-700 ring-1 ring-inset ring-warning-600/20',
  danger: 'bg-danger-50 text-danger-700 ring-1 ring-inset ring-danger-600/20',
  info: 'bg-info-50 text-info-700 ring-1 ring-inset ring-info-600/20',
  consent: 'bg-consent-50 text-consent-700 ring-1 ring-inset ring-consent-600/20',
  neutral: 'bg-gray-100 text-gray-700 ring-1 ring-inset ring-gray-500/10',
}

export function Badge({ className, tone = 'neutral', ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium',
        toneClasses[tone],
        className,
      )}
      {...props}
    />
  )
}
