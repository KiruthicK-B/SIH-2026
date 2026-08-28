import { Card, CardContent } from '@/components/ui/Card'
import { Progress } from '@/components/ui/Progress'
import { departments } from '@/data/departments'

const stages = ['Integrate', 'Standardize', 'Modernize', 'Migrate', 'Retire Legacy']

function stageIndex(percent: number) {
  if (percent >= 100) return 4
  if (percent >= 75) return 3
  if (percent >= 40) return 2
  if (percent >= 15) return 1
  return 0
}

export function ModernizationTab() {
  return (
    <div className="space-y-4">
      <p className="text-sm text-gray-500">
        Legacy systems aren't replaced overnight. Each department moves through the same pipeline at its own
        pace, without ever blocking the interoperability layer above it.
      </p>

      <Card>
        <CardContent className="space-y-6 pt-5">
          {departments
            .filter((d) => d.name !== 'Identity Service')
            .map((d) => {
              const active = stageIndex(d.modernization.percent)
              return (
                <div key={d.id}>
                  <div className="mb-1.5 flex flex-wrap items-center justify-between gap-2">
                    <div>
                      <p className="text-sm font-medium text-gray-900">{d.name}</p>
                      <p className="text-xs text-gray-500">
                        Current: {d.interfaceType} → Target: {d.modernization.target}
                      </p>
                    </div>
                    <span className="text-xs font-medium text-gray-500">{d.modernization.status}</span>
                  </div>
                  <Progress value={d.modernization.percent} />
                  <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1">
                    {stages.map((stage, idx) => (
                      <span
                        key={stage}
                        className={idx <= active ? 'text-[11px] font-medium text-brand-700' : 'text-[11px] text-gray-300'}
                      >
                        {stage}
                        {idx < stages.length - 1 && <span className="ml-4 text-gray-200">/</span>}
                      </span>
                    ))}
                  </div>
                </div>
              )
            })}
        </CardContent>
      </Card>
    </div>
  )
}
