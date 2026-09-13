import type { Boundary, LatLng, PFZCell, PFZResult } from '@/data/types'
import { pfzBand } from '@/data/mockPFZ'
import { distanceKm as haversineKm, directionFrom, pointInPolygon, distanceToPolygonKm } from '@/lib/geo'

export interface GeofenceHit {
  boundary: Boundary
  inside: boolean
  distanceKm: number
}

const PROXIMITY_WARNING_KM = 8

export const GeospatialAgent = {
  distanceKm: haversineKm,

  findNearestPFZ(userLocation: LatLng, pfzGrid: PFZCell[], minLikelihood = 0): PFZResult | null {
    const candidates = pfzGrid.filter((c) => c.likelihood >= minLikelihood)
    if (candidates.length === 0) return null

    let best: PFZCell | null = null
    let bestDist = Infinity
    for (const cell of candidates) {
      const d = haversineKm(userLocation, { lat: cell.lat, lon: cell.lon })
      // Favor closer AND higher-likelihood cells rather than pure nearest-neighbor.
      const score = d - cell.likelihood * 25
      if (score < bestDist) {
        bestDist = score
        best = cell
      }
    }
    if (!best) return null

    const dist = haversineKm(userLocation, { lat: best.lat, lon: best.lon })
    return {
      center: { lat: best.lat, lon: best.lon },
      distanceKm: Math.round(dist),
      direction: directionFrom(userLocation, { lat: best.lat, lon: best.lon }),
      likelihood: best.likelihood,
      band: pfzBand(best.likelihood),
      id: `PFZ-${Math.round(best.lat * 100)}-${Math.round(best.lon * 100)}`,
    }
  },

  findSaferAlternative(userLocation: LatLng, pfzGrid: PFZCell[], excludeCenter: LatLng, boundaries: Boundary[]): PFZResult | null {
    const safeCandidates = pfzGrid.filter((c) => {
      const farFromExcluded = haversineKm({ lat: c.lat, lon: c.lon }, excludeCenter) > 12
      const clearOfBoundaries = boundaries.every((b) => distanceToPolygonKm({ lat: c.lat, lon: c.lon }, b.polygon) > PROXIMITY_WARNING_KM)
      return farFromExcluded && clearOfBoundaries && c.likelihood >= 0.3
    })
    return this.findNearestPFZ(userLocation, safeCandidates)
  },

  checkGeofencing(lat: number, lon: number, boundaries: Boundary[]): GeofenceHit[] {
    const point = { lat, lon }
    return boundaries
      .map((boundary) => {
        const inside = pointInPolygon(point, boundary.polygon)
        const distance = inside ? 0 : distanceToPolygonKm(point, boundary.polygon)
        return { boundary, inside, distanceKm: Math.round(distance) }
      })
      .filter((hit) => hit.inside || hit.distanceKm <= PROXIMITY_WARNING_KM)
      .sort((a, b) => a.distanceKm - b.distanceKm)
  },
}
