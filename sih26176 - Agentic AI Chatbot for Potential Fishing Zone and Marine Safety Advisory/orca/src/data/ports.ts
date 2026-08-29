import type { Port } from './types'

export const ports: Port[] = [
  { name: 'Chennai', state: 'Tamil Nadu', location: { lat: 13.0827, lon: 80.2707 } },
  { name: 'Puducherry', state: 'Puducherry', location: { lat: 11.9416, lon: 79.8083 } },
  { name: 'Nagapattinam', state: 'Tamil Nadu', location: { lat: 10.7661, lon: 79.8449 } },
  { name: 'Rameswaram', state: 'Tamil Nadu', location: { lat: 9.2876, lon: 79.3129 } },
  { name: 'Tuticorin', state: 'Tamil Nadu', location: { lat: 8.7642, lon: 78.1348 } },
  { name: 'Visakhapatnam', state: 'Andhra Pradesh', location: { lat: 17.6868, lon: 83.2185 } },
  { name: 'Kakinada', state: 'Andhra Pradesh', location: { lat: 16.9891, lon: 82.2475 } },
  { name: 'Paradip', state: 'Odisha', location: { lat: 20.3149, lon: 86.6094 } },
  { name: 'Kochi', state: 'Kerala', location: { lat: 9.9312, lon: 76.2673 } },
  { name: 'Mangalore', state: 'Karnataka', location: { lat: 12.9141, lon: 74.856 } },
]

export function findPortByName(name: string): Port | undefined {
  const q = name.trim().toLowerCase()
  return ports.find((p) => p.name.toLowerCase() === q || p.name.toLowerCase().includes(q) || q.includes(p.name.toLowerCase()))
}
