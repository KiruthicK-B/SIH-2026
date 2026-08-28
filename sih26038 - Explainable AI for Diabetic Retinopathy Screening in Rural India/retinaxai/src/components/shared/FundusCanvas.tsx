import { useEffect, useRef } from 'react'

interface FundusCanvasProps {
  imageDataUrl: string
  size?: number
  background?: 'image' | 'black'
  draw?: (ctx: CanvasRenderingContext2D, w: number, h: number) => void
  className?: string
}

/** Renders the fundus image (or a black backdrop for vessel-only views) onto a fixed-size canvas,
 *  then invokes the supplied draw callback so lesion/vessel/Grad-CAM overlays stay pixel-aligned
 *  to the underlying image regardless of container sizing. */
export function FundusCanvas({ imageDataUrl, size = 420, background = 'image', draw, className }: FundusCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null)

  useEffect(() => {
    const canvas = canvasRef.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    let cancelled = false
    const img = new Image()
    img.onload = () => {
      if (cancelled) return
      ctx.clearRect(0, 0, size, size)

      ctx.save()
      ctx.beginPath()
      ctx.arc(size / 2, size / 2, size / 2 - 2, 0, Math.PI * 2)
      ctx.clip()

      if (background === 'black') {
        ctx.fillStyle = '#000000'
        ctx.fillRect(0, 0, size, size)
      } else {
        ctx.drawImage(img, 0, 0, size, size)
      }

      draw?.(ctx, size, size)
      ctx.restore()

      ctx.beginPath()
      ctx.arc(size / 2, size / 2, size / 2 - 1.5, 0, Math.PI * 2)
      ctx.lineWidth = 3
      ctx.strokeStyle = '#1f2937'
      ctx.stroke()
    }
    img.src = imageDataUrl

    return () => {
      cancelled = true
    }
  }, [imageDataUrl, size, background, draw])

  return <canvas ref={canvasRef} width={size} height={size} className={className} />
}
