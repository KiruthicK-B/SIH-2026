export type QualityLevel = 'Good' | 'Borderline' | 'Poor'

export interface QualityMetric {
  label: string
  value: string
  level: QualityLevel
}

export interface QualityAssessment {
  overall: QualityLevel
  metrics: QualityMetric[]
  recommendation: string
}

export type DRSeverity = 'No DR' | 'Mild NPDR' | 'Moderate NPDR' | 'Severe NPDR' | 'Proliferative DR'

export interface LesionCounts {
  microaneurysms: number
  hemorrhages: number
  hardExudates: number
  softExudates: number
}

export interface LesionPoint {
  x: number // 0..1 normalized
  y: number // 0..1 normalized
  r: number // 0..1 normalized radius
  type: 'microaneurysms' | 'hemorrhages' | 'hardExudates' | 'softExudates'
}

export interface VesselMetrics {
  density: number
  tortuosity: number
  avgWidthMicrons: number
  neovascularAssessment: 'Not detected' | 'Suspicious' | 'Detected'
}

export interface AnatomicalLandmarks {
  opticDisc: { x: number; y: number }
  fovea: { x: number; y: number }
}

export interface MacularAnalysis {
  foveaLocalized: boolean
  exudateProximity: 'Low' | 'Moderate' | 'Elevated'
  macularRisk: 'Low' | 'Moderate' | 'Elevated'
}

export interface Explainability {
  gradCamAvailable: boolean
  lesionAgreementPct: number
  consistency: 'LOW' | 'MODERATE' | 'HIGH'
  attentionCenter: { x: number; y: number }
  attentionRadius: number
}

export interface ScreeningResult {
  id: string
  patientId: string
  patientName: string
  timestamp: string
  imageDataUrl: string
  seed: number
  quality: QualityAssessment
  drGrade: 0 | 1 | 2 | 3 | 4
  severity: DRSeverity
  rawConfidence: number
  calibratedConfidence: number
  referable: boolean
  lesionCounts: LesionCounts
  lesionPoints: LesionPoint[]
  vessel: VesselMetrics
  landmarks: AnatomicalLandmarks
  macular: MacularAnalysis
  explainability: Explainability
  status: 'Referable' | 'Non-Referable'
  reviewStatus: 'Pending Review' | 'Reviewed' | 'Not Required'
}
