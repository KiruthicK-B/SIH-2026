import type { LucideIcon } from 'lucide-react'
import { cn } from '@/lib/utils'

const toneClasses = {
  brand: 'bg-brand-50 text-brand-600',
  success: 'bg-success-50 text-success-600',
  warning: 'bg-warning-50 text-warning-600',
  danger: 'bg-danger-50 text-danger-600',
  info: 'bg-info-50 text-info-600',
}

export function StatCard({
  icon: Icon,
  label,
  value,
  tone = 'brand',
  sub,
}: {
  icon: LucideIcon
  label: string
  value: string | number
  tone?: keyof typeof toneClasses
  sub?: string
}) {
  return (
    <div className="rounded-xl border border-gray-200 bg-white p-4">
      <div className="flex items-center gap-3">
        <div className={cn('flex h-10 w-10 shrink-0 items-center justify-center rounded-lg', toneClasses[tone])}>
          <Icon className="h-5 w-5" />
        </div>
        <div className="min-w-0">
          <p className="text-xs font-medium text-gray-500">{label}</p>
          <p className="text-xl font-bold text-gray-900">{value}</p>
        </div>
      </div>
      {sub && <p className="mt-2 text-xs text-gray-400">{sub}</p>}
    </div>
  )
}
