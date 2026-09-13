import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'
import type { ScreeningResult } from '@/lib/types'
import { assessImageQuality, generateScreeningResult, seedFromImage } from '@/lib/imageAnalysis'
import { generateSyntheticFundus } from '@/lib/syntheticFundus'
import { mockPatients } from '@/data/mockPatients'

interface ScreeningsState {
  screenings: ScreeningResult[]
  ready: boolean
  getScreening: (id: string) => ScreeningResult | undefined
  addScreeningFromFile: (file: File, patientId?: string) => Promise<ScreeningResult>
  addScreeningFromSample: () => Promise<ScreeningResult>
  markReviewed: (id: string) => void
  stats: {
    screensCompleted: number
    referableCases: number
    patients: number
    avgConfidence: number
    pendingReview: number
  }
}

const ScreeningsContext = createContext<ScreeningsState | null>(null)

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new Image()
    img.onload = () => resolve(img)
    img.onerror = reject
    img.src = src
  })
}

function fileToDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result as string)
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}

let idCounter = 4 // seed screenings occupy 001-003

function nextScreeningId() {
  const n = String(idCounter++).padStart(3, '0')
  return `RXT-250518-${n}`
}

/** Builds a deterministic seed screening, nudging the seed forward until the DR grade lands on the
 *  desired side of the referable threshold so the dashboard demo data matches the reference mockup. */
async function buildSeedScreening(baseSeed: number, wantReferable: boolean, id: string, patientId: string, patientName: string): Promise<ScreeningResult> {
  let seed = baseSeed
  for (let attempt = 0; attempt < 400; attempt++) {
    const probe = generateScreeningResult({
      id,
      patientId,
      patientName,
      imageDataUrl: '',
      seed,
      quality: { overall: 'Good', metrics: [], recommendation: '' },
    })
    if (probe.referable === wantReferable) break
    seed += 1
  }
  const dataUrl = generateSyntheticFundus(seed)
  const img = await loadImage(dataUrl)
  const quality = assessImageQuality(img)
  return generateScreeningResult({ id, patientId, patientName, imageDataUrl: dataUrl, seed, quality })
}

export function ScreeningsProvider({ children }: { children: ReactNode }) {
  const [screenings, setScreenings] = useState<ScreeningResult[]>([])
  const [ready, setReady] = useState(false)

  useEffect(() => {
    let cancelled = false
    async function init() {
      const [s1, s2, s3] = await Promise.all([
        buildSeedScreening(918273, true, 'RXT-250518-001', mockPatients[0].id, mockPatients[0].name),
        buildSeedScreening(445566, false, 'RXT-250518-002', mockPatients[1].id, mockPatients[1].name),
        buildSeedScreening(112233, true, 'RXT-250518-003', mockPatients[2].id, mockPatients[2].name),
      ])
      if (cancelled) return
      const withTimestamps = [s1, s2, s3].map((s, i) => ({
        ...s,
        timestamp: new Date(Date.now() - (i + 1) * 1000 * 60 * 40).toISOString(),
        reviewStatus: (s.referable ? (i === 0 ? 'Pending Review' : 'Reviewed') : 'Not Required') as ScreeningResult['reviewStatus'],
      }))
      setScreenings(withTimestamps)
      setReady(true)
    }
    init()
    return () => {
      cancelled = true
    }
  }, [])

  const value = useMemo<ScreeningsState>(() => {
    const referableCases = screenings.filter((s) => s.referable).length
    const avgConfidence = screenings.length
      ? screenings.reduce((acc, s) => acc + s.calibratedConfidence, 0) / screenings.length
      : 0
    const pendingReview = screenings.filter((s) => s.reviewStatus === 'Pending Review').length

    return {
      screenings,
      ready,
      getScreening: (id: string) => screenings.find((s) => s.id === id),
      addScreeningFromFile: async (file: File, patientId?: string) => {
        const dataUrl = await fileToDataUrl(file)
        const img = await loadImage(dataUrl)
        const quality = assessImageQuality(img)
        const seed = seedFromImage(img, file.name + file.size)
        const patient = patientId ? mockPatients.find((p) => p.id === patientId) : undefined
        const result = generateScreeningResult({
          id: nextScreeningId(),
          patientId: patient?.id ?? 'PXT-WALKIN',
          patientName: patient?.name ?? 'Walk-in Patient',
          imageDataUrl: dataUrl,
          seed,
          quality,
        })
        setScreenings((prev) => [result, ...prev])
        return result
      },
      addScreeningFromSample: async () => {
        const seed = Math.floor(Math.random() * 1_000_000)
        const dataUrl = generateSyntheticFundus(seed)
        const img = await loadImage(dataUrl)
        const quality = assessImageQuality(img)
        const patient = mockPatients[Math.floor(Math.random() * mockPatients.length)]
        const result = generateScreeningResult({
          id: nextScreeningId(),
          patientId: patient.id,
          patientName: patient.name,
          imageDataUrl: dataUrl,
          seed,
          quality,
        })
        setScreenings((prev) => [result, ...prev])
        return result
      },
      markReviewed: (id: string) => {
        setScreenings((prev) => prev.map((s) => (s.id === id ? { ...s, reviewStatus: 'Reviewed' } : s)))
      },
      stats: {
        screensCompleted: screenings.length,
        referableCases,
        patients: mockPatients.length,
        avgConfidence,
        pendingReview,
      },
    }
  }, [screenings, ready])

  return <ScreeningsContext.Provider value={value}>{children}</ScreeningsContext.Provider>
}

export function useScreenings() {
  const ctx = useContext(ScreeningsContext)
  if (!ctx) throw new Error('useScreenings must be used within ScreeningsProvider')
  return ctx
}
