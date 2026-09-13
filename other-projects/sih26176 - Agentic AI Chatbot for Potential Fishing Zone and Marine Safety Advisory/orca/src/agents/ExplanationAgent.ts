import type { Explanation, Intent, PFZResult, SafetyResult, WeatherForecast } from '@/data/types'
import type { GeofenceHit } from './GeospatialAgent'

export interface ExplanationInput {
  intent: Intent
  locationName: string | null
  date: string
  weather: WeatherForecast
  safety: SafetyResult
  pfzResult: PFZResult | null
  geofenceHits: GeofenceHit[]
}

/** Produces the natural-language reasoning trail shown in the expandable "Show reasoning" panel —
 *  the step-by-step account of what the pipeline looked up and which rules fired. */
export const ExplanationAgent = {
  generateExplanation(input: ExplanationInput): Explanation {
    const { locationName, date, weather, safety, pfzResult, geofenceHits } = input

    const steps: string[] = []
    steps.push(`Identified starting location: ${locationName ?? 'unspecified'}.`)
    steps.push(`Retrieved the PFZ advisory layer and satellite proxy data (SST, chlorophyll-a) for ${date}.`)
    if (pfzResult) {
      steps.push(`Found nearest high-potential zone ${pfzResult.distanceKm} km ${pfzResult.direction}, likelihood ${(pfzResult.likelihood * 100).toFixed(0)}% (${pfzResult.band}).`)
    }
    steps.push(`Evaluated weather: wave height ${weather.waveHeightM.toFixed(1)} m, wind ${weather.windSpeedKmh} km/h ${weather.windDirection}, lightning risk ${weather.lightningRisk}${weather.cycloneAlert ? ', cyclone alert active' : ''}.`)
    if (geofenceHits.length > 0) {
      steps.push(`Checked maritime boundaries — ${geofenceHits.length} boundary${geofenceHits.length > 1 ? 'ies' : ''} within relevant range.`)
    } else {
      steps.push('Checked maritime boundaries — none within relevant range.')
    }
    steps.push(`Computed composite safety score: ${safety.score}/100 → ${safety.category}.`)

    const dataReferences = [
      `Simulated SST for ${date} (mock oceanographic proxy).`,
      `Simulated chlorophyll-a from Oceansat-like reflectance data for ${date}.`,
      `Simulated wave/wind/lightning forecast for ${date}.`,
      'Illustrative maritime boundary polygons (International / Restricted / MPA).',
    ]

    const rulesApplied: string[] = []
    if (pfzResult) {
      rulesApplied.push('High chlorophyll-a + strong thermal front → elevated PFZ likelihood.')
    }
    if (weather.waveHeightM > 2.5) rulesApplied.push('Wave height > 2.5 m → hazardous, major score deduction.')
    if (weather.lightningRisk === 'High') rulesApplied.push('High lightning risk → major score deduction.')
    if (weather.cycloneAlert) rulesApplied.push('Active cyclone alert → forced Unsafe category.')
    if (geofenceHits.some((h) => h.inside)) rulesApplied.push('Location inside a restricted/international boundary → forced Unsafe or heavy penalty.')
    if (rulesApplied.length === 0) rulesApplied.push('No high-severity rules triggered — conditions within normal operating range.')

    const summary =
      safety.category === 'Safe'
        ? `Conditions look favorable near ${locationName ?? 'the queried location'} on ${date}${pfzResult ? ` — nearest PFZ is ${pfzResult.distanceKm} km ${pfzResult.direction} with ${pfzResult.band.toLowerCase()} likelihood` : ''}.`
        : safety.category === 'Caution'
          ? `Proceed with caution near ${locationName ?? 'the queried location'} on ${date} — some hazards were detected.`
          : `Not recommended near ${locationName ?? 'the queried location'} on ${date} — significant hazards detected.`

    return { summary, steps, dataReferences, rulesApplied }
  },
}
