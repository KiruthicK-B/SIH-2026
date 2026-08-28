import type { LucideIcon } from 'lucide-react'
import { Link } from 'react-router-dom'
import { cn } from '@/lib/utils'

interface StatCardProps {
  icon: LucideIcon
  label: string
  value: string | number
  tone?: 'brand' | 'warning' | 'success' | 'consent'
  to?: string
  linkLabel?: string
}

const toneClasses = {
  brand: 'bg-brand-50 text-brand-600',
  warning: 'bg-warning-50 text-warning-600',
  success: 'bg-success-50 text-success-600',
  consent: 'bg-consent-50 text-consent-600',
}

export function StatCard({ icon: Icon, label, value, tone = 'brand', to, linkLabel }: StatCardProps) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white p-5 shadow-xs">
      <div className="flex items-center gap-3">
        <div className={cn('flex h-10 w-10 shrink-0 items-center justify-center rounded-md', toneClasses[tone])}>
          <Icon className="h-5 w-5" />
        </div>
        <div>
          <p className="text-sm text-gray-500">{label}</p>
          <p className="text-2xl font-semibold text-gray-900">{value}</p>
        </div>
      </div>
      {to && (
        <Link to={to} className="mt-3 inline-block text-xs font-medium text-brand-600 hover:text-brand-700">
          {linkLabel ?? 'View all'} →
        </Link>
      )}
    </div>
  )
}
