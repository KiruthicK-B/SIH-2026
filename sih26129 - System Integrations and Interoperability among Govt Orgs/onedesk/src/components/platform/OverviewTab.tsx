import { Activity, CheckCircle2, Clock, Percent, Workflow, XCircle } from 'lucide-react'
import { DataFlowDiagram } from '@/components/operations/DataFlowDiagram'
import { StatCard } from '@/components/shared/StatCard'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { connectedInterfaces, connectedSystems, integrationHealth, recentEvents } from '@/data/integrations'
import { cn } from '@/lib/utils'

export function OverviewTab() {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        <StatCard icon={Activity} label="Requests Today" value={integrationHealth.apiRequests.toLocaleString('en-IN')} tone="brand" />
        <StatCard icon={CheckCircle2} label="Successful" value={integrationHealth.successful.toLocaleString('en-IN')} tone="success" />
        <StatCard icon={XCircle} label="Failed" value={integrationHealth.failed.toLocaleString('en-IN')} tone="warning" />
        <StatCard icon={Workflow} label="Active Workflows" value={integrationHealth.activeWorkflows.toLocaleString('en-IN')} tone="consent" />
        <StatCard icon={Percent} label="SLA Compliance" value={`${integrationHealth.slaCompliance}%`} tone="success" />
        <StatCard icon={Clock} label="Connected Systems" value={integrationHealth.connectedSystemsCount} tone="brand" />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle>Connected Systems</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {connectedSystems.map((sys) => (
              <div key={sys.name} className="flex items-center justify-between text-sm">
                <span className="text-gray-700">{sys.name}</span>
                <span className="flex items-center gap-1.5 text-xs font-medium text-success-600">
                  <span className="h-1.5 w-1.5 rounded-full bg-success-600" /> Connected
                </span>
              </div>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Connector Health</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {connectedInterfaces.map((iface) => (
              <div key={iface.name} className="flex items-center justify-between text-sm">
                <span className="text-gray-700">{iface.name}</span>
                <span
                  className={cn(
                    'text-xs font-medium',
                    iface.health === 'Healthy' && 'text-success-600',
                    iface.health === 'Degraded' && 'text-warning-600',
                    iface.health === 'Down' && 'text-danger-600',
                  )}
                >
                  {iface.health}
                </span>
              </div>
            ))}
            <div className="border-t border-gray-100 pt-3 text-xs text-gray-500">
              Avg. response time: <span className="font-medium text-gray-700">{integrationHealth.avgResponseMs} ms</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Recent Events</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {recentEvents.map((evt) => (
              <div key={evt.id} className="flex items-start gap-2.5">
                <Clock className="mt-0.5 h-3.5 w-3.5 shrink-0 text-gray-400" />
                <div className="min-w-0">
                  <p className="font-mono text-xs font-medium text-gray-900">{evt.type}</p>
                  <p className="text-xs text-gray-500">
                    {evt.actor} · {evt.timestamp}
                  </p>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Data Flow</CardTitle>
        </CardHeader>
        <CardContent>
          <DataFlowDiagram />
        </CardContent>
      </Card>
    </div>
  )
}
