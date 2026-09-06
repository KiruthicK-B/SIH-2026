import { AlertTriangle, Check } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import type { TimelineStep } from '@/data/applications'
import { cn, formatDate } from '@/lib/utils'

export function ApplicationTimeline({ steps }: { steps: TimelineStep[] }) {
  const { t } = useTranslation()
  return (
    <ol>
      {steps.map((step, idx) => {
        const isLast = idx === steps.length - 1
        return (
          <li key={step.label} className="relative flex gap-4 pb-8 last:pb-0">
            {!isLast && (
              <span
                className={cn(
                  'absolute left-[15px] top-8 h-[calc(100%-2rem)] w-px',
                  step.status === 'done' ? 'bg-success-600/40' : 'bg-gray-200',
                )}
              />
            )}
            <span
              className={cn(
                'z-10 flex h-8 w-8 shrink-0 items-center justify-center rounded-full border-2 text-xs font-semibold',
                step.status === 'done' && 'border-success-600 bg-success-600 text-white',
                step.status === 'active' && 'border-brand-500 bg-brand-50 text-brand-600',
                step.status === 'blocked' && 'border-warning-600 bg-warning-50 text-warning-600',
                step.status === 'pending' && 'border-gray-300 bg-white text-gray-300',
              )}
            >
              {step.status === 'done' ? (
                <Check className="h-4 w-4" />
              ) : step.status === 'blocked' ? (
                <AlertTriangle className="h-4 w-4" />
              ) : step.status === 'active' ? (
                <span className="h-2.5 w-2.5 rounded-full bg-brand-500" />
              ) : (
                <span className="h-2 w-2 rounded-full bg-gray-300" />
              )}
            </span>
            <div className="flex-1 pt-1">
              <div className="flex flex-wrap items-center gap-2">
                <p
                  className={cn(
                    'text-sm font-medium',
                    step.status === 'pending' ? 'text-gray-400' : 'text-gray-900',
                  )}
                >
                  {step.label}
                </p>
                {step.systemType && (
                  <span className="rounded-full border border-gray-200 px-2 py-0.5 text-[10px] font-medium text-gray-500">
                    {step.systemType}
                  </span>
                )}
              </div>
              <p className="mt-0.5 text-xs text-gray-500">{step.department}</p>
              {step.date && <p className="mt-0.5 text-xs text-gray-400">{formatDate(step.date)}</p>}
              {step.status === 'active' && !step.date && (
                <p className="mt-0.5 text-xs font-medium text-brand-600">{t('timeline.inProgress')}</p>
              )}
              {step.status === 'blocked' && (
                <p className="mt-1 text-xs font-medium text-warning-700">
                  {step.note ?? t('timeline.defaultBlockedNote')}
                </p>
              )}
            </div>
          </li>
        )
      })}
    </ol>
  )
}
