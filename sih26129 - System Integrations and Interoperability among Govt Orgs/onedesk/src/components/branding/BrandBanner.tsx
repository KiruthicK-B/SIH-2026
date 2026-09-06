import { Wordmark } from '@/components/branding/Wordmark'

export function BrandBanner() {
  return (
    <div className="relative overflow-hidden rounded-xl bg-navy-950 px-6 py-7 sm:px-8 sm:py-8">
      <div
        className="pointer-events-none absolute inset-y-0 right-0 w-2/3"
        style={{
          backgroundImage: 'radial-gradient(rgba(255,255,255,0.14) 1px, transparent 1px)',
          backgroundSize: '16px 16px',
          maskImage: 'linear-gradient(to left, black, transparent)',
          WebkitMaskImage: 'linear-gradient(to left, black, transparent)',
        }}
      />

      <div className="relative">
        <Wordmark size="xl" dark />
        <p className="mt-2 text-sm leading-snug text-slate-400 sm:text-base">
          Unified Services,
          <br />
          Seamless Access
        </p>
      </div>

      <div className="relative mt-6 h-px bg-white/10" />
    </div>
  )
}
