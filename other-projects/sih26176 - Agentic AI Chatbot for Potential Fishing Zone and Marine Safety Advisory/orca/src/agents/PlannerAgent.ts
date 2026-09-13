import type { Intent, LatLng, PlanResult } from '@/data/types'
import { findPortByName, ports } from '@/data/ports'

export interface PlannerContext {
  lastLocation: LatLng | null
  lastLocationName: string | null
  lastDate: string | null
}

function todayISO(): string {
  return new Date().toISOString().slice(0, 10)
}

/** Adds days to a YYYY-MM-DD string using UTC-only arithmetic — parsing/serializing in local time
 *  would shift the result by a day in any UTC+ timezone (e.g. IST), since local midnight doesn't
 *  align with the UTC calendar boundary. */
function addDays(dateStr: string, days: number): string {
  const [year, month, day] = dateStr.split('-').map(Number)
  const d = new Date(Date.UTC(year, month - 1, day))
  d.setUTCDate(d.getUTCDate() + days)
  return d.toISOString().slice(0, 10)
}

function detectLocation(message: string): { location: LatLng; name: string } | null {
  const lower = message.toLowerCase()
  for (const port of ports) {
    if (lower.includes(port.name.toLowerCase())) {
      return { location: port.location, name: port.name }
    }
  }
  const fromMatch = lower.match(/from ([a-z\s]+?)(?:[.?,]| today| tomorrow| is| are|$)/)
  if (fromMatch) {
    const candidate = findPortByName(fromMatch[1].trim())
    if (candidate) return { location: candidate.location, name: candidate.name }
  }
  return null
}

function detectIntent(message: string): Intent {
  const lower = message.toLowerCase()

  if (/(day after|next day)/.test(lower)) return 'follow_up_next_day'
  if (/(safer|another zone|different zone|alternative)/.test(lower)) return 'follow_up_safer_zone'
  if (/why.*(risky|unsafe|danger|caution)/.test(lower)) return 'follow_up_why_risky'

  if (/(chlorophyll|sea surface temp|\bsst\b|thermal front|favorable)/.test(lower)) return 'chlorophyll_sst_exploration'
  if (/(lightning|cyclone|hazard|storm|alert)/.test(lower) && !/(pfz|fishing zone|safe to)/.test(lower)) return 'hazard_query'
  if (/(pfz|fishing zone|safe|safety|potential fishing)/.test(lower)) return 'pfz_safety'

  return 'unknown'
}

function detectDate(message: string, baseDate: string): string {
  const lower = message.toLowerCase()
  if (lower.includes('day after')) return addDays(baseDate, 2)
  if (lower.includes('tomorrow')) return addDays(baseDate, 1)
  if (lower.includes('today')) return baseDate
  return baseDate
}

export const PlannerAgent = {
  plan(message: string, context: PlannerContext): PlanResult {
    const today = todayISO()
    const intent = detectIntent(message)
    const detectedLoc = detectLocation(message)

    const location = detectedLoc?.location ?? context.lastLocation
    const locationName = detectedLoc?.name ?? context.lastLocationName

    // Follow-up questions ("why risky", "safer zone") should continue talking about whatever date
    // was last in play, not silently reset to today when the message has no explicit date keyword.
    const isFollowUp = intent === 'follow_up_next_day' || intent === 'follow_up_safer_zone' || intent === 'follow_up_why_risky'
    const dateBase = isFollowUp && context.lastDate ? context.lastDate : today
    let date = detectDate(message, dateBase)
    if (intent === 'follow_up_next_day' && context.lastDate) {
      date = addDays(context.lastDate, 1)
    }

    const needsLocation = ['pfz_safety', 'hazard_query', 'chlorophyll_sst_exploration', 'follow_up_safer_zone'].includes(intent)
    const needsClarification = needsLocation && !location

    return {
      intent,
      location,
      locationName,
      date,
      needsClarification,
      clarificationQuestion: needsClarification ? 'Which port or coastal city are you starting from?' : undefined,
    }
  },
}
