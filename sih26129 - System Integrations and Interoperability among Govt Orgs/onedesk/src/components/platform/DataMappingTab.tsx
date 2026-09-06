import { Building2, Expand, Info, Lock, LockOpen, Maximize2, Minus, Plus, Search, Shrink, UserCheck } from 'lucide-react'
import { motion } from 'motion/react'
import { useEffect, useMemo, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent } from '@/components/ui/Card'
import { Input } from '@/components/ui/Input'
import { Modal } from '@/components/ui/Modal'
import { Select } from '@/components/ui/Select'
import {
  CANONICAL_MODEL_NAME,
  CANONICAL_MODEL_VERSION,
  type DepartmentNode,
  NODE_POSITIONS,
  defaultProtocolStyle,
  protocolStyle,
} from '@/data/dataMapping'
import { api } from '@/lib/api'
import { cn } from '@/lib/utils'

const CENTER = { x: 50, y: 50 }

const legendEntries = Object.values(protocolStyle)

function styleFor(protocol: string) {
  return protocolStyle[protocol] ?? defaultProtocolStyle
}

export function DataMappingTab() {
  const { t } = useTranslation()
  const protocolFilterOptions = [
    { value: 'all', label: t('dataMappingTab.filterAll') },
    { value: 'OAuth', label: 'OAuth' },
    { value: 'SOAP', label: 'SOAP' },
    { value: 'REST', label: 'REST' },
    { value: 'DB', label: 'Database' },
    { value: 'GraphQL', label: 'GraphQL' },
    { value: 'Manual', label: t('dataMappingTab.filterManual') },
  ]
  const [departments, setDepartments] = useState<DepartmentNode[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [hoveredId, setHoveredId] = useState<string | null>(null)
  const [protocolFilter, setProtocolFilter] = useState('all')
  const [query, setQuery] = useState('')
  const [zoom, setZoom] = useState(1)
  const [locked, setLocked] = useState(false)
  const [showAllMappings, setShowAllMappings] = useState(false)
  const [expanded, setExpanded] = useState(false)

  useEffect(() => {
    api.get<DepartmentNode[]>('/data-mapping').then(setDepartments)
  }, [])

  useEffect(() => {
    if (!expanded) return
    const onKeyDown = (e: KeyboardEvent) => e.key === 'Escape' && setExpanded(false)
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [expanded])

  const filteredIds = useMemo(() => {
    const q = query.trim().toLowerCase()
    return new Set(
      departments
        .filter((d) => {
          if (protocolFilter !== 'all' && d.protocol !== protocolFilter) return false
          if (!q) return true
          return (
            d.name.toLowerCase().includes(q) ||
            d.dataFlows.some((f) => f.field.toLowerCase().includes(q) || f.canonicalField.toLowerCase().includes(q))
          )
        })
        .map((d) => d.id),
    )
  }, [departments, protocolFilter, query])

  const selected = departments.find((d) => d.id === selectedId) ?? null
  const hovered = departments.find((d) => d.id === hoveredId) ?? null
  const tooltipTarget = !selected ? hovered : null // avoid tooltip fighting with an open detail panel

  const selectNode = (id: string) => {
    if (locked) return
    setSelectedId((prev) => (prev === id ? null : id))
  }

  return (
    <div className={cn('space-y-4', expanded && 'fixed inset-4 z-50 flex flex-col overflow-auto rounded-lg border border-gray-200 bg-white p-4 shadow-2xl')}>
      {expanded && <div className="fixed inset-0 -z-10 bg-black/50" onClick={() => setExpanded(false)} />}

      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <p className="flex items-center gap-1.5 text-sm font-semibold text-gray-900">
            {t('dataMappingTab.title')}
            <Info className="h-3.5 w-3.5 text-gray-300" />
          </p>
          <p className="mt-0.5 text-sm text-gray-500">{t('dataMappingTab.subtitle')}</p>
        </div>

        <div className="flex flex-wrap items-center gap-4">
          <div className="flex flex-wrap items-center gap-3">
            {legendEntries.map((entry) => (
              <span key={entry.label} className="flex items-center gap-1.5 text-xs text-gray-500">
                <span
                  className="inline-block h-0 w-4 border-t-2"
                  style={{ borderColor: entry.stroke, borderStyle: entry.dashed ? 'dashed' : 'solid' }}
                />
                {entry.label}
              </span>
            ))}
          </div>
          <Select value={protocolFilter} onValueChange={setProtocolFilter} options={protocolFilterOptions} className="w-44" />
          <button
            type="button"
            onClick={() => setExpanded((e) => !e)}
            className="flex items-center gap-1.5 rounded-md border border-gray-200 bg-white px-2.5 py-1.5 text-xs font-medium text-gray-600 shadow-sm hover:bg-gray-50"
          >
            {expanded ? <Shrink className="h-3.5 w-3.5" /> : <Expand className="h-3.5 w-3.5" />}
            {expanded ? t('dataMappingTab.exitFullView') : t('dataMappingTab.openFullView')}
          </button>
        </div>
      </div>

      <div className="relative flex-1">
        <div className={cn('grid grid-cols-1 gap-4 lg:grid-cols-[1fr_320px]', expanded && 'h-full')}>
          <Card className="relative overflow-hidden">
            <div className="pointer-events-none absolute right-3 top-3 z-20 w-56">
              <div className="pointer-events-auto relative">
                <Search className="pointer-events-none absolute left-2.5 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-gray-400" />
                <Input
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder={t('dataMappingTab.searchPlaceholder')}
                  className="h-8 border-gray-200 bg-white pl-8 text-xs shadow-sm"
                />
              </div>
            </div>
            <CardContent className="p-0">
              <div className={cn('relative w-full overflow-hidden bg-gray-50/50', expanded ? 'h-full min-h-[520px]' : 'h-[560px]')}>
                <div
                  className="absolute inset-0 origin-center transition-transform duration-200"
                  style={{ transform: `scale(${zoom})` }}
                >
                  {/* Connection lines */}
                  <svg viewBox="0 0 100 100" preserveAspectRatio="none" className="absolute inset-0 h-full w-full">
                    {departments.map((d) => {
                      const pos = NODE_POSITIONS[d.name] ?? { x: 50, y: 50 }
                      const style = styleFor(d.protocol)
                      const dimmed = (!filteredIds.has(d.id) && (protocolFilter !== 'all' || query.trim())) || (selectedId && selectedId !== d.id)
                      return (
                        <g key={d.id}>
                          {/* wide invisible hit target for hover */}
                          <line
                            x1={CENTER.x}
                            y1={CENTER.y}
                            x2={pos.x}
                            y2={pos.y}
                            stroke="transparent"
                            strokeWidth={3}
                            className="cursor-pointer"
                            onMouseEnter={() => setHoveredId(d.id)}
                            onMouseLeave={() => setHoveredId((prev) => (prev === d.id ? null : prev))}
                            onClick={() => selectNode(d.id)}
                          />
                          <line
                            x1={CENTER.x}
                            y1={CENTER.y}
                            x2={pos.x}
                            y2={pos.y}
                            stroke={style.stroke}
                            strokeWidth={selectedId === d.id ? 0.6 : 0.35}
                            strokeDasharray={style.dashed ? '2 1.5' : undefined}
                            opacity={dimmed ? 0.15 : hoveredId === d.id ? 1 : 0.75}
                            className="pointer-events-none transition-opacity"
                            vectorEffect="non-scaling-stroke"
                          />
                          {/* Flow indicator — marching dashes animate along the connector
                              while hovered or selected, showing data actually moving
                              through this link, not just a static line. */}
                          {(hoveredId === d.id || selectedId === d.id) && (
                            <motion.line
                              x1={CENTER.x}
                              y1={CENTER.y}
                              x2={pos.x}
                              y2={pos.y}
                              stroke={style.stroke}
                              strokeWidth={1}
                              strokeLinecap="round"
                              strokeDasharray="1.2 3"
                              className="pointer-events-none"
                              vectorEffect="non-scaling-stroke"
                              initial={{ strokeDashoffset: 0 }}
                              animate={{ strokeDashoffset: -8.4 }}
                              transition={{ duration: 0.7, repeat: Infinity, ease: 'linear' }}
                            />
                          )}
                        </g>
                      )
                    })}
                  </svg>

                  {/* OneDesk hub */}
                  <div
                    className="absolute flex h-24 w-24 -translate-x-1/2 -translate-y-1/2 flex-col items-center justify-center rounded-full border-4 border-brand-100 bg-brand-600 text-center shadow-sm"
                    style={{ left: `${CENTER.x}%`, top: `${CENTER.y}%` }}
                  >
                    <p className="text-[11px] font-semibold leading-tight text-white">{t('dataMappingTab.oneDeskHub')}</p>
                    <p className="text-[9px] leading-tight text-brand-100">{t('dataMappingTab.interoperabilityLayer')}</p>
                  </div>

                  {/* Department nodes */}
                  {departments.map((d) => {
                    const pos = NODE_POSITIONS[d.name] ?? { x: 50, y: 50 }
                    const dimmed = (!filteredIds.has(d.id) && (protocolFilter !== 'all' || query.trim())) || (selectedId && selectedId !== d.id)
                    return (
                      <button
                        key={d.id}
                        type="button"
                        onClick={() => selectNode(d.id)}
                        onMouseEnter={() => setHoveredId(d.id)}
                        onMouseLeave={() => setHoveredId((prev) => (prev === d.id ? null : prev))}
                        className={cn(
                          'absolute w-[168px] -translate-x-1/2 -translate-y-1/2 rounded-md border bg-white px-3 py-2 text-left shadow-sm transition-all',
                          selectedId === d.id ? 'border-brand-500 ring-1 ring-brand-500' : 'border-gray-200 hover:border-gray-300',
                          dimmed && 'opacity-30',
                        )}
                        style={{ left: `${pos.x}%`, top: `${pos.y}%` }}
                      >
                        <div className="flex items-start justify-between gap-2">
                          <div className="flex items-start gap-1.5">
                            <div className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded bg-navy-800/5 text-navy-800">
                              <Building2 className="h-3.5 w-3.5" />
                            </div>
                            <p className="text-xs font-semibold leading-tight text-gray-900">{d.name}</p>
                          </div>
                          <span
                            className={cn(
                              'mt-1 h-1.5 w-1.5 shrink-0 rounded-full',
                              d.health === 'Healthy' && 'bg-success-600',
                              d.health === 'Degraded' && 'bg-warning-600',
                              d.health === 'Down' && 'bg-danger-600',
                              d.health === 'Manual Processing' && 'bg-gray-400',
                            )}
                          />
                        </div>
                        <p className="mt-1 text-[10px] text-gray-500">{d.interfaceType}</p>
                        <p className="font-mono text-[10px] text-gray-400">
                          {d.hasLiveConnector ? t('dataMappingTab.fieldsExchanged', { count: d.dataFlows.length }) : t('dataMappingTab.noLiveConnector')}
                        </p>
                      </button>
                    )
                  })}
                </div>

                {tooltipTarget &&
                  (() => {
                    const pos = NODE_POSITIONS[tooltipTarget.name] ?? { x: 50, y: 50 }
                    return (
                      <div
                        className="pointer-events-none absolute z-20 w-72 -translate-x-1/2 rounded-md border border-gray-200 bg-white p-3 text-xs shadow-md"
                        style={{
                          left: `${pos.x}%`,
                          top: `${pos.y < 50 ? pos.y + 8 : pos.y - 8}%`,
                          transform: pos.y < 50 ? 'translate(-50%, 0)' : 'translate(-50%, -100%)',
                        }}
                      >
                        <p className="font-semibold text-gray-900">{tooltipTarget.name}</p>
                        <p className="mt-0.5 text-[11px] text-gray-500">{tooltipTarget.description}</p>
                        <dl className="mt-2 space-y-1 border-t border-gray-100 pt-2">
                          <TooltipRow label={t('dataMappingTab.protocol')} value={tooltipTarget.protocol} />
                          <TooltipRow label={t('dataMappingTab.status')} value={t(`status.${tooltipTarget.health}`, { defaultValue: tooltipTarget.health })} />
                          <TooltipRow
                            label={t('dataMappingTab.nameResolved')}
                            value={tooltipTarget.identityResolution ? t('dataMappingTab.yes') : t('dataMappingTab.notYet')}
                          />
                        </dl>
                        {tooltipTarget.dataFlows.length > 0 ? (
                          <div className="mt-2 space-y-1 border-t border-gray-100 pt-2">
                            <p className="text-[10px] font-semibold uppercase tracking-wide text-gray-400">
                              {t('dataMappingTab.variablesExchanged', { department: tooltipTarget.name })}
                            </p>
                            {tooltipTarget.dataFlows.slice(0, 4).map((f) => (
                              <div key={`${f.direction}-${f.field}`} className="flex items-center gap-1.5 font-mono text-[10px]">
                                <span className="w-3 shrink-0 text-center text-gray-400">
                                  {f.direction === 'Outbound' ? '→' : f.direction === 'Inbound' ? '←' : '•'}
                                </span>
                                <span className="min-w-0 flex-1 truncate text-gray-500">{f.field}</span>
                                <span className="shrink-0 text-gray-300">↦</span>
                                <span className="min-w-0 flex-1 truncate text-right text-gray-900">{f.canonicalField}</span>
                              </div>
                            ))}
                            {tooltipTarget.dataFlows.length > 4 && (
                              <p className="text-[10px] text-gray-400">
                                {t('dataMappingTab.moreFields', { count: tooltipTarget.dataFlows.length - 4 })}
                              </p>
                            )}
                          </div>
                        ) : (
                          <p className="mt-2 border-t border-gray-100 pt-2 text-[11px] text-gray-400">
                            {t('dataMappingTab.noLiveConnectorManual')}
                          </p>
                        )}
                      </div>
                    )
                  })()}

                {/* Canvas controls */}
                <div className="absolute bottom-3 left-3 z-10 flex items-center gap-1 rounded-md border border-gray-200 bg-white p-1 shadow-sm">
                  <button
                    type="button"
                    onClick={() => setZoom((z) => Math.min(1.6, +(z + 0.2).toFixed(1)))}
                    className="flex h-7 w-7 items-center justify-center rounded text-gray-500 hover:bg-gray-100"
                    aria-label={t('dataMappingTab.zoomIn')}
                  >
                    <Plus className="h-3.5 w-3.5" />
                  </button>
                  <button
                    type="button"
                    onClick={() => setZoom((z) => Math.max(0.6, +(z - 0.2).toFixed(1)))}
                    className="flex h-7 w-7 items-center justify-center rounded text-gray-500 hover:bg-gray-100"
                    aria-label={t('dataMappingTab.zoomOut')}
                  >
                    <Minus className="h-3.5 w-3.5" />
                  </button>
                  <button
                    type="button"
                    onClick={() => setZoom(1)}
                    className="flex h-7 w-7 items-center justify-center rounded text-gray-500 hover:bg-gray-100"
                    aria-label={t('dataMappingTab.fitToView')}
                  >
                    <Maximize2 className="h-3.5 w-3.5" />
                  </button>
                  <button
                    type="button"
                    onClick={() => setLocked((l) => !l)}
                    className={cn('flex h-7 w-7 items-center justify-center rounded hover:bg-gray-100', locked ? 'text-brand-600' : 'text-gray-500')}
                    aria-label={locked ? t('dataMappingTab.unlockLayout') : t('dataMappingTab.lockLayout')}
                    title={locked ? t('dataMappingTab.layoutLockedTitle') : t('dataMappingTab.lockLayout')}
                  >
                    {locked ? <Lock className="h-3.5 w-3.5" /> : <LockOpen className="h-3.5 w-3.5" />}
                  </button>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className={cn(expanded ? 'h-full overflow-auto' : 'h-fit')}>
            <CardContent className="pt-5">
              {!selected ? (
                <div className="flex flex-col items-center gap-2 py-14 text-center text-gray-400">
                  <Building2 className="h-8 w-8" />
                  <p className="text-sm">{t('dataMappingTab.selectDepartmentPrompt')}</p>
                </div>
              ) : (
                <DepartmentDetailPanel department={selected} onViewAllMappings={() => setShowAllMappings(true)} />
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      <p className="text-xs text-gray-400">
        {t('dataMappingTab.canonicalModelLabel')}{' '}
        <span className="font-mono text-gray-500">
          {CANONICAL_MODEL_NAME} ({CANONICAL_MODEL_VERSION})
        </span>{' '}
        {t('dataMappingTab.canonicalModelSuffix')}
      </p>

      {selected && (
        <Modal
          open={showAllMappings}
          onOpenChange={setShowAllMappings}
          title={t('dataMappingTab.fieldMappingsTitle', { department: selected.name })}
          description={t('dataMappingTab.fieldMappingsDescription', { model: CANONICAL_MODEL_NAME })}
        >
          <div className="space-y-1.5">
            {selected.dataFlows.length === 0 && (
              <p className="text-sm text-gray-400">{t('dataMappingTab.noFieldLevelExchange')}</p>
            )}
            {selected.dataFlows.map((f) => (
              <div
                key={`${f.direction}-${f.field}`}
                className="flex items-center justify-between rounded-md border border-gray-200 px-3 py-2 font-mono text-xs"
              >
                <span className="text-gray-400">{f.direction}</span>
                <span className="text-gray-500">{f.field}</span>
                <span className="text-gray-300">→</span>
                <span className="font-medium text-gray-900">{f.canonicalField}</span>
              </div>
            ))}
          </div>
        </Modal>
      )}
    </div>
  )
}

function TooltipRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-start justify-between gap-3">
      <dt className="text-gray-400">{label}</dt>
      <dd className="text-right text-gray-700">{value}</dd>
    </div>
  )
}

function DepartmentDetailPanel({
  department,
  onViewAllMappings,
}: {
  department: DepartmentNode
  onViewAllMappings: () => void
}) {
  const { t } = useTranslation()
  const d = department

  return (
    <div className="space-y-4">
      <div>
        <div className="flex items-center gap-2.5">
          <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-md bg-navy-800/5 text-navy-800">
            <Building2 className="h-5 w-5" />
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-900">{d.name}</p>
            <p className="text-xs text-gray-500">{d.interfaceType}</p>
          </div>
        </div>
        <div className="mt-2">
          <StatusBadge status={d.health} />
        </div>
        <p className="mt-3 text-xs text-gray-500">{d.description}</p>
      </div>

      <Section title={t('dataMappingTab.connectionDetailsTitle')}>
        <DetailRow label={t('dataMappingTab.protocol')} value={d.protocol} />
        <DetailRow label={t('dataMappingTab.status')} value={t(`status.${d.health}`, { defaultValue: d.health })} tone={d.health} />
        <DetailRow label={t('dataMappingTab.killSwitch')} value={d.killSwitchEnabled ? t('dataMappingTab.engaged') : t('dataMappingTab.off')} />
        <DetailRow label={t('dataMappingTab.modernization')} value={`${d.modernizationPercent}%`} />
      </Section>

      <Section title={t('dataMappingTab.identityResolutionTitle')}>
        {d.identityResolution ? (
          <>
            <DetailRow
              label={t('dataMappingTab.oneDeskCitizen')}
              value={`${d.identityResolution.citizenName} (${d.identityResolution.masterId})`}
            />
            <DetailRow label={t('dataMappingTab.resolvesTo')} value={d.identityResolution.departmentIdentifier} mono />
            {d.identityResolution.confidence != null && (
              <DetailRow label={t('dataMappingTab.confidence')} value={`${Math.round(d.identityResolution.confidence * 100)}%`} />
            )}
          </>
        ) : (
          <p className="flex items-center gap-1.5 text-xs text-gray-400">
            <UserCheck className="h-3.5 w-3.5" /> {t('dataMappingTab.noIdentifierResolved')}
          </p>
        )}
      </Section>

      <div>
        <p className="mb-1.5 text-xs font-semibold text-gray-700">
          {t('dataMappingTab.dataExchanged')} {d.dataFlows.length > 0 && t('dataMappingTab.dataExchangedFieldsCount', { count: d.dataFlows.length })}
        </p>
        {d.dataFlows.length === 0 ? (
          <p className="text-xs text-gray-400">{t('dataMappingTab.noAutomatedExchange')}</p>
        ) : (
          <>
            <div className="space-y-1.5">
              {d.dataFlows.slice(0, 3).map((f) => (
                <div
                  key={`${f.direction}-${f.field}`}
                  className="flex items-center justify-between rounded-md border border-gray-100 bg-gray-50 px-2.5 py-1.5 font-mono text-[11px]"
                >
                  <span className="text-danger-600/80">{f.field}</span>
                  <span className="text-gray-300">→</span>
                  <span className="text-success-700">{f.canonicalField}</span>
                </div>
              ))}
            </div>
            {d.dataFlows.length > 3 && (
              <button type="button" onClick={onViewAllMappings} className="mt-2 text-xs font-medium text-brand-600 hover:text-brand-700">
                {t('dataMappingTab.viewAllMappings')}
              </button>
            )}
          </>
        )}
      </div>
    </div>
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

function DetailRow({ label, value, mono, tone }: { label: string; value: string; mono?: boolean; tone?: string }) {
  return (
    <div className="flex items-center justify-between gap-3 text-xs">
      <span className="text-gray-400">{label}</span>
      <span
        className={cn(
          mono && 'font-mono',
          'text-right text-gray-700',
          tone === 'Healthy' && 'font-medium text-success-600',
          tone === 'Degraded' && 'font-medium text-warning-600',
          tone === 'Down' && 'font-medium text-danger-600',
          tone === 'Manual Processing' && 'font-medium text-gray-500',
        )}
      >
        {value}
      </span>
    </div>
  )
}
