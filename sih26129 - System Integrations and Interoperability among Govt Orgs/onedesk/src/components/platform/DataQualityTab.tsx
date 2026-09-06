import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Bar } from '@/components/charts/bar'
import { BarChart } from '@/components/charts/bar-chart'
import { BarYAxis } from '@/components/charts/bar-y-axis'
import { Grid } from '@/components/charts/grid'
import { Ring } from '@/components/charts/ring'
import { RingCenter } from '@/components/charts/ring-center'
import { RingChart } from '@/components/charts/ring-chart'
import { ChartTooltip } from '@/components/charts/tooltip/chart-tooltip'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Progress } from '@/components/ui/Progress'
import type { DataQualityIssue, DepartmentDataQuality } from '@/data/dataQuality'
import { api } from '@/lib/api'

interface DataQualityMetrics {
  recordsProcessed: number
  validRecords: number
  warnings: number
  validationErrors: number
}

export function DataQualityTab() {
  const { t } = useTranslation()
  const [metrics, setMetrics] = useState<DataQualityMetrics | null>(null)
  const [issues, setIssues] = useState<DataQualityIssue[]>([])
  const [byDepartment, setByDepartment] = useState<DepartmentDataQuality[]>([])

  useEffect(() => {
    api
      .get<{ metrics: DataQualityMetrics; issues: DataQualityIssue[]; byDepartment: DepartmentDataQuality[] }>('/data-quality')
      .then((data) => {
        setMetrics(data.metrics)
        setIssues(data.issues)
        setByDepartment(data.byDepartment)
      })
  }, [])

  if (!metrics) return null

  const validPercent = (metrics.validRecords / metrics.recordsProcessed) * 100

  const rings = [
    { label: t('dataQualityTab.ringValid'), value: metrics.validRecords, maxValue: metrics.recordsProcessed, color: '#16803c' },
    { label: t('dataQualityTab.ringWarnings'), value: metrics.warnings, maxValue: metrics.recordsProcessed, color: '#b25e09' },
    { label: t('dataQualityTab.ringErrors'), value: metrics.validationErrors, maxValue: metrics.recordsProcessed, color: '#c0262c' },
  ]

  return (
    <div className="space-y-6">
      <p className="text-sm text-gray-500">{t('dataQualityTab.intro')}</p>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2 lg:[&>*]:min-w-0">
        <Card>
          <CardHeader>
            <CardTitle>{t('dataQualityTab.overallValidityTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="flex min-w-0 flex-col items-center gap-4">
            <RingChart data={rings} size={160} strokeWidth={12}>
              {rings.map((r, i) => (
                <Ring key={r.label} index={i} />
              ))}
              <RingCenter defaultLabel={t('dataQualityTab.recordsChecked')} />
            </RingChart>
            <div className="grid w-full grid-cols-3 gap-3 border-t border-gray-100 pt-4 text-center text-xs">
              {rings.map((r) => (
                <div key={r.label}>
                  <p className="flex items-center justify-center gap-1 text-gray-400">
                    <span className="h-2 w-2 rounded-full" style={{ backgroundColor: r.color }} />
                    {r.label}
                  </p>
                  <p className="mt-0.5 font-semibold text-gray-900">{r.value.toLocaleString('en-IN')}</p>
                </div>
              ))}
            </div>
            <p className="text-xs text-gray-500">
              {t('dataQualityTab.validitySummary', {
                valid: metrics.validRecords.toLocaleString('en-IN'),
                total: metrics.recordsProcessed.toLocaleString('en-IN'),
                percent: validPercent.toFixed(1),
              })}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t('dataQualityTab.commonIssuesTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="min-w-0">
            <BarChart
              data={issues.map((i) => ({ label: i.label, count: i.count }))}
              xDataKey="label"
              orientation="horizontal"
              aspectRatio="4 / 3"
              margin={{ left: 160, right: 24, top: 16, bottom: 16 }}
            >
              <Grid vertical />
              <Bar dataKey="count" fill="#b25e09" />
              <BarYAxis />
              <ChartTooltip />
            </BarChart>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>{t('dataQualityTab.validityByDepartmentTitle')}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {byDepartment.map((d) => (
            <div key={d.department}>
              <div className="mb-1 flex items-center justify-between text-sm">
                <span className="text-gray-700">{d.department}</span>
                <span className="font-medium text-gray-900">{d.validRate}%</span>
              </div>
              <Progress value={d.validRate} />
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  )
}
