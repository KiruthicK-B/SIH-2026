import { mulberry32, hashStringToSeed, randFloat } from '@/lib/rng'
import type { LatLng, PFZCell } from './types'
import { distanceKm, destinationPoint } from '@/lib/geo'

const DEFAULT_COAST_ANCHOR: LatLng = { lat: 10.9, lon: 79.6 } // off Nagapattinam, Tamil Nadu

/** Deterministic mock PFZ grid: 3 offshore "hotspot" clusters (matching the PFZ-1/2/3 pattern shown
 *  in the reference dashboard) plus low-likelihood background cells, all seeded by date so results
 *  are stable within a day and shift gently from day to day. */
export function generatePFZGrid(date: string, coastAnchor: LatLng = DEFAULT_COAST_ANCHOR): PFZCell[] {
  const rng = mulberry32(hashStringToSeed('pfz|' + date + '|' + coastAnchor.lat.toFixed(2) + coastAnchor.lon.toFixed(2)))
  const cells: PFZCell[] = []

  const clusterCount = 3
  const clusters: { center: LatLng; strength: number; radiusKm: number }[] = []
  for (let i = 0; i < clusterCount; i++) {
    const bearing = randFloat(rng, 60, 140) // roughly east/southeast, out to sea
    const distance = 40 + i * 25 + randFloat(rng, -8, 8)
    const center = destinationPoint(coastAnchor, bearing, distance)
    clusters.push({
      center,
      strength: randFloat(rng, 0.6, 0.95) - i * 0.08,
      radiusKm: randFloat(rng, 14, 20),
    })
  }

  for (const cluster of clusters) {
    const cellCount = 14
    for (let i = 0; i < cellCount; i++) {
      const angle = randFloat(rng, 0, Math.PI * 2)
      const r = Math.sqrt(rng()) * cluster.radiusKm
      const point = destinationPoint(cluster.center, (angle * 180) / Math.PI, r)
      const falloff = Math.max(0, 1 - r / cluster.radiusKm)
      const likelihood = Math.min(0.97, cluster.strength * (0.55 + 0.45 * falloff) + randFloat(rng, -0.05, 0.05))
      const chlorophyll = 0.6 + likelihood * 1.6 + randFloat(rng, -0.1, 0.1)
      const sst = 29.5 + randFloat(rng, -1.2, 1.2) - likelihood * 0.6
      cells.push({ lat: point.lat, lon: point.lon, likelihood: Math.max(0.05, likelihood), sst, chlorophyll: Math.max(0.15, chlorophyll) })
    }
  }

  // Sparse low-likelihood background cells so the map doesn't look empty outside clusters.
  for (let i = 0; i < 18; i++) {
    const bearing = randFloat(rng, 40, 160)
    const distance = randFloat(rng, 10, 110)
    const point = destinationPoint(coastAnchor, bearing, distance)
    const nearestClusterDist = Math.min(...clusters.map((c) => distanceKm(point, c.center)))
    if (nearestClusterDist < 18) continue
    const likelihood = randFloat(rng, 0.05, 0.28)
    cells.push({
      lat: point.lat,
      lon: point.lon,
      likelihood,
      sst: 29.8 + randFloat(rng, -1, 1),
      chlorophyll: 0.3 + randFloat(rng, 0, 0.4),
    })
  }

  return cells
}

export function pfzBand(likelihood: number): 'Low' | 'Moderate' | 'High' {
  if (likelihood >= 0.65) return 'High'
  if (likelihood >= 0.35) return 'Moderate'
  return 'Low'
}
