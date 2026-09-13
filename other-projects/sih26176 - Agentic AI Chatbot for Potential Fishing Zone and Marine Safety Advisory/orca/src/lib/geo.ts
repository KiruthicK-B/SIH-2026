import type { LatLng } from '@/data/types'

const EARTH_RADIUS_KM = 6371

function toRad(deg: number) {
  return (deg * Math.PI) / 180
}

function toDeg(rad: number) {
  return (rad * 180) / Math.PI
}

/** Great-circle distance between two points, in kilometers. */
export function distanceKm(a: LatLng, b: LatLng): number {
  const dLat = toRad(b.lat - a.lat)
  const dLon = toRad(b.lon - a.lon)
  const lat1 = toRad(a.lat)
  const lat2 = toRad(b.lat)

  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(h))
}

/** Destination point given a start, bearing (degrees, 0=N/clockwise), and distance in km. */
export function destinationPoint(start: LatLng, bearingDeg: number, distanceKm: number): LatLng {
  const brng = toRad(bearingDeg)
  const lat1 = toRad(start.lat)
  const lon1 = toRad(start.lon)
  const dOverR = distanceKm / EARTH_RADIUS_KM

  const lat2 = Math.asin(Math.sin(lat1) * Math.cos(dOverR) + Math.cos(lat1) * Math.sin(dOverR) * Math.cos(brng))
  const lon2 = lon1 + Math.atan2(Math.sin(brng) * Math.sin(dOverR) * Math.cos(lat1), Math.cos(dOverR) - Math.sin(lat1) * Math.sin(lat2))

  return { lat: toDeg(lat2), lon: toDeg(lon2) }
}

/** Initial bearing from a to b, in degrees (0=N, 90=E). */
export function bearingDegrees(a: LatLng, b: LatLng): number {
  const lat1 = toRad(a.lat)
  const lat2 = toRad(b.lat)
  const dLon = toRad(b.lon - a.lon)
  const y = Math.sin(dLon) * Math.cos(lat2)
  const x = Math.cos(lat1) * Math.sin(lat2) - Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLon)
  return (toDeg(Math.atan2(y, x)) + 360) % 360
}

const COMPASS = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW']

export function bearingToCompass(bearingDeg: number): string {
  const index = Math.round(bearingDeg / 22.5) % 16
  return COMPASS[index]
}

export function directionFrom(a: LatLng, b: LatLng): string {
  return bearingToCompass(bearingDegrees(a, b))
}

/** Even-odd ray casting point-in-polygon test on a simple lat/lon polygon. */
export function pointInPolygon(point: LatLng, polygon: LatLng[]): boolean {
  let inside = false
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i].lon
    const yi = polygon[i].lat
    const xj = polygon[j].lon
    const yj = polygon[j].lat
    const intersect = yi > point.lat !== yj > point.lat && point.lon < ((xj - xi) * (point.lat - yi)) / (yj - yi) + xi
    if (intersect) inside = !inside
  }
  return inside
}

/** Minimum distance in km from a point to a polygon's edges — used for "how close to this boundary" checks. */
export function distanceToPolygonKm(point: LatLng, polygon: LatLng[]): number {
  let min = Infinity
  for (let i = 0; i < polygon.length; i++) {
    const a = polygon[i]
    const b = polygon[(i + 1) % polygon.length]
    min = Math.min(min, distanceToSegmentKm(point, a, b))
  }
  return min
}

function distanceToSegmentKm(p: LatLng, a: LatLng, b: LatLng): number {
  // Approximate by sampling the segment — adequate at the regional scale used here.
  const steps = 20
  let min = Infinity
  for (let i = 0; i <= steps; i++) {
    const t = i / steps
    const sample: LatLng = { lat: a.lat + (b.lat - a.lat) * t, lon: a.lon + (b.lon - a.lon) * t }
    min = Math.min(min, distanceKm(p, sample))
  }
  return min
}
