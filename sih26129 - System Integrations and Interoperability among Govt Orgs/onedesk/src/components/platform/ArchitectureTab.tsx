import {
  Bell,
  Building2,
  Database,
  FileText,
  KeyRound,
  LayoutDashboard,
  Network,
  Server,
  ShieldCheck,
  User,
  UserCheck,
} from 'lucide-react'
import { motion } from 'motion/react'
import { useEffect, useMemo, useState } from 'react'
import { Trans, useTranslation } from 'react-i18next'
import { Card, CardContent } from '@/components/ui/Card'
import { defaultProtocolStyle, protocolStyle } from '@/data/dataMapping'
import { api } from '@/lib/api'
import { cn } from '@/lib/utils'

interface ArchNode {
  id: string
  name: string
  role?: string
  framework?: string
  port: number | null
  healthy: boolean
  routes?: string[]
  source?: string
}

interface ArchAdapter extends ArchNode {
  protocol: string
  health: string
  killSwitchEnabled: boolean
  route: string | null
}

interface ArchDatabase {
  id: string
  name: string
  role: string
  usedBy: string[]
  source: string
}

interface ArchEdge {
  from: string
  to: string
  protocol: string
  label: string
  source: string
}

interface ArchitectureResponse {
  identityProvider: ArchNode
  gateway: ArchNode & { routes: string[] }
  services: ArchNode[]
  databases: ArchDatabase[]
  adapters: ArchAdapter[]
  edges: ArchEdge[]
}

// Layout is presentation-only (same category as Data Mapping tab's NODE_POSITIONS)
// — real facts (which nodes exist, which edges are real) all come from /architecture.
// Cards are 208px wide (w-52); with the 1400px canvas below, a column needs to sit
// at least ~8% in from either edge to avoid the card clipping off-screen.
const POS: Record<string, { x: number; y: number }> = {
  'Identity Service': { x: 9, y: 8 },
  'Business Registry': { x: 9, y: 26 },
  'Revenue Department': { x: 9, y: 44 },
  'Municipal Corporation': { x: 9, y: 62 },
  'License Authority': { x: 9, y: 88 },
  // Off the direct path of every adapter→core-api line (adapters call core-api
  // directly, never through Kong — see the "Why a gateway" card below). Sitting
  // below the whole adapter column (which spans y 8-88) keeps Kong clear of that
  // entire diagonal fan instead of intersecting it partway.
  kong: { x: 28, y: 93 },
  'core-api': { x: 50, y: 26 },
  'mdm-service': { x: 50, y: 62 },
  'db-core-api': { x: 74, y: 8 },
  keycloak: { x: 74, y: 44 },
  'db-municipal': { x: 74, y: 80 },
  frontend: { x: 91, y: 44 },
}

// Gentle quadratic bend so many lines converging on the same node (5 adapters into
// core-api) fan out visually instead of overlapping as straight, indistinguishable
// segments — a standard declutter technique for many-to-one diagram edges.
function curvedPath(from: { x: number; y: number }, to: { x: number; y: number }) {
  const mx = (from.x + to.x) / 2
  const my = (from.y + to.y) / 2
  const dx = to.x - from.x
  const dy = to.y - from.y
  const len = Math.hypot(dx, dy) || 1
  const bend = 6
  const cx = mx + (-dy / len) * bend
  const cy = my + (dx / len) * bend
  return { d: `M ${from.x} ${from.y} Q ${cx} ${cy} ${to.x} ${to.y}`, cx, cy }
}

function styleForProtocol(protocol: string) {
  return protocolStyle[protocol] ?? defaultProtocolStyle
}

export function ArchitectureTab() {
  const { t } = useTranslation()
  const [data, setData] = useState<ArchitectureResponse | null>(null)
  const [hoveredId, setHoveredId] = useState<string | null>(null)
  const [selectedId, setSelectedId] = useState<string | null>(null)

  useEffect(() => {
    api.get<ArchitectureResponse>('/architecture').then(setData)
  }, [])

  const nodes = useMemo((): (ArchNode | ArchAdapter)[] => {
    if (!data) return []
    return [
      { id: 'frontend', name: 'Frontend', role: 'React SPA', healthy: true, port: 5190 },
      { ...data.identityProvider },
      { ...data.gateway },
      ...data.services,
      ...data.databases.map((d) => ({ id: d.id, name: d.name, role: d.role, healthy: true, port: null, source: d.source })),
      ...data.adapters,
    ]
  }, [data])

  // Direct connections only (1-hop, both directions) — predictable and honest:
  // never implies a multi-hop path that doesn't correspond to an actual call.
  const activeId = selectedId ?? hoveredId
  const highlightedEdgeKeys = useMemo(() => {
    if (!data || !activeId) return null
    const keys = new Set<string>()
    for (const e of data.edges) {
      if (e.from === activeId || e.to === activeId) keys.add(`${e.from}->${e.to}`)
    }
    return keys
  }, [data, activeId])

  const highlightedNodeIds = useMemo(() => {
    if (!data || !activeId) return null
    const ids = new Set<string>([activeId])
    for (const e of data.edges) {
      if (e.from === activeId) ids.add(e.to)
      if (e.to === activeId) ids.add(e.from)
    }
    return ids
  }, [data, activeId])

  if (!data) return null

  const selected = nodes.find((n) => n.id === selectedId) ?? null
  const selectedAdapter = data.adapters.find((a) => a.id === selectedId)
  const selectedEdgesIn = selectedId ? data.edges.filter((e) => e.to === selectedId) : []
  const selectedEdgesOut = selectedId ? data.edges.filter((e) => e.from === selectedId) : []

  const protocolCount = new Set(data.adapters.map((a) => a.protocol)).size

  return (
    <div className="space-y-4">
      <p className="text-sm text-gray-500">{t('architectureTab.intro')}</p>

      {/* Summary strip — every number below is derived from the data fetched above, not hardcoded */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
        <SummaryStat label={t('architectureTab.statConnectedSystems')} value={data.adapters.length} />
        <SummaryStat label={t('architectureTab.statProtocols')} value={protocolCount} />
        <SummaryStat label={t('architectureTab.statCoreServices')} value={data.services.length} />
        <SummaryStat label={t('architectureTab.statDataStores')} value={data.databases.length} />
        <SummaryStat label={t('architectureTab.statGateway')} value={`Kong :${data.gateway.port}`} />
        <SummaryStat label={t('architectureTab.statIdentityProvider')} value={`${data.identityProvider.name} :${data.identityProvider.port}`} />
      </div>

      <div className="flex flex-wrap items-center gap-3 text-xs text-gray-500">
        {Object.entries(protocolStyle).map(([key, s]) => (
          <span key={key} className="flex items-center gap-1.5">
            <span className="inline-block h-0 w-4 border-t-2" style={{ borderColor: s.stroke, borderStyle: s.dashed ? 'dashed' : 'solid' }} />
            {s.label}
          </span>
        ))}
        <span className="ml-auto text-gray-400">{t('architectureTab.hoverHint')}</span>
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[1fr_320px]">
        <Card className="relative overflow-hidden">
          <CardContent className="p-0" onClick={() => setSelectedId(null)}>
            <div className="relative h-[560px] w-full overflow-x-auto overflow-y-hidden bg-gray-50/50">
              <div className="relative h-full min-w-[1400px]">
                <svg viewBox="0 0 100 100" preserveAspectRatio="none" className="absolute inset-0 h-full w-full">
                  {data.edges.map((e) => {
                    const from = POS[e.from]
                    const to = POS[e.to]
                    if (!from || !to) return null
                    const style = styleForProtocol(e.protocol)
                    const key = `${e.from}->${e.to}`
                    const dimmed = highlightedEdgeKeys ? !highlightedEdgeKeys.has(key) : false
                    const active = highlightedEdgeKeys?.has(key) ?? false
                    // The animated flow always travels left→right on screen (lower x
                    // to higher x) regardless of which side is the logical caller —
                    // that's a request-direction fact for the detail panel, not a
                    // screen-direction fact for the animation.
                    const leftPoint = from.x <= to.x ? from : to
                    const rightPoint = from.x <= to.x ? to : from
                    const basePath = curvedPath(from, to)
                    const flowPath = curvedPath(leftPoint, rightPoint)
                    return (
                      <g key={key}>
                        <path
                          d={basePath.d}
                          fill="none"
                          stroke={style.stroke}
                          strokeWidth={active ? 0.5 : 0.3}
                          opacity={dimmed ? 0.12 : 0.55}
                          vectorEffect="non-scaling-stroke"
                        />
                        {/* Data-flow particles — always drift left→right, subtle; only bright on the active path */}
                        <motion.path
                          d={flowPath.d}
                          fill="none"
                          stroke={style.stroke}
                          strokeWidth={0.6}
                          strokeLinecap="round"
                          strokeDasharray="0.6 4"
                          opacity={dimmed ? 0.08 : active ? 0.95 : 0.35}
                          vectorEffect="non-scaling-stroke"
                          animate={{ strokeDashoffset: [0, -9.2] }}
                          transition={{ duration: active ? 1.1 : 2.2, repeat: Infinity, ease: 'linear' }}
                        />
                      </g>
                    )
                  })}
                </svg>

                {nodes.map((n) => {
                  const pos = POS[n.id]
                  if (!pos) return null
                  const isAdapter = 'protocol' in n
                  const style = isAdapter ? styleForProtocol((n as ArchAdapter).protocol) : null
                  const dimmed = highlightedNodeIds ? !highlightedNodeIds.has(n.id) : false
                  const isActive = activeId === n.id
                  const Icon =
                    n.id === 'frontend'
                      ? Network
                      : n.id === 'keycloak'
                        ? KeyRound
                        : n.id.startsWith('db-')
                          ? Database
                          : n.id === 'kong'
                            ? Network
                            : isAdapter
                              ? Building2
                              : Server
                  return (
                    <button
                      key={n.id}
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation()
                        setSelectedId((prev) => (prev === n.id ? null : n.id))
                      }}
                      onMouseEnter={() => setHoveredId(n.id)}
                      onMouseLeave={() => setHoveredId((p) => (p === n.id ? null : p))}
                      className={cn(
                        'absolute w-52 -translate-x-1/2 -translate-y-1/2 rounded-md border bg-white px-3 py-2 text-left shadow-sm transition-opacity',
                        isActive ? 'border-brand-500 ring-1 ring-brand-500' : 'border-gray-200 hover:border-gray-300',
                        dimmed && 'opacity-25',
                      )}
                      style={{ left: `${pos.x}%`, top: `${pos.y}%`, borderLeftColor: style?.stroke, borderLeftWidth: style ? 3 : undefined }}
                    >
                      <div className="flex items-start justify-between gap-1.5">
                        <p className="flex items-center gap-1.5 text-xs font-semibold leading-snug text-gray-900">
                          <Icon className="h-3.5 w-3.5 shrink-0 text-gray-400" />
                          <span>{n.name}</span>
                        </p>
                        <span className={cn('mt-0.5 h-1.5 w-1.5 shrink-0 rounded-full', n.healthy ? 'bg-success-600' : 'bg-danger-600')} />
                      </div>
                      <p className="mt-0.5 truncate text-[10px] text-gray-500">
                        {style ? style.label : n.role}
                        {n.port ? ` · :${n.port}` : ''}
                      </p>
                    </button>
                  )
                })}
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="h-fit">
          <CardContent className="pt-5">
            {!selected ? (
              <div className="flex flex-col items-center gap-2 py-14 text-center text-gray-400">
                <Server className="h-8 w-8" />
                <p className="text-sm">{t('architectureTab.selectNodePrompt')}</p>
              </div>
            ) : (
              <div className="space-y-4">
                <div>
                  <p className="text-sm font-semibold text-gray-900">{selected.name}</p>
                  {selected.role && <p className="mt-1 text-xs text-gray-500">{selected.role}</p>}
                  <div className="mt-2 flex items-center gap-1.5">
                    <span className={cn('h-1.5 w-1.5 rounded-full', selected.healthy ? 'bg-success-600' : 'bg-danger-600')} />
                    <span className="text-xs font-medium text-gray-600">{selected.healthy ? t('status.Healthy') : t('status.Down')}</span>
                  </div>
                </div>

                <Section title={t('architectureTab.sectionServiceDetails')}>
                  {selected.port && <DetailRow label={t('architectureTab.port')} value={String(selected.port)} />}
                  {selectedAdapter && <DetailRow label={t('architectureTab.protocol')} value={selectedAdapter.protocol} />}
                  {selectedAdapter?.route && <DetailRow label={t('architectureTab.routeHitByCoreApi')} value={selectedAdapter.route} mono />}
                  {selected.source && <DetailRow label={t('architectureTab.source')} value={selected.source} mono />}
                </Section>

                {(selectedEdgesIn.length > 0 || selectedEdgesOut.length > 0) && (
                  <Section title={t('architectureTab.sectionConnections')}>
                    {selectedEdgesIn.map((e) => (
                      <DetailRow key={`${e.from}-in`} label={t('architectureTab.inboundFrom', { node: e.from })} value={`${e.protocol} · ${e.label}`} />
                    ))}
                    {selectedEdgesOut.map((e) => (
                      <DetailRow key={`${e.to}-out`} label={t('architectureTab.outboundTo', { node: e.to })} value={`${e.protocol} · ${e.label}`} />
                    ))}
                  </Section>
                )}

                {'routes' in selected && Array.isArray((selected as ArchNode).routes) && (
                  <Section title={t('architectureTab.sectionRoutes')}>
                    <div className="flex flex-wrap gap-1">
                      {((selected as ArchNode).routes ?? []).map((r) => (
                        <span key={r} className="rounded-full bg-gray-100 px-2 py-0.5 font-mono text-[10px] text-gray-600">
                          {r}
                        </span>
                      ))}
                    </div>
                  </Section>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Role-based views + rendered outputs — real personas the frontend serves, not
          separate deployed services, so they're shown as labels, not graph nodes. */}
      <Card>
        <CardContent className="flex flex-wrap items-center gap-6 pt-5">
          <div className="flex items-center gap-2">
            <p className="text-[10px] font-semibold uppercase tracking-wide text-gray-400">{t('architectureTab.roleBasedViews')}</p>
            <Chip icon={User} label={t('architectureTab.chipCitizenPortal')} />
            <Chip icon={UserCheck} label={t('architectureTab.chipOfficerConsole')} />
            <Chip icon={ShieldCheck} label={t('architectureTab.chipAdminConsole')} />
          </div>
          <div className="flex items-center gap-2">
            <p className="text-[10px] font-semibold uppercase tracking-wide text-gray-400">{t('architectureTab.renderedFromCoreApi')}</p>
            <Chip icon={LayoutDashboard} label={t('architectureTab.chipDashboard')} />
            <Chip icon={FileText} label={t('architectureTab.chipAuditReports')} />
            <Chip icon={Bell} label={t('architectureTab.chipNotifications')} />
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Card>
          <CardContent className="pt-5">
            <p className="text-xs font-semibold uppercase tracking-wide text-gray-400">{t('architectureTab.whyGatewayTitle')}</p>
            <p className="mt-1.5 text-sm text-gray-600">
              <Trans
                i18nKey="architectureTab.whyGatewayDescription"
                components={{ code1: <code className="font-mono text-xs" />, code2: <code className="font-mono text-xs" /> }}
              />
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-5">
            <p className="text-xs font-semibold uppercase tracking-wide text-gray-400">{t('architectureTab.whyTwoDatabasesTitle')}</p>
            <p className="mt-1.5 text-sm text-gray-600">{t('architectureTab.whyTwoDatabasesDescription')}</p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

function SummaryStat({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="rounded-md border border-gray-200 bg-white px-3 py-2">
      <p className="text-[10px] font-semibold uppercase tracking-wide text-gray-400">{label}</p>
      <p className="mt-0.5 truncate text-sm font-semibold text-gray-900">{value}</p>
    </div>
  )
}

function Chip({ icon: Icon, label }: { icon: typeof User; label: string }) {
  return (
    <span className="flex items-center gap-1.5 rounded-full border border-gray-200 bg-white px-2.5 py-1 text-[11px] font-medium text-gray-600 shadow-sm">
      <Icon className="h-3 w-3 text-gray-400" />
      {label}
    </span>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="border-t border-gray-100 pt-3">
      <p className="mb-1.5 text-xs font-semibold text-gray-700">{title}</p>
      <div className="space-y-1">{children}</div>
    </div>
  )
}

function DetailRow({ label, value, mono }: { label: string; value: string; mono?: boolean }) {
  return (
    <div className="flex items-center justify-between gap-3 text-xs">
      <span className="shrink-0 text-gray-400">{label}</span>
      <span className={cn('truncate text-right text-gray-700', mono && 'font-mono text-[11px]')}>{value}</span>
    </div>
  )
}
