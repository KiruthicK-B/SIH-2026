import { AlertTriangle, CheckCircle2 } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Bar } from '@/components/charts/bar'
import { BarChart } from '@/components/charts/bar-chart'
import { BarXAxis } from '@/components/charts/bar-x-axis'
import { Grid } from '@/components/charts/grid'
import { ChartTooltip } from '@/components/charts/tooltip/chart-tooltip'
import { StatCard } from '@/components/shared/StatCard'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Progress } from '@/components/ui/Progress'
import type { SlaEntry } from '@/data/sla'
import { api } from '@/lib/api'
import { cn } from '@/lib/utils'

export function SlaTab() {
  const { t } = useTranslation()
  const [overallCompliance, setOverallCompliance] = useState(0)
  const [entries, setEntries] = useState<SlaEntry[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api
      .get<{ overallCompliance: number; entries: SlaEntry[] }>('/sla')
      .then((data) => {
        setOverallCompliance(data.overallCompliance)
        setEntries(data.entries)
      })
      .finally(() => setLoading(false))
  }, [])

  // Raw hours span 1h to 120h across steps, so a bar chart of hours would be
  // useless — % of target consumed is the comparable, chartable number.
  const chartData = useMemo(
    () =>
      entries.map((e) => ({
        name: e.label.length > 18 ? `${e.label.slice(0, 17)}…` : e.label,
        percentOfTarget: Math.round((e.currentHours / e.targetHours) * 100),
      })),
    [entries],
  )

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <StatCard icon={CheckCircle2} label={t('slaTab.overallCompliance')} value={`${overallCompliance}%`} tone="success" />
        <StatCard
          icon={AlertTriangle}
          label={t('slaTab.breachingSteps')}
          value={entries.filter((s) => !s.withinSla).length}
          tone="warning"
        />
      </div>

      <Card>
        <CardHeader>
          <CardTitle>{t('slaTab.percentOfTargetTitle')}</CardTitle>
        </CardHeader>
        <CardContent>
          <BarChart data={chartData} xDataKey="name" status={loading ? 'loading' : 'ready'} aspectRatio="3 / 1">
            <Grid horizontal />
            <Bar dataKey="percentOfTarget" fill="var(--chart-line-primary)" />
            <BarXAxis />
            <ChartTooltip />
          </BarChart>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="space-y-5 pt-5">
          {entries.map((entry) => (
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
                  {entry.withinSla ? t('slaTab.withinSla') : t('slaTab.slaBreach')}
                </span>
              </div>
              <p className="mb-1.5 text-xs text-gray-500">
                {t('slaTab.targetCurrent', { target: entry.targetLabel, current: entry.currentLabel })}
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
