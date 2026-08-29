import { mulberry32, hashStringToSeed, randFloat } from '@/lib/rng'
import type { WeatherForecast } from './types'

function monthOf(dateStr: string): number {
  return new Date(dateStr + 'T00:00:00').getMonth() + 1 // 1-12
}

/** Bay of Bengal cyclone seasons: pre-monsoon (Apr-May) and post-monsoon/NE monsoon (Oct-Dec). */
function isCycloneSeason(month: number): boolean {
  return (month >= 4 && month <= 5) || (month >= 10 && month <= 12)
}

/** SW monsoon (Jun-Sep) drives rougher seas on the west coast; NE monsoon (Oct-Dec) drives the east coast. */
function isMonsoon(month: number): boolean {
  return (month >= 6 && month <= 9) || (month >= 10 && month <= 12)
}

/** Pre-monsoon thunderstorm season — highest lightning incidence along the Bay of Bengal coast. */
function isThunderstormSeason(month: number): boolean {
  return month >= 3 && month <= 5
}

const WIND_DIRECTIONS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']

export function getWeatherForecast(lat: number, lon: number, date: string): WeatherForecast {
  const rng = mulberry32(hashStringToSeed(`wx|${lat.toFixed(2)}|${lon.toFixed(2)}|${date}`))
  const month = monthOf(date)
  const offshoreFactor = Math.min(1, Math.abs(lon - 80) / 4 + 0.2) // rougher/windier further from coast, mock proxy

  let waveHeightM = randFloat(rng, 0.5, 1.3) + offshoreFactor * 0.6
  if (isMonsoon(month)) waveHeightM += randFloat(rng, 0.6, 1.6)
  waveHeightM = Math.round(waveHeightM * 10) / 10

  let windSpeedKmh = randFloat(rng, 10, 22) + offshoreFactor * 8
  if (isMonsoon(month)) windSpeedKmh += randFloat(rng, 8, 20)
  windSpeedKmh = Math.round(windSpeedKmh)

  const windDirection = WIND_DIRECTIONS[Math.floor(rng() * WIND_DIRECTIONS.length)]

  let lightningRisk: WeatherForecast['lightningRisk'] = 'Low'
  const lightningRoll = rng()
  if (isThunderstormSeason(month)) {
    lightningRisk = lightningRoll > 0.55 ? 'High' : lightningRoll > 0.25 ? 'Medium' : 'Low'
  } else {
    lightningRisk = lightningRoll > 0.85 ? 'Medium' : 'Low'
  }

  const cycloneRoll = rng()
  const cycloneAlert = isCycloneSeason(month) ? cycloneRoll > 0.72 : cycloneRoll > 0.97

  const seaSurfaceTempC = Math.round((28.5 + randFloat(rng, -1, 2) + (isMonsoon(month) ? -0.6 : 0.4)) * 10) / 10
  const visibilityKm = Math.round(randFloat(rng, 4, 12) - (isMonsoon(month) ? randFloat(rng, 1, 4) : 0))
  const pressureHpa = Math.round(1008 + randFloat(rng, -6, 6) - (cycloneAlert ? randFloat(rng, 8, 16) : 0))

  return {
    waveHeightM,
    windSpeedKmh,
    windDirection,
    lightningRisk,
    cycloneAlert,
    seaSurfaceTempC,
    visibilityKm: Math.max(1, visibilityKm),
    pressureHpa,
  }
}

export function getTideForecast(lat: number, lon: number, date: string) {
  const rng = mulberry32(hashStringToSeed(`tide|${lat.toFixed(2)}|${lon.toFixed(2)}|${date}`))
  const baseHigh1 = randFloat(rng, 1.0, 1.4)
  const baseHigh2 = randFloat(rng, 0.9, 1.3)
  const baseLow1 = randFloat(rng, 0.2, 0.5)
  const baseLow2 = randFloat(rng, 0.2, 0.5)
  return {
    events: [
      { type: 'Low' as const, time: '02:15 AM', heightM: Math.round(baseLow1 * 10) / 10 },
      { type: 'High' as const, time: '08:25 AM', heightM: Math.round(baseHigh1 * 10) / 10 },
      { type: 'Low' as const, time: '02:40 PM', heightM: Math.round(baseLow2 * 10) / 10 },
      { type: 'High' as const, time: '08:55 PM', heightM: Math.round(baseHigh2 * 10) / 10 },
    ],
    currentTrend: rng() > 0.5 ? 'Rising' : 'Falling',
  }
}
