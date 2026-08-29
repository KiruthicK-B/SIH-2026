import { getWeatherForecast, getTideForecast } from '@/data/mockWeather'
import type { WeatherForecast } from '@/data/types'

/** Wraps the mock weather/ocean dataset behind agent-style functions per the ORCA agent spec. */
export const WeatherAgent = {
  getForecast(lat: number, lon: number, date: string): WeatherForecast {
    return getWeatherForecast(lat, lon, date)
  },
  getWaveForecast(lat: number, lon: number, date: string): number {
    return getWeatherForecast(lat, lon, date).waveHeightM
  },
  getWindForecast(lat: number, lon: number, date: string): { speedKmh: number; direction: string } {
    const f = getWeatherForecast(lat, lon, date)
    return { speedKmh: f.windSpeedKmh, direction: f.windDirection }
  },
  getLightningRisk(lat: number, lon: number, date: string): WeatherForecast['lightningRisk'] {
    return getWeatherForecast(lat, lon, date).lightningRisk
  },
  getCycloneAlert(lat: number, lon: number, date: string): boolean {
    return getWeatherForecast(lat, lon, date).cycloneAlert
  },
  getTides(lat: number, lon: number, date: string) {
    return getTideForecast(lat, lon, date)
  },
}
