import { mulberry32, randFloat } from './rng'
import type { AnatomicalLandmarks, LesionPoint, ScreeningResult } from './types'

const LESION_COLORS: Record<LesionPoint['type'], string> = {
  microaneurysms: '#f59e0b',
  hemorrhages: '#ef4444',
  hardExudates: '#22c55e',
  softExudates: '#3b82f6',
}

export function drawLesionOverlay(ctx: CanvasRenderingContext2D, w: number, h: number, points: LesionPoint[]) {
  ctx.save()
  for (const p of points) {
    ctx.beginPath()
    ctx.fillStyle = LESION_COLORS[p.type]
    ctx.globalAlpha = 0.85
    ctx.arc(p.x * w, p.y * h, p.r * w, 0, Math.PI * 2)
    ctx.fill()
    ctx.globalAlpha = 1
    ctx.lineWidth = 1
    ctx.strokeStyle = 'rgba(255,255,255,0.6)'
    ctx.stroke()
  }
  ctx.restore()
}

interface Branch {
  x: number
  y: number
  angle: number
  length: number
  width: number
  depth: number
}

/** Recursive branching vessel tree seeded from the same PRNG as the rest of the mock pipeline,
 *  radiating from the optic disc — visually similar to a segmented retinal vasculature map. */
export function drawVesselMap(
  ctx: CanvasRenderingContext2D,
  w: number,
  h: number,
  landmarks: AnatomicalLandmarks,
  seed: number,
  color = '#ffffff',
) {
  const rng = mulberry32(seed ^ 0x5bd1e995)
  ctx.save()
  ctx.strokeStyle = color
  ctx.lineCap = 'round'

  const originX = landmarks.opticDisc.x * w
  const originY = landmarks.opticDisc.y * h

  const trunks = 5
  const stack: Branch[] = []
  for (let i = 0; i < trunks; i++) {
    const baseAngle = (Math.PI * 2 * i) / trunks + randFloat(rng, -0.3, 0.3)
    stack.push({
      x: originX,
      y: originY,
      angle: baseAngle,
      length: randFloat(rng, w * 0.16, w * 0.24),
      width: randFloat(rng, 2.6, 3.6),
      depth: 0,
    })
  }

  function branch(b: Branch) {
    const x2 = b.x + Math.cos(b.angle) * b.length
    const y2 = b.y + Math.sin(b.angle) * b.length
    ctx.lineWidth = b.width
    ctx.globalAlpha = 0.9 - b.depth * 0.08
    ctx.beginPath()
    ctx.moveTo(b.x, b.y)
    const midX = (b.x + x2) / 2 + randFloat(rng, -6, 6)
    const midY = (b.y + y2) / 2 + randFloat(rng, -6, 6)
    ctx.quadraticCurveTo(midX, midY, x2, y2)
    ctx.stroke()

    if (b.depth >= 6 || b.width < 0.5) return
    const children = rng() > 0.35 ? 2 : 1
    for (let i = 0; i < children; i++) {
      branch({
        x: x2,
        y: y2,
        angle: b.angle + randFloat(rng, -0.7, 0.7) * (i === 0 ? 1 : -1),
        length: b.length * randFloat(rng, 0.62, 0.78),
        width: b.width * randFloat(rng, 0.62, 0.78),
        depth: b.depth + 1,
      })
    }
  }

  for (const t of stack) branch(t)
  ctx.globalAlpha = 1
  ctx.restore()
}

/** Grad-CAM-style radial "jet" colormap heatmap centered on the model's mock attention region. */
export function drawGradCam(
  ctx: CanvasRenderingContext2D,
  w: number,
  h: number,
  center: { x: number; y: number },
  radius: number,
  seed: number,
) {
  const rng = mulberry32(seed ^ 0x27d4eb2f)
  const cx = center.x * w
  const cy = center.y * h
  const r = radius * Math.max(w, h)

  ctx.save()
  ctx.globalCompositeOperation = 'source-over'

  // A few offset secondary blobs give the heatmap organic, non-perfectly-circular shape.
  const blobs = [
    { dx: 0, dy: 0, scale: 1 },
    { dx: randFloat(rng, -0.4, 0.4) * r, dy: randFloat(rng, -0.3, 0.3) * r, scale: 0.6 },
    { dx: randFloat(rng, -0.3, 0.3) * r, dy: randFloat(rng, -0.4, 0.4) * r, scale: 0.45 },
  ]

  for (const blob of blobs) {
    const bx = cx + blob.dx
    const by = cy + blob.dy
    const br = r * blob.scale
    const gradient = ctx.createRadialGradient(bx, by, 0, bx, by, br)
    gradient.addColorStop(0, 'rgba(239, 68, 68, 0.85)')
    gradient.addColorStop(0.35, 'rgba(249, 115, 22, 0.65)')
    gradient.addColorStop(0.6, 'rgba(234, 179, 8, 0.45)')
    gradient.addColorStop(0.8, 'rgba(59, 130, 246, 0.25)')
    gradient.addColorStop(1, 'rgba(59, 130, 246, 0)')
    ctx.fillStyle = gradient
    ctx.beginPath()
    ctx.arc(bx, by, br, 0, Math.PI * 2)
    ctx.fill()
  }
  ctx.restore()
}

export function drawLandmarkMarkers(ctx: CanvasRenderingContext2D, w: number, h: number, landmarks: AnatomicalLandmarks) {
  ctx.save()
  ctx.lineWidth = 2.5

  ctx.strokeStyle = '#22c55e'
  ctx.beginPath()
  ctx.arc(landmarks.opticDisc.x * w, landmarks.opticDisc.y * h, w * 0.045, 0, Math.PI * 2)
  ctx.stroke()

  ctx.strokeStyle = '#eab308'
  ctx.beginPath()
  ctx.arc(landmarks.fovea.x * w, landmarks.fovea.y * h, w * 0.025, 0, Math.PI * 2)
  ctx.stroke()
  ctx.restore()
}

export function pixelToLabel(v: { x: number; y: number }, w: number, h: number) {
  return `(${Math.round(v.x * w)}, ${Math.round(v.y * h)})`
}

export function lesionLegend() {
  return [
    { key: 'microaneurysms', label: 'Microaneurysms', color: LESION_COLORS.microaneurysms },
    { key: 'hemorrhages', label: 'Hemorrhages', color: LESION_COLORS.hemorrhages },
    { key: 'hardExudates', label: 'Hard Exudates', color: LESION_COLORS.hardExudates },
    { key: 'softExudates', label: 'Soft Exudates', color: LESION_COLORS.softExudates },
  ] as const
}

export type { ScreeningResult }
