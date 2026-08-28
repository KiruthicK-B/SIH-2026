import { ArrowRight, CheckCircle2 } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Progress } from '@/components/ui/Progress'
import { dataQualityByDepartment, dataQualityIssues, dataQualityMetrics } from '@/data/dataQuality'
import { commonModelLabel, sourceSystemLabel, transformationChecks, transformationExample } from '@/data/dataStandards'
import { masterIdentity } from '@/data/identity'

export function DataStandardsTab() {
  const maxIssueCount = Math.max(...dataQualityIssues.map((i) => i.count))
  const validPercent = (dataQualityMetrics.validRecords / dataQualityMetrics.recordsProcessed) * 100

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Data Transformation — Common Government Data Model</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="mb-4 text-sm text-gray-500">
            Two systems can describe the same citizen differently. Every record is mapped to one shared schema
            before it moves between departments.
          </p>
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-[1fr_auto_1fr] lg:items-center">
            <div className="rounded-md border border-gray-200 p-4">
              <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-400">{sourceSystemLabel}</p>
              <div className="space-y-2 font-mono text-xs text-gray-600">
                {transformationExample.map((f) => (
                  <p key={f.sourceField}>
                    {f.sourceField}: <span className="text-gray-900">{f.sourceValue}</span>
                  </p>
                ))}
              </div>
            </div>

            <ArrowRight className="mx-auto hidden h-5 w-5 text-gray-300 lg:block" />

            <div className="rounded-md border border-brand-500/20 bg-brand-50/40 p-4">
              <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-brand-700">{commonModelLabel}</p>
              <div className="space-y-2 font-mono text-xs text-gray-700">
                {transformationExample.map((f) => (
                  <p key={f.commonField}>
                    {f.commonField}: <span className="text-gray-900">{f.commonValue}</span>
                  </p>
                ))}
              </div>
            </div>
          </div>

          <div className="mt-4 flex flex-wrap gap-4">
            {transformationChecks.map((check) => (
              <span key={check} className="flex items-center gap-1.5 text-xs font-medium text-success-600">
                <CheckCircle2 className="h-3.5 w-3.5" /> {check}
              </span>
            ))}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Master Data — Identity Resolution</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="mb-4 text-sm text-gray-500">
            {masterIdentity.departmentIdentifiers.length} departmental identifiers resolved to 1 master citizen
            record.
          </p>
          <div className="flex flex-col items-center gap-4 lg:flex-row lg:justify-center">
            <div className="grid grid-cols-2 gap-2 lg:grid-cols-1">
              {masterIdentity.departmentIdentifiers.map((d) => (
                <div key={d.department} className="rounded-md border border-gray-200 px-3 py-2 text-xs">
                  <p className="text-gray-400">{d.department}</p>
                  <p className="font-mono font-medium text-gray-800">{d.identifier}</p>
                </div>
              ))}
            </div>
            <ArrowRight className="h-5 w-5 rotate-90 text-gray-300 lg:rotate-0" />
            <div className="rounded-md border border-consent-600/30 bg-consent-50 px-5 py-4 text-center">
              <p className="text-xs font-semibold uppercase tracking-wide text-consent-700">Master Citizen Record</p>
              <p className="mt-1 font-mono text-lg font-semibold text-consent-700">{masterIdentity.masterId}</p>
              <p className="mt-0.5 text-xs text-consent-700/80">{masterIdentity.citizenName}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Data Quality — Overall Validity</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="mb-2 text-2xl font-semibold text-gray-900">{validPercent.toFixed(1)}%</p>
            <Progress value={validPercent} barClassName="bg-success-600" />
            <p className="mt-2 text-xs text-gray-500">
              {dataQualityMetrics.validRecords.toLocaleString('en-IN')} of{' '}
              {dataQualityMetrics.recordsProcessed.toLocaleString('en-IN')} records passed validation before
              crossing a department boundary
            </p>
            <div className="mt-4 grid grid-cols-2 gap-3 border-t border-gray-100 pt-4 text-xs">
              <div>
                <p className="text-gray-400">Warnings</p>
                <p className="font-semibold text-gray-900">{dataQualityMetrics.warnings.toLocaleString('en-IN')}</p>
              </div>
              <div>
                <p className="text-gray-400">Errors</p>
                <p className="font-semibold text-gray-900">{dataQualityMetrics.validationErrors.toLocaleString('en-IN')}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Common Issues Caught Before Exchange</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {dataQualityIssues.map((issue) => (
              <div key={issue.label}>
                <div className="mb-1 flex items-center justify-between text-sm">
                  <span className="text-gray-700">{issue.label}</span>
                  <span className="font-medium text-gray-900">{issue.count}</span>
                </div>
                <Progress value={(issue.count / maxIssueCount) * 100} barClassName="bg-warning-600" />
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Validity Rate by Department</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {dataQualityByDepartment.map((d) => (
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
