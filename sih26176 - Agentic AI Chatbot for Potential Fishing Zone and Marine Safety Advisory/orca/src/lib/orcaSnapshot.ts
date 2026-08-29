import { MarineDataAgent } from '@/agents/MarineDataAgent'
import { WeatherAgent } from '@/agents/WeatherAgent'
import { GeospatialAgent } from '@/agents/GeospatialAgent'
import { RiskAgent } from '@/agents/RiskAgent'
import { VisualizationAgent } from '@/agents/VisualizationAgent'
import { getBoundaries } from '@/data/mockBoundaries'
import type { LatLng } from '@/data/types'

/** Runs the same agent pipeline as chat, but for a fixed location/date — used by dashboard-style
 *  pages (Dashboard, PFZ Finder, Weather, Tides, Boundaries) that show "current conditions" without
 *  going through a conversation turn. */
export function computeOrcaSnapshot(location: LatLng, date: string) {
  const pfzGrid = MarineDataAgent.getPFZLayer(date, location)
  const weather = WeatherAgent.getForecast(location.lat, location.lon, date)
  const tides = WeatherAgent.getTides(location.lat, location.lon, date)
  const boundaries = getBoundaries()
  const geofenceHits = GeospatialAgent.checkGeofencing(location.lat, location.lon, boundaries)
  const pfzResult = GeospatialAgent.findNearestPFZ(location, pfzGrid)
  const safety = RiskAgent.computeSafetyScore(weather.waveHeightM, weather.windSpeedKmh, weather.lightningRisk, weather.cycloneAlert, geofenceHits)
  const vizPlan = VisualizationAgent.buildVisualizationPlan({ intent: 'pfz_safety', weather, safety, geofenceHits, date })

  return { pfzGrid, weather, tides, boundaries, geofenceHits, pfzResult, safety, alerts: vizPlan.alerts, layers: vizPlan.layers }
}
