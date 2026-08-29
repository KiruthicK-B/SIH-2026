import type { Intent, MapLayers, OrcaAlert, SafetyResult, WeatherForecast } from '@/data/types'
import type { GeofenceHit } from './GeospatialAgent'

export interface VisualizationInput {
  intent: Intent
  weather: WeatherForecast
  safety: SafetyResult
  geofenceHits: GeofenceHit[]
  date: string
}

export interface VisualizationPlan {
  layers: MapLayers
  alerts: OrcaAlert[]
  panels: Array<'pfz_summary' | 'safety_summary' | 'reasoning'>
}

let alertCounter = 0
function nextAlertId() {
  alertCounter += 1
  return `alert-${alertCounter}`
}

/** Decides which map layers, alert badges, and result panels the assistant response should surface,
 *  based on the resolved intent and the risk/weather data already computed upstream in the pipeline. */
export const VisualizationAgent = {
  buildVisualizationPlan(input: VisualizationInput): VisualizationPlan {
    const { intent, weather, geofenceHits, date } = input
    const alerts: OrcaAlert[] = []
    const validUntil = `${date} 23:59`

    if (weather.waveHeightM > 2.0) {
      alerts.push({
        id: nextAlertId(),
        title: 'High Wave Warning',
        severity: weather.waveHeightM > 2.5 ? 'High' : 'Medium',
        text: `Wave height ${weather.waveHeightM.toFixed(1)} m expected near the queried location.`,
        validUntil,
        kind: 'wave',
      })
    }

    if (weather.lightningRisk !== 'Low') {
      alerts.push({
        id: nextAlertId(),
        title: 'Lightning Alert',
        severity: weather.lightningRisk === 'High' ? 'High' : 'Medium',
        text: `${weather.lightningRisk} lightning risk over the next 24 hours.`,
        validUntil,
        kind: 'lightning',
      })
    }

    if (weather.cycloneAlert) {
      alerts.push({
        id: nextAlertId(),
        title: 'Cyclone Alert',
        severity: 'High',
        text: 'Cyclonic conditions possible — Bay of Bengal advisory in effect.',
        validUntil,
        kind: 'cyclone',
      })
    }

    for (const hit of geofenceHits) {
      alerts.push({
        id: nextAlertId(),
        title: hit.inside ? `Inside ${hit.boundary.type} Zone` : `${hit.boundary.type} Zone Proximity`,
        severity: hit.inside && hit.boundary.type !== 'MPA' ? 'High' : 'Medium',
        text: hit.inside ? `Within ${hit.boundary.name}.` : `${hit.distanceKm} km from ${hit.boundary.name}.`,
        validUntil,
        kind: 'boundary',
      })
    }

    const layers: MapLayers = {
      pfz: intent === 'pfz_safety' || intent === 'chlorophyll_sst_exploration' || intent === 'follow_up_safer_zone' || intent === 'follow_up_next_day',
      waves: intent === 'pfz_safety' || intent === 'hazard_query' || intent === 'follow_up_next_day' || weather.waveHeightM > 1.5,
      lightning: intent === 'hazard_query' || weather.lightningRisk !== 'Low' || weather.cycloneAlert,
      boundaries: true,
    }

    const panels: VisualizationPlan['panels'] = []
    if (intent === 'pfz_safety' || intent === 'follow_up_next_day' || intent === 'follow_up_safer_zone' || intent === 'follow_up_why_risky') {
      panels.push('pfz_summary', 'safety_summary')
    } else if (intent === 'hazard_query') {
      panels.push('safety_summary')
    } else if (intent === 'chlorophyll_sst_exploration') {
      panels.push('pfz_summary')
    }
    panels.push('reasoning')

    return { layers, alerts, panels }
  },
}
