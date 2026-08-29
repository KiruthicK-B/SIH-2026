import type { Boundary } from './types'

/** Simplified, illustrative boundary polygons near the Tamil Nadu / Bay of Bengal coast — not
 *  survey-accurate, adequate for a POC geofencing demo. */
export function getBoundaries(): Boundary[] {
  const boundaries: Boundary[] = [
    {
      name: 'India–Sri Lanka International Maritime Boundary Line',
      type: 'International',
      polygon: [
        { lat: 10.6, lon: 80.1 },
        { lat: 10.1, lon: 80.05 },
        { lat: 9.6, lon: 79.7 },
        { lat: 9.1, lon: 79.4 },
        { lat: 8.9, lon: 79.6 },
        { lat: 9.4, lon: 79.9 },
        { lat: 9.9, lon: 80.25 },
        { lat: 10.5, lon: 80.35 },
      ],
    },
    {
      name: 'Gulf of Mannar Marine National Park',
      type: 'MPA',
      polygon: [
        { lat: 9.32, lon: 78.98 },
        { lat: 9.22, lon: 79.15 },
        { lat: 9.02, lon: 79.28 },
        { lat: 8.85, lon: 79.05 },
        { lat: 8.9, lon: 78.75 },
        { lat: 9.1, lon: 78.72 },
      ],
    },
    {
      name: 'Naval Exercise Restricted Zone – Chennai Offshore',
      type: 'Restricted',
      polygon: [
        { lat: 13.25, lon: 80.55 },
        { lat: 13.05, lon: 80.75 },
        { lat: 12.8, lon: 80.65 },
        { lat: 12.85, lon: 80.4 },
        { lat: 13.1, lon: 80.35 },
      ],
    },
  ]
  return boundaries
}
