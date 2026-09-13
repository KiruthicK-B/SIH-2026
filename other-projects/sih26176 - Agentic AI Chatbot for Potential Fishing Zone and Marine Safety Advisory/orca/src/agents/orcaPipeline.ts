import { PlannerAgent } from './PlannerAgent'
import { MarineDataAgent } from './MarineDataAgent'
import { WeatherAgent } from './WeatherAgent'
import { GeospatialAgent } from './GeospatialAgent'
import { RiskAgent } from './RiskAgent'
import { VisualizationAgent } from './VisualizationAgent'
import { ExplanationAgent } from './ExplanationAgent'
import { ChatAgent, type ChatSession } from './ChatAgent'
import { getBoundaries } from '@/data/mockBoundaries'
import { OceanAnalyticsAgent } from './OceanAnalyticsAgent'
import type { Intent, PFZResult, SafetyResult, WeatherForecast } from '@/data/types'

function pct(v: number) {
  return `${Math.round(v * 100)}%`
}

function buildResponseText(
  intent: Intent,
  locationName: string | null,
  date: string,
  pfzResult: PFZResult | null,
  safety: SafetyResult | null,
  weather: WeatherForecast,
  alertCount: number,
): string {
  const loc = locationName ?? 'the queried location'

  if (intent === 'hazard_query') {
    if (alertCount === 0) return `No significant hazard alerts near ${loc} on ${date}. Wave height ${weather.waveHeightM.toFixed(1)} m, lightning risk ${weather.lightningRisk}.`
    return `${alertCount} active hazard alert${alertCount > 1 ? 's' : ''} near ${loc} on ${date} — see the alerts below. Lightning risk is ${weather.lightningRisk.toLowerCase()}${weather.cycloneAlert ? ' and a cyclone alert is active' : ''}.`
  }

  if (intent === 'chlorophyll_sst_exploration') {
    if (!pfzResult) return `No strong chlorophyll/SST signal found near ${loc} on ${date}.`
    return `The strongest chlorophyll-a and SST signal near ${loc} on ${date} is ${pfzResult.distanceKm} km ${pfzResult.direction}, with ${pfzResult.band.toLowerCase()} PFZ likelihood (${pct(pfzResult.likelihood)}). This usually indicates a nutrient-rich thermal front.`
  }

  if (intent === 'follow_up_safer_zone') {
    if (!pfzResult) return `I couldn't find a clearly safer nearby zone for ${loc} on ${date} — conditions are fairly uniform right now.`
    return `A safer nearby zone from ${loc} is ${pfzResult.distanceKm} km ${pfzResult.direction}, with ${pfzResult.band.toLowerCase()} PFZ likelihood (${pct(pfzResult.likelihood)}) and clear of restricted boundaries.`
  }

  if (intent === 'follow_up_why_risky' && safety) {
    return `Here's why conditions near ${loc} on ${date} are rated ${safety.category}: ${safety.warnings.join(' ')}`
  }

  // pfz_safety / follow_up_next_day / default
  if (!pfzResult || !safety) return `I couldn't compute a PFZ recommendation for ${loc} on ${date}.`
  return `The nearest Potential Fishing Zone from ${loc} on ${date} is approximately ${pfzResult.distanceKm} km ${pfzResult.direction}, with ${pfzResult.band.toLowerCase()} likelihood (${pct(pfzResult.likelihood)}). Conditions are rated ${safety.category} for fishing operations (score ${safety.score}/100).`
}

export function runOrcaPipeline(session: ChatSession, userText: string): ChatSession {
  let s = ChatAgent.appendUserMessage(session, userText)
  const plannerContext = ChatAgent.getContext(s)
  const plan = PlannerAgent.plan(userText, plannerContext)

  if (plan.needsClarification) {
    s = ChatAgent.appendAssistantMessage(s, plan.clarificationQuestion ?? 'Could you clarify your location?', undefined, true)
    return s
  }

  const location = plan.location!
  const locationName = plan.locationName
  const date = plan.date

  // 2. MarineDataAgent — satellite proxy layers
  const pfzGrid = MarineDataAgent.getPFZLayer(date, location)

  // 3. OceanAnalyticsAgent — sanity-check a sample point's likelihood (used for explanation copy)
  const sampleSst = MarineDataAgent.getSST(location.lat, location.lon, date)
  const sampleChl = MarineDataAgent.getChlorophyll(location.lat, location.lon, date)
  OceanAnalyticsAgent.computePFZLikelihood(sampleSst, sampleChl)

  // 4. WeatherAgent
  const weather = WeatherAgent.getForecast(location.lat, location.lon, date)

  // 5. GeospatialAgent — boundaries + nearest PFZ
  const boundaries = getBoundaries()
  const geofenceHits = GeospatialAgent.checkGeofencing(location.lat, location.lon, boundaries)

  let pfzResult: PFZResult | null = null
  if (plan.intent !== 'hazard_query') {
    pfzResult = GeospatialAgent.findNearestPFZ(location, pfzGrid)
    if (plan.intent === 'follow_up_safer_zone' && pfzResult) {
      const safer = GeospatialAgent.findSaferAlternative(location, pfzGrid, pfzResult.center, boundaries)
      if (safer) pfzResult = safer
    }
  }

  // 6. RiskAgent
  const safety = RiskAgent.computeSafetyScore(weather.waveHeightM, weather.windSpeedKmh, weather.lightningRisk, weather.cycloneAlert, geofenceHits)

  // 7. ExplanationAgent
  const explanation = ExplanationAgent.generateExplanation({ intent: plan.intent, locationName, date, weather, safety, pfzResult, geofenceHits })

  // 8. VisualizationAgent
  const vizPlan = VisualizationAgent.buildVisualizationPlan({ intent: plan.intent, weather, safety, geofenceHits, date })

  const responseText = buildResponseText(plan.intent, locationName, date, pfzResult, safety, weather, vizPlan.alerts.length)

  // 9. ChatAgent — persist context + assistant turn
  s = ChatAgent.updateContext(s, location, locationName, date)
  s = ChatAgent.appendAssistantMessage(s, responseText, {
    pfzResult: pfzResult ?? undefined,
    safety,
    alerts: vizPlan.alerts,
    explanation,
    layers: vizPlan.layers,
    mapCenter: pfzResult?.center ?? location,
  })

  return s
}
