import type { PFZCell } from '@/data/types'

const CHLOROPHYLL_THRESHOLD = 1.0 // mg/m³
const SST_GRADIENT_THRESHOLD = 0.8 // °C, mock thermal-front proxy

/** Derives PFZ likelihood from chlorophyll concentration and an SST-gradient proxy — high
 *  chlorophyll plus a sharp thermal front is the classic upwelling/front signature fishers use. */
export const OceanAnalyticsAgent = {
  computePFZLikelihood(sst: number, chlorophyll: number): number {
    const sstGradientProxy = Math.abs(sst - 29.0)
    let likelihood = 0.2
    if (chlorophyll > CHLOROPHYLL_THRESHOLD && sstGradientProxy > SST_GRADIENT_THRESHOLD) {
      likelihood = 0.75 + Math.min(0.2, (chlorophyll - CHLOROPHYLL_THRESHOLD) * 0.15)
    } else if (chlorophyll > CHLOROPHYLL_THRESHOLD || sstGradientProxy > SST_GRADIENT_THRESHOLD) {
      likelihood = 0.45 + Math.min(0.2, chlorophyll * 0.1)
    }
    return Math.min(0.97, Math.max(0.05, likelihood))
  },

  rankHighLikelihoodCells(grid: PFZCell[], topN = 5): PFZCell[] {
    return [...grid].sort((a, b) => b.likelihood - a.likelihood).slice(0, topN)
  },

  explainCorrelation(cell: PFZCell): string {
    const highChl = cell.chlorophyll > CHLOROPHYLL_THRESHOLD
    const frontStrength = Math.abs(cell.sst - 29.0) > SST_GRADIENT_THRESHOLD
    if (highChl && frontStrength) {
      return `Chlorophyll-a of ${cell.chlorophyll.toFixed(2)} mg/m³ with a pronounced thermal front (SST ${cell.sst.toFixed(1)}°C) indicates nutrient upwelling — a strong PFZ signal.`
    }
    if (highChl) {
      return `Elevated chlorophyll-a (${cell.chlorophyll.toFixed(2)} mg/m³) but a weak thermal gradient — moderate PFZ potential.`
    }
    return `SST and chlorophyll are both close to regional baseline — low PFZ potential in this cell.`
  },
}
