import type { LatLng, PFZCell } from '@/data/types'
import { generatePFZGrid } from '@/data/mockPFZ'
import { mulberry32, hashStringToSeed, randFloat } from '@/lib/rng'

/** Simulated satellite-derived datasets (SST, chlorophyll-a, PFZ advisory layer). Values are seeded
 *  deterministically per lat/lon/date so the same query always returns the same "observation". */
export const MarineDataAgent = {
  getSST(lat: number, lon: number, date: string): number {
    const rng = mulberry32(hashStringToSeed(`sst|${lat.toFixed(2)}|${lon.toFixed(2)}|${date}`))
    return Math.round((28.6 + randFloat(rng, -1.3, 2.0)) * 10) / 10
  },

  getChlorophyll(lat: number, lon: number, date: string): number {
    const rng = mulberry32(hashStringToSeed(`chl|${lat.toFixed(2)}|${lon.toFixed(2)}|${date}`))
    return Math.round((0.4 + randFloat(rng, 0, 1.4)) * 100) / 100
  },

  getPFZLayer(date: string, coastAnchor?: LatLng): PFZCell[] {
    return generatePFZGrid(date, coastAnchor)
  },
}
