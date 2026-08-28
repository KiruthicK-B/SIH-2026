import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Progress } from '@/components/ui/Progress'
import { dataQualityByDepartment, dataQualityIssues, dataQualityMetrics } from '@/data/dataQuality'

export function DataQualityTab() {
  const maxIssueCount = Math.max(...dataQualityIssues.map((i) => i.count))
  const validPercent = (dataQualityMetrics.validRecords / dataQualityMetrics.recordsProcessed) * 100

  return (
    <div className="space-y-6">
      <p className="text-sm text-gray-500">
        Every record is checked at the connector boundary before it moves between departments — bad data never
        gets the chance to spread.
      </p>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Overall Validity</CardTitle>
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
