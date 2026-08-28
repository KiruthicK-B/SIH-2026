import { mulberry32, randFloat } from './rng'

/** Generates a stylized placeholder retinal fundus photo (radial vignette + optic-disc glow + vessel
 *  hints) entirely on canvas, so the demo has believable sample images without shipping real patient data. */
export function generateSyntheticFundus(seed: number, size = 512): string {
  const canvas = document.createElement('canvas')
  canvas.width = size
  canvas.height = size
  const ctx = canvas.getContext('2d')!
  const rng = mulberry32(seed)

  const cx = size / 2
  const cy = size / 2
  const radius = size * 0.47

  ctx.fillStyle = '#050302'
  ctx.fillRect(0, 0, size, size)

  const baseHue = randFloat(rng, 10, 24)
  const grad = ctx.createRadialGradient(cx, cy, radius * 0.1, cx, cy, radius)
  grad.addColorStop(0, `hsl(${baseHue}, 78%, 42%)`)
  grad.addColorStop(0.55, `hsl(${baseHue}, 72%, 30%)`)
  grad.addColorStop(1, `hsl(${baseHue}, 65%, 14%)`)

  ctx.save()
  ctx.beginPath()
  ctx.arc(cx, cy, radius, 0, Math.PI * 2)
  ctx.closePath()
  ctx.clip()
  ctx.fillStyle = grad
  ctx.fillRect(0, 0, size, size)

  // Optic disc glow
  const odX = cx - radius * 0.28
  const odY = cy + radius * 0.05
  const odGrad = ctx.createRadialGradient(odX, odY, 2, odX, odY, radius * 0.22)
  odGrad.addColorStop(0, 'rgba(255, 214, 153, 0.95)')
  odGrad.addColorStop(1, 'rgba(255, 214, 153, 0)')
  ctx.fillStyle = odGrad
  ctx.beginPath()
  ctx.arc(odX, odY, radius * 0.22, 0, Math.PI * 2)
  ctx.fill()

  // Faint vessel hints radiating from optic disc
  ctx.strokeStyle = 'rgba(120, 20, 20, 0.35)'
  for (let i = 0; i < 10; i++) {
    const angle = randFloat(rng, 0, Math.PI * 2)
    const len = randFloat(rng, radius * 0.3, radius * 0.75)
    ctx.lineWidth = randFloat(rng, 1, 2.4)
    ctx.beginPath()
    ctx.moveTo(odX, odY)
    const midX = odX + Math.cos(angle) * len * 0.5 + randFloat(rng, -20, 20)
    const midY = odY + Math.sin(angle) * len * 0.5 + randFloat(rng, -20, 20)
    const endX = odX + Math.cos(angle) * len
    const endY = odY + Math.sin(angle) * len
    ctx.quadraticCurveTo(midX, midY, endX, endY)
    ctx.stroke()
  }

  // Subtle mottling for texture
  ctx.globalAlpha = 0.06
  for (let i = 0; i < 400; i++) {
    const a = randFloat(rng, 0, Math.PI * 2)
    const d = randFloat(rng, 0, radius)
    const x = cx + Math.cos(a) * d
    const y = cy + Math.sin(a) * d
    ctx.fillStyle = rng() > 0.5 ? '#000000' : '#ffb37a'
    ctx.beginPath()
    ctx.arc(x, y, randFloat(rng, 1, 4), 0, Math.PI * 2)
    ctx.fill()
  }
  ctx.globalAlpha = 1

  // Vignette ring
  ctx.strokeStyle = 'rgba(0,0,0,0.5)'
  ctx.lineWidth = radius * 0.08
  ctx.beginPath()
  ctx.arc(cx, cy, radius - radius * 0.04, 0, Math.PI * 2)
  ctx.stroke()

  ctx.restore()

  return canvas.toDataURL('image/jpeg', 0.92)
}
