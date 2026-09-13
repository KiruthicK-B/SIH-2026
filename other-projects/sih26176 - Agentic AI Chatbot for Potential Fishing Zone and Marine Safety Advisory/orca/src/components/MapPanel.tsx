import { useEffect, useMemo } from 'react'
import { MapContainer, TileLayer, Circle, Marker, Polygon, Polyline, Popup, useMap } from 'react-leaflet'
import L from 'leaflet'
import type { Boundary, LatLng, MapLayers, PFZCell, PFZResult } from '@/data/types'

const BOUNDARY_COLOR: Record<Boundary['type'], string> = {
  International: '#38bdf8',
  Restricted: '#ef4444',
  MPA: '#22c55e',
}

/** Interpolates PFZ likelihood (0–1) to a blue→green→yellow→red colormap, matching the vertical
 *  "PFZ Probability" legend in the reference dashboard (red = high, blue = low). */
function likelihoodToColor(likelihood: number): string {
  const stops: Array<[number, [number, number, number]]> = [
    [0, [56, 130, 246]], // blue
    [0.4, [34, 197, 94]], // green
    [0.7, [234, 179, 8]], // yellow
    [1, [239, 68, 68]], // red
  ]
  let lo = stops[0]
  let hi = stops[stops.length - 1]
  for (let i = 0; i < stops.length - 1; i++) {
    if (likelihood >= stops[i][0] && likelihood <= stops[i + 1][0]) {
      lo = stops[i]
      hi = stops[i + 1]
      break
    }
  }
  const span = hi[0] - lo[0] || 1
  const t = (likelihood - lo[0]) / span
  const rgb = lo[1].map((c, i) => Math.round(c + (hi[1][i] - c) * t))
  return `rgb(${rgb[0]}, ${rgb[1]}, ${rgb[2]})`
}

function userIcon() {
  return L.divIcon({
    className: '',
    html: `<div style="width:16px;height:16px;border-radius:50%;background:#22d3ee;border:3px solid #0a1929;box-shadow:0 0 0 2px #22d3ee55"></div>`,
    iconSize: [16, 16],
    iconAnchor: [8, 8],
  })
}

function pfzIcon() {
  return L.divIcon({
    className: '',
    html: `<div style="width:14px;height:14px;transform:rotate(45deg);background:#f59e0b;border:2px solid #0a1929;"></div>`,
    iconSize: [14, 14],
    iconAnchor: [7, 7],
  })
}

function RecenterOnChange({ center }: { center: LatLng }) {
  const map = useMap()
  useMemo(() => {
    map.setView([center.lat, center.lon], map.getZoom(), { animate: true })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [center.lat, center.lon])
  return null
}

/** Leaflet measures its container at mount time. Inside flex/grid layouts the container can still be
 *  zero-height at that instant (before the surrounding layout settles), which renders a blank map
 *  until something forces a resize. This recalculates the size once layout has actually painted, and
 *  again on window resize. */
function InvalidateSizeOnMount() {
  const map = useMap()
  useEffect(() => {
    const handleResize = () => map.invalidateSize()
    const raf = requestAnimationFrame(handleResize)
    const timeout = setTimeout(handleResize, 250)
    window.addEventListener('resize', handleResize)
    return () => {
      cancelAnimationFrame(raf)
      clearTimeout(timeout)
      window.removeEventListener('resize', handleResize)
    }
  }, [map])
  return null
}

interface MapPanelProps {
  center: LatLng
  zoom?: number
  layers: MapLayers
  pfzGrid: PFZCell[]
  userLocation: LatLng
  pfzResult?: PFZResult | null
  boundaries: Boundary[]
  waveHeightM?: number
  heightClassName?: string
}

export function MapPanel({ center, zoom = 8, layers, pfzGrid, userLocation, pfzResult, boundaries, waveHeightM, heightClassName = 'h-full' }: MapPanelProps) {
  const userMarkerIcon = useMemo(() => userIcon(), [])
  const pfzMarkerIcon = useMemo(() => pfzIcon(), [])

  return (
    <div className={`overflow-hidden rounded-xl border border-navy-600 ${heightClassName}`}>
      <MapContainer center={[center.lat, center.lon]} zoom={zoom} className="h-full w-full" scrollWheelZoom>
        <TileLayer
          attribution='&copy; OpenStreetMap contributors, &copy; CARTO'
          url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
        />

        <InvalidateSizeOnMount />
        <RecenterOnChange center={center} />

        {layers.pfz &&
          pfzGrid.map((cell, i) => (
            <Circle
              key={i}
              center={[cell.lat, cell.lon]}
              radius={4200}
              pathOptions={{ color: likelihoodToColor(cell.likelihood), fillColor: likelihoodToColor(cell.likelihood), fillOpacity: 0.35, weight: 1, opacity: 0.6 }}
            >
              <Popup>
                <div className="text-xs">
                  <p className="font-semibold">PFZ cell</p>
                  <p>Likelihood: {Math.round(cell.likelihood * 100)}%</p>
                  <p>SST: {cell.sst.toFixed(1)}°C</p>
                  <p>Chlorophyll-a: {cell.chlorophyll.toFixed(2)} mg/m³</p>
                </div>
              </Popup>
            </Circle>
          ))}

        {layers.waves && waveHeightM !== undefined && (
          <Circle
            center={[userLocation.lat, userLocation.lon]}
            radius={25000}
            pathOptions={{
              color: waveHeightM > 2.5 ? '#ef4444' : waveHeightM > 1.5 ? '#f59e0b' : '#38bdf8',
              fillOpacity: 0.06,
              weight: 1.5,
              dashArray: '3 8',
            }}
          >
            <Popup>
              <div className="text-xs">
                <p className="font-semibold">Sea state</p>
                <p>Wave height: {waveHeightM.toFixed(1)} m</p>
              </div>
            </Popup>
          </Circle>
        )}

        {layers.boundaries &&
          boundaries.map((b) => (
            <Polygon
              key={b.name}
              positions={b.polygon.map((p) => [p.lat, p.lon])}
              pathOptions={{ color: BOUNDARY_COLOR[b.type], fillColor: BOUNDARY_COLOR[b.type], fillOpacity: 0.12, weight: 2, dashArray: b.type === 'International' ? '6 6' : undefined }}
            >
              <Popup>
                <div className="text-xs">
                  <p className="font-semibold">{b.name}</p>
                  <p>Type: {b.type}</p>
                </div>
              </Popup>
            </Polygon>
          ))}

        <Marker position={[userLocation.lat, userLocation.lon]} icon={userMarkerIcon}>
          <Popup>Your location / port</Popup>
        </Marker>

        {pfzResult && (
          <>
            <Marker position={[pfzResult.center.lat, pfzResult.center.lon]} icon={pfzMarkerIcon}>
              <Popup>
                <div className="text-xs">
                  <p className="font-semibold">Nearest PFZ</p>
                  <p>{pfzResult.distanceKm} km {pfzResult.direction}</p>
                  <p>Likelihood: {Math.round(pfzResult.likelihood * 100)}% ({pfzResult.band})</p>
                </div>
              </Popup>
            </Marker>
            <Polyline
              positions={[
                [userLocation.lat, userLocation.lon],
                [pfzResult.center.lat, pfzResult.center.lon],
              ]}
              pathOptions={{ color: '#22d3ee', weight: 2, dashArray: '4 6', opacity: 0.8 }}
            />
          </>
        )}
      </MapContainer>
    </div>
  )
}
