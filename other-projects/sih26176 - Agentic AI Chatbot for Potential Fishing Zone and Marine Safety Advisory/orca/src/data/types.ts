export type LatLng = { lat: number; lon: number }

export type PFZCell = {
  lat: number
  lon: number
  likelihood: number // 0–1
  sst: number // °C
  chlorophyll: number // mg/m³
}

export type PFZBand = 'Low' | 'Moderate' | 'High'

export type WeatherForecast = {
  waveHeightM: number
  windSpeedKmh: number
  windDirection: string
  lightningRisk: 'Low' | 'Medium' | 'High'
  cycloneAlert: boolean
  seaSurfaceTempC: number
  visibilityKm: number
  pressureHpa: number
}

export type SafetyCategory = 'Safe' | 'Caution' | 'Unsafe'

export type SafetyResult = {
  score: number // 0–100
  category: SafetyCategory
  warnings: string[]
}

export type PFZResult = {
  center: LatLng
  distanceKm: number
  direction: string
  likelihood: number
  band: PFZBand
  id: string
}

export type BoundaryType = 'International' | 'Restricted' | 'MPA'

export type Boundary = {
  name: string
  type: BoundaryType
  polygon: LatLng[]
}

export type Explanation = {
  summary: string
  steps: string[]
  dataReferences: string[]
  rulesApplied: string[]
}

export type AlertSeverity = 'Low' | 'Medium' | 'High'

export type OrcaAlert = {
  id: string
  title: string
  severity: AlertSeverity
  text: string
  validUntil: string
  kind: 'wave' | 'lightning' | 'cyclone' | 'boundary'
}

export type MapLayers = {
  pfz: boolean
  waves: boolean
  lightning: boolean
  boundaries: boolean
}

export type ChatRole = 'user' | 'assistant'

export type ChatAttachment = {
  pfzResult?: PFZResult
  safety?: SafetyResult
  alerts?: OrcaAlert[]
  explanation?: Explanation
  layers?: MapLayers
  mapCenter?: LatLng
}

export type ChatMessage = {
  id: string
  role: ChatRole
  text: string
  timestamp: string
  attachment?: ChatAttachment
  needsClarification?: boolean
}

export type Port = {
  name: string
  state: string
  location: LatLng
}

export type Intent =
  | 'pfz_safety'
  | 'hazard_query'
  | 'chlorophyll_sst_exploration'
  | 'follow_up_next_day'
  | 'follow_up_safer_zone'
  | 'follow_up_why_risky'
  | 'clarify_location'
  | 'unknown'

export type PlanResult = {
  intent: Intent
  location: LatLng | null
  locationName: string | null
  date: string
  needsClarification: boolean
  clarificationQuestion?: string
}
