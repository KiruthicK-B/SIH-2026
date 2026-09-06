// Data Mapping tab — real data, fetched from GET /data-mapping (see DataMappingTab.tsx).
// Only presentation concerns (canvas layout position, protocol color legend) stay
// static here — the same category as icons or spacing, not "data" in the mock sense.

export interface DataFlowField {
  direction: string
  field: string
  canonicalField: string
  sampleValue: string
}

export interface IdentityResolution {
  masterId: string
  citizenName: string
  departmentIdentifier: string
  confidence: number | null
}

export interface DepartmentNode {
  id: string
  name: string
  description: string
  interfaceType: string
  modernizationPercent: number
  protocol: string
  health: string
  hasLiveConnector: boolean
  killSwitchEnabled: boolean
  dataFlows: DataFlowField[]
  identityResolution: IdentityResolution | null
}

export const CANONICAL_MODEL_NAME = 'OneDesk Canonical Data Model'
export const CANONICAL_MODEL_VERSION = 'OD-CANONICAL-1.0'

/** Fixed canvas position, percentage of container — hand-placed for an organic
 * (non-trigonometric-circle) layout, keyed by the real department name. */
export const NODE_POSITIONS: Record<string, { x: number; y: number }> = {
  'Business Registry': { x: 22, y: 14 },
  'Education Department': { x: 50, y: 10 },
  'Food & Civil Supplies': { x: 78, y: 14 },
  'Social Welfare Department': { x: 12, y: 40 },
  'Health Department': { x: 88, y: 40 },
  'Revenue Department': { x: 18, y: 62 },
  'Municipal Corporation': { x: 82, y: 62 },
  'License Authority': { x: 26, y: 87 },
  'Identity Service': { x: 74, y: 87 },
  RTO: { x: 50, y: 90 },
}

export const protocolStyle: Record<string, { stroke: string; dashed: boolean; label: string }> = {
  OAuth: { stroke: '#234478', dashed: false, label: 'OAuth' },
  SOAP: { stroke: '#163f8a', dashed: false, label: 'SOAP' },
  REST: { stroke: '#16803c', dashed: false, label: 'REST' },
  DB: { stroke: '#6a3fc4', dashed: false, label: 'Database' },
  GraphQL: { stroke: '#b25e09', dashed: false, label: 'GraphQL' },
  Manual: { stroke: '#9ca3af', dashed: true, label: 'Manual Processing' },
}

export const defaultProtocolStyle = { stroke: '#9ca3af', dashed: true, label: 'Unknown' }
