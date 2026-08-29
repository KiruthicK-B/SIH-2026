import type { SafetyCategory, SafetyResult, WeatherForecast } from '@/data/types'
import type { GeofenceHit } from './GeospatialAgent'

function categoryFromScore(score: number): SafetyCategory {
  if (score >= 75) return 'Safe'
  if (score >= 45) return 'Caution'
  return 'Unsafe'
}

/** Combines wave, wind, lightning, cyclone, and boundary-proximity risk into a single 0–100 safety
 *  score with human-readable warnings. Any hard trigger (cyclone alert, restricted-zone intrusion,
 *  extreme wave height) forces the category to Unsafe regardless of the composite score. */
export const RiskAgent = {
  computeSafetyScore(
    wave: number,
    wind: number,
    lightning: WeatherForecast['lightningRisk'],
    cyclone: boolean,
    boundary: GeofenceHit[],
  ): SafetyResult {
    let score = 100
    const warnings: string[] = []
    let forceUnsafe = false

    if (wave > 2.5) {
      score -= 35
      warnings.push(`High wave height (${wave.toFixed(1)} m) — hazardous for small and medium craft.`)
    } else if (wave > 1.5) {
      score -= 15
      warnings.push(`Moderate wave height (${wave.toFixed(1)} m) — exercise caution.`)
    }
    if (wave > 3.5) forceUnsafe = true

    if (wind > 40) {
      score -= 20
      warnings.push(`Strong winds (${wind} km/h) may affect vessel handling.`)
    } else if (wind > 28) {
      score -= 8
      warnings.push(`Moderate winds (${wind} km/h).`)
    }

    if (lightning === 'High') {
      score -= 30
      warnings.push('High lightning risk in the area — avoid open water during storm windows.')
    } else if (lightning === 'Medium') {
      score -= 12
      warnings.push('Medium lightning risk — monitor sky conditions closely.')
    }

    if (cyclone) {
      score -= 45
      forceUnsafe = true
      warnings.push('Active cyclone alert — fishing operations not recommended.')
    }

    for (const hit of boundary) {
      if (hit.inside) {
        score -= hit.boundary.type === 'MPA' ? 20 : 35
        forceUnsafe = hit.boundary.type !== 'MPA' || forceUnsafe
        warnings.push(`Location falls within ${hit.boundary.type === 'MPA' ? 'a protected marine area' : hit.boundary.type.toLowerCase() + ' boundary'}: ${hit.boundary.name}.`)
      } else {
        score -= 8
        warnings.push(`Within ${hit.distanceKm} km of ${hit.boundary.name} (${hit.boundary.type}) — stay clear.`)
      }
    }

    score = Math.max(0, Math.min(100, Math.round(score)))
    let category = categoryFromScore(score)
    if (forceUnsafe) category = 'Unsafe'

    if (warnings.length === 0) warnings.push('No significant hazards detected for the selected location and date.')

    return { score, category, warnings }
  },
}
