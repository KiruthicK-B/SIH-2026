import { Activity, CheckCircle2, Clock, Database, Network, Percent, ShieldCheck, Workflow, XCircle } from 'lucide-react'
import { motion, type Variants } from 'motion/react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Ring } from '@/components/charts/ring'
import { RingCenter } from '@/components/charts/ring-center'
import { RingChart } from '@/components/charts/ring-chart'
import Loader from '@/components/kokonutui/loader'
import { DataFlowDiagram } from '@/components/operations/DataFlowDiagram'
import { ModernizationTab } from '@/components/platform/ModernizationTab'
import { StatCard } from '@/components/shared/StatCard'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { useApplications } from '@/context/ApplicationsContext'
import { defaultProtocolStyle, protocolStyle } from '@/data/dataMapping'
import type { IntegrationEvent } from '@/data/integrations'
import { api } from '@/lib/api'
import { cn } from '@/lib/utils'

interface ConnectorRegistryRow {
  name: string
  protocol: string
  health: string
  killSwitchEnabled: boolean
}

interface TrafficSummary {
  apiRequests: number
  successful: number
  failed: number
  avgResponseMs: number
}

const statCardVariants: Variants = {
  hidden: { opacity: 0, y: 10 },
  visible: (i: number) => ({ opacity: 1, y: 0, transition: { delay: i * 0.05, duration: 0.35, ease: [0.4, 0, 0.2, 1] } }),
}

interface OverviewTabProps {
  /** Jumps the parent Tabs to another top-level section — wired to the quick-link
   * tiles below so Overview actually orients someone landing on /platform instead
   * of just being the first of five equally-weighted tabs. */
  onNavigate?: (tab: string) => void
  isAdminOnly?: boolean
}

export function OverviewTab({ onNavigate, isAdminOnly }: OverviewTabProps) {
  const { t } = useTranslation()
  const { applications } = useApplications()
  const [connectors, setConnectors] = useState<ConnectorRegistryRow[]>([])
  const [traffic, setTraffic] = useState<TrafficSummary>({ apiRequests: 0, successful: 0, failed: 0, avgResponseMs: 0 })
  const [recentEvents, setRecentEvents] = useState<IntegrationEvent[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.get<ConnectorRegistryRow[]>('/admin/connectors').then(setConnectors),
      api.get<TrafficSummary>('/admin/traffic-summary').then(setTraffic),
      api.get<IntegrationEvent[]>('/admin/recent-events').then(setRecentEvents),
    ]).finally(() => setLoading(false))
  }, [])

  // Computed live from the same Postgres data driving every other screen.
  const activeWorkflows = applications.filter((a) => a.status === 'In Progress' || a.status === 'Under Review').length
  const completedCount = applications.filter((a) => a.status === 'Completed' || a.status === 'Approved').length
  const slaCompliance = applications.length > 0 ? Math.round((completedCount / applications.length) * 100) : 0

  const protocols = Array.from(new Set(connectors.map((c) => c.protocol)))

  const protocolRings = protocols.map((p) => ({
    label: p,
    value: connectors.filter((c) => c.protocol === p).length,
    maxValue: connectors.length,
    color: (protocolStyle[p] ?? defaultProtocolStyle).stroke,
  }))

  if (loading) {
    return (
      <Loader size="sm" title={t('overviewTab.loaderTitle')} subtitle={t('overviewTab.loaderSubtitle')} />
    )
  }

  const statCards = [
    { icon: Activity, label: t('overviewTab.requestsToday'), value: traffic.apiRequests.toLocaleString('en-IN'), tone: 'brand' as const },
    { icon: CheckCircle2, label: t('overviewTab.successful'), value: traffic.successful.toLocaleString('en-IN'), tone: 'success' as const },
    { icon: XCircle, label: t('overviewTab.failed'), value: traffic.failed.toLocaleString('en-IN'), tone: 'warning' as const },
    { icon: Workflow, label: t('overviewTab.activeWorkflows'), value: activeWorkflows, tone: 'consent' as const },
    { icon: Percent, label: t('overviewTab.slaCompliance'), value: `${slaCompliance}%`, tone: 'success' as const },
    { icon: Clock, label: t('overviewTab.connectedSystems'), value: connectors.length, tone: 'brand' as const },
  ]

  return (
    <div className="space-y-6">
      <div className="rounded-md border border-gray-200 bg-gray-50/60 px-4 py-3">
        <p className="text-sm text-gray-700">
          <span className="font-semibold text-gray-900">{t('overviewTab.systemsIntegrated', { count: connectors.length })}</span>{' '}
          {t('overviewTab.systemsIntegratedSuffix')}
        </p>
        {protocols.length > 0 && (
          <div className="mt-2 flex flex-wrap gap-1.5">
            {protocols.map((p) => (
              <span key={p} className="rounded-full bg-white px-2.5 py-0.5 text-[11px] font-medium text-gray-600 ring-1 ring-gray-200">
                {p}
              </span>
            ))}
          </div>
        )}
      </div>

      {onNavigate && (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          {isAdminOnly && (
            <QuickLinkTile
              icon={Network}
              label={t('governmentPlatform.tabInteroperability')}
              onClick={() => onNavigate('interoperability')}
            />
          )}
          <QuickLinkTile icon={ShieldCheck} label={t('governmentPlatform.tabDataConsent')} onClick={() => onNavigate('dataConsent')} />
          <QuickLinkTile icon={Workflow} label={t('governmentPlatform.tabOperations')} onClick={() => onNavigate('operations')} />
          {isAdminOnly && (
            <QuickLinkTile icon={Database} label={t('governmentPlatform.tabRegistry')} onClick={() => onNavigate('registry')} />
          )}
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        {statCards.map((s, i) => (
          <motion.div key={s.label} custom={i} initial="hidden" animate="visible" variants={statCardVariants}>
            <StatCard icon={s.icon} label={s.label} value={s.value} tone={s.tone} />
          </motion.div>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-4">
        <Card>
          <CardHeader>
            <CardTitle>{t('overviewTab.connectedSystems')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {connectors.map((c) => (
              <div key={c.name} className="flex items-center justify-between text-sm">
                <span className="text-gray-700">{c.name}</span>
                <span
                  className={cn(
                    'flex items-center gap-1.5 text-xs font-medium',
                    c.killSwitchEnabled ? 'text-danger-600' : 'text-success-600',
                  )}
                >
                  <span className={cn('h-1.5 w-1.5 rounded-full', c.killSwitchEnabled ? 'bg-danger-600' : 'bg-success-600')} />
                  {c.killSwitchEnabled ? t('overviewTab.down') : t('overviewTab.connected')}
                </span>
              </div>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t('overviewTab.connectorHealthTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {connectors.map((c) => (
              <div key={c.name} className="flex items-center justify-between text-sm">
                <span className="text-gray-700">
                  {c.name} <span className="text-gray-400">({c.protocol})</span>
                </span>
                <span
                  className={cn(
                    'text-xs font-medium',
                    c.health === 'Healthy' && 'text-success-600',
                    c.health === 'Degraded' && 'text-warning-600',
                    c.health === 'Down' && 'text-danger-600',
                  )}
                >
                  {t(`status.${c.health}`, { defaultValue: c.health })}
                </span>
              </div>
            ))}
            <div className="border-t border-gray-100 pt-3 text-xs text-gray-500">
              {t('overviewTab.avgResponseTime')} <span className="font-medium text-gray-700">{t('overviewTab.msUnit', { ms: traffic.avgResponseMs })}</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t('overviewTab.protocolDistributionTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col items-center gap-3">
            {protocolRings.length > 0 ? (
              <>
                <RingChart data={protocolRings} size={140} strokeWidth={10}>
                  {protocolRings.map((r, i) => (
                    <Ring key={r.label} index={i} />
                  ))}
                  <RingCenter defaultLabel={t('overviewTab.liveConnectors')} />
                </RingChart>
                <div className="flex flex-wrap justify-center gap-x-3 gap-y-1">
                  {protocolRings.map((r) => (
                    <span key={r.label} className="flex items-center gap-1.5 text-[11px] text-gray-500">
                      <span className="h-2 w-2 rounded-full" style={{ backgroundColor: r.color }} />
                      {r.label} ({r.value})
                    </span>
                  ))}
                </div>
              </>
            ) : (
              <p className="py-8 text-xs text-gray-400">{t('overviewTab.noLiveConnectors')}</p>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t('overviewTab.recentEventsTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {recentEvents.map((evt) => (
              <div key={evt.id} className="flex items-start gap-2.5">
                <Clock className="mt-0.5 h-3.5 w-3.5 shrink-0 text-gray-400" />
                <div className="min-w-0">
                  <p className="font-mono text-xs font-medium text-gray-900">{evt.type}</p>
                  <p className="text-xs text-gray-500">
                    {evt.actor} · {new Date(evt.timestamp).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                  </p>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>{t('overviewTab.dataFlowTitle')}</CardTitle>
        </CardHeader>
        <CardContent>
          <DataFlowDiagram />
        </CardContent>
      </Card>

      <div>
        <h3 className="mb-3 text-sm font-semibold text-gray-900">{t('governmentPlatform.tabModernizationHeading')}</h3>
        <ModernizationTab />
      </div>
    </div>
  )
}

function QuickLinkTile({ icon: Icon, label, onClick }: { icon: typeof Network; label: string; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex items-center gap-2.5 rounded-md border border-gray-200 bg-white px-3.5 py-3 text-left transition-colors hover:border-brand-300 hover:bg-brand-50/40"
    >
      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-gray-100 text-gray-500">
        <Icon className="h-4 w-4" />
      </span>
      <span className="text-sm font-medium text-gray-800">{label}</span>
    </button>
  )
}
