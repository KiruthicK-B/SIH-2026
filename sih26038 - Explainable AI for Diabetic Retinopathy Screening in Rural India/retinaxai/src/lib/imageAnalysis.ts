import { mulberry32, hashStringToSeed, randInt, randFloat } from './rng'
import type {
  QualityAssessment,
  QualityLevel,
  ScreeningResult,
  LesionPoint,
  DRSeverity,
} from './types'

const SEVERITY_BY_GRADE: DRSeverity[] = [
  'No DR',
  'Mild NPDR',
  'Moderate NPDR',
  'Severe NPDR',
  'Proliferative DR',
]

/** Downsamples the image onto an offscreen canvas and returns raw pixel data for lightweight analysis. */
export function getImageData(img: HTMLImageElement, size = 128): ImageData {
  const canvas = document.createElement('canvas')
  canvas.width = size
  canvas.height = size
  const ctx = canvas.getContext('2d')!
  ctx.drawImage(img, 0, 0, size, size)
  return ctx.getImageData(0, 0, size, size)
}

function toGrayscale(data: ImageData): Float32Array {
  const gray = new Float32Array(data.width * data.height)
  for (let i = 0; i < gray.length; i++) {
    const o = i * 4
    gray[i] = 0.299 * data.data[o] + 0.587 * data.data[o + 1] + 0.114 * data.data[o + 2]
  }
  return gray
}

/** Laplacian variance as a focus/blur proxy — higher variance implies sharper edges. */
function laplacianVariance(gray: Float32Array, w: number, h: number): number {
  const lap: number[] = []
  for (let y = 1; y < h - 1; y++) {
    for (let x = 1; x < w - 1; x++) {
      const i = y * w + x
      const v =
        -4 * gray[i] +
        gray[i - 1] +
        gray[i + 1] +
        gray[i - w] +
        gray[i + w]
      lap.push(v)
    }
  }
  const mean = lap.reduce((a, b) => a + b, 0) / lap.length
  const variance = lap.reduce((a, b) => a + (b - mean) ** 2, 0) / lap.length
  return variance
}

function meanAndStd(values: Float32Array | number[]): { mean: number; std: number } {
  const arr = Array.from(values)
  const mean = arr.reduce((a, b) => a + b, 0) / arr.length
  const std = Math.sqrt(arr.reduce((a, b) => a + (b - mean) ** 2, 0) / arr.length)
  return { mean, std }
}

/** Rough field-of-view estimate: fraction of pixels bright enough to be considered retinal tissue vs. black surround. */
function fieldOfViewCoverage(data: ImageData): number {
  let lit = 0
  const total = data.width * data.height
  for (let i = 0; i < total; i++) {
    const o = i * 4
    const brightness = (data.data[o] + data.data[o + 1] + data.data[o + 2]) / 3
    if (brightness > 18) lit++
  }
  return lit / total
}

function levelFromScore(score: number, goodMin: number, borderlineMin: number): QualityLevel {
  if (score >= goodMin) return 'Good'
  if (score >= borderlineMin) return 'Borderline'
  return 'Poor'
}

export function assessImageQuality(img: HTMLImageElement): QualityAssessment {
  const data = getImageData(img, 160)
  const gray = toGrayscale(data)
  const lapVar = laplacianVariance(gray, data.width, data.height)
  const { mean: brightness, std: contrast } = meanAndStd(gray)
  const fov = fieldOfViewCoverage(data)

  const focusLevel = levelFromScore(lapVar, 120, 40)
  const illumLevel: QualityLevel =
    brightness > 60 && brightness < 210 ? 'Good' : brightness > 35 && brightness < 235 ? 'Borderline' : 'Poor'
  const fovLevel = levelFromScore(fov * 100, 55, 30)
  const contrastLevel = levelFromScore(contrast, 28, 14)

  const levels = [focusLevel, illumLevel, fovLevel, contrastLevel]
  const poorCount = levels.filter((l) => l === 'Poor').length
  const borderlineCount = levels.filter((l) => l === 'Borderline').length

  let overall: QualityLevel = 'Good'
  if (poorCount >= 1) overall = 'Poor'
  else if (borderlineCount >= 1) overall = 'Borderline'

  const recommendation =
    overall === 'Good'
      ? 'The image is suitable for analysis.'
      : overall === 'Borderline'
        ? 'Image quality is borderline. Enhancement will be applied before analysis.'
        : 'Image quality is insufficient for reliable analysis. Recapture recommended.'

  return {
    overall,
    metrics: [
      { label: 'Focus (Laplacian Var.)', value: lapVar >= 120 ? 'Good' : lapVar >= 40 ? 'Borderline' : 'Poor', level: focusLevel },
      { label: 'Illumination', value: illumLevel, level: illumLevel },
      { label: 'Field of View', value: fovLevel, level: fovLevel },
      { label: 'Contrast', value: contrastLevel, level: contrastLevel },
    ],
    recommendation,
  }
}

/** Derives a deterministic seed from the uploaded image's pixel content so repeat uploads of the same
 *  image reproduce the same "AI" result, without needing a real model. */
export function seedFromImage(img: HTMLImageElement, fileNameHint: string): number {
  const data = getImageData(img, 24)
  let acc = ''
  for (let i = 0; i < data.data.length; i += 37) {
    acc += data.data[i]
  }
  return hashStringToSeed(acc + '|' + fileNameHint + '|' + img.naturalWidth + 'x' + img.naturalHeight)
}

function generateLesionPoints(rng: () => number, counts: { type: LesionPoint['type']; n: number; r: [number, number] }[]): LesionPoint[] {
  const points: LesionPoint[] = []
  for (const c of counts) {
    for (let i = 0; i < c.n; i++) {
      points.push({
        x: randFloat(rng, 0.18, 0.82),
        y: randFloat(rng, 0.18, 0.82),
        r: randFloat(rng, c.r[0], c.r[1]),
        type: c.type,
      })
    }
  }
  return points
}

export function generateScreeningResult(params: {
  id: string
  patientId: string
  patientName: string
  imageDataUrl: string
  seed: number
  quality: QualityAssessment
}): ScreeningResult {
  const { seed } = params
  const rng = mulberry32(seed)

  // Weighted grade distribution so results feel clinically plausible rather than uniform.
  const gradeRoll = rng()
  let drGrade: 0 | 1 | 2 | 3 | 4
  if (gradeRoll < 0.28) drGrade = 0
  else if (gradeRoll < 0.48) drGrade = 1
  else if (gradeRoll < 0.68) drGrade = 2
  else if (gradeRoll < 0.87) drGrade = 3
  else drGrade = 4

  const severity = SEVERITY_BY_GRADE[drGrade]
  const referable = drGrade >= 2

  const rawConfidence = randFloat(rng, 0.86, 0.99)
  const calibratedConfidence = Math.max(0.55, rawConfidence - randFloat(rng, 0.03, 0.12))

  const severityFactor = drGrade / 4
  const lesionCounts = {
    microaneurysms: Math.round(randInt(rng, 0, 6) + severityFactor * randInt(rng, 8, 22)),
    hemorrhages: Math.round(randInt(rng, 0, 2) + severityFactor * randInt(rng, 2, 10)),
    hardExudates: Math.round(randInt(rng, 0, 2) + severityFactor * randInt(rng, 1, 8)),
    softExudates: drGrade >= 3 ? randInt(rng, 1, 4) : randInt(rng, 0, 1),
  }

  const lesionPoints = generateLesionPoints(rng, [
    { type: 'microaneurysms', n: lesionCounts.microaneurysms, r: [0.006, 0.012] },
    { type: 'hemorrhages', n: lesionCounts.hemorrhages, r: [0.012, 0.022] },
    { type: 'hardExudates', n: lesionCounts.hardExudates, r: [0.014, 0.026] },
    { type: 'softExudates', n: lesionCounts.softExudates, r: [0.018, 0.03] },
  ])

  const opticDisc = { x: randFloat(rng, 0.24, 0.34), y: randFloat(rng, 0.4, 0.55) }
  const fovea = { x: randFloat(rng, 0.55, 0.68), y: randFloat(rng, 0.46, 0.58) }

  const exudateDistances = lesionPoints
    .filter((p) => p.type === 'hardExudates')
    .map((p) => Math.hypot(p.x - fovea.x, p.y - fovea.y))
  const minExudateDist = exudateDistances.length ? Math.min(...exudateDistances) : 1

  const exudateProximity: 'Low' | 'Moderate' | 'Elevated' =
    minExudateDist < 0.12 ? 'Elevated' : minExudateDist < 0.22 ? 'Moderate' : 'Low'
  const macularRisk: 'Low' | 'Moderate' | 'Elevated' =
    exudateProximity === 'Elevated' && drGrade >= 2 ? 'Elevated' : exudateProximity === 'Low' ? 'Low' : 'Moderate'

  const vesselDensity = randFloat(rng, 0.32, 0.52) - severityFactor * 0.04
  const tortuosity = randFloat(rng, 0.4, 0.7) + severityFactor * 0.15
  const nvAssessment: 'Not detected' | 'Suspicious' | 'Detected' =
    drGrade === 4 ? (rng() > 0.4 ? 'Detected' : 'Suspicious') : drGrade === 3 ? (rng() > 0.7 ? 'Suspicious' : 'Not detected') : 'Not detected'

  const lesionAgreementPct = Math.round(randFloat(rng, 68, 94))
  const consistency: 'LOW' | 'MODERATE' | 'HIGH' =
    lesionAgreementPct >= 80 ? 'HIGH' : lesionAgreementPct >= 60 ? 'MODERATE' : 'LOW'

  // Attention center biases toward the densest lesion cluster when present, else the optic disc vicinity.
  const attentionCenter = lesionPoints.length
    ? lesionPoints.reduce(
        (acc, p) => ({ x: acc.x + p.x / lesionPoints.length, y: acc.y + p.y / lesionPoints.length }),
        { x: 0, y: 0 },
      )
    : { x: opticDisc.x + 0.1, y: opticDisc.y }

  return {
    id: params.id,
    patientId: params.patientId,
    patientName: params.patientName,
    timestamp: new Date().toISOString(),
    imageDataUrl: params.imageDataUrl,
    seed,
    quality: params.quality,
    drGrade,
    severity,
    rawConfidence,
    calibratedConfidence,
    referable,
    lesionCounts,
    lesionPoints,
    vessel: {
      density: Number(vesselDensity.toFixed(2)),
      tortuosity: Number(tortuosity.toFixed(2)),
      avgWidthMicrons: Number(randFloat(rng, 110, 165).toFixed(1)),
      neovascularAssessment: nvAssessment,
    },
    landmarks: { opticDisc, fovea },
    macular: {
      foveaLocalized: true,
      exudateProximity,
      macularRisk,
    },
    explainability: {
      gradCamAvailable: true,
      lesionAgreementPct,
      consistency,
      attentionCenter,
      attentionRadius: randFloat(rng, 0.22, 0.34),
    },
    status: referable ? 'Referable' : 'Non-Referable',
    reviewStatus: referable ? 'Pending Review' : 'Not Required',
  }
}
