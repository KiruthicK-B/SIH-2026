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

      <div className="relative flex items-center gap-5">
        <div className="relative shrink-0">
          <div className="absolute inset-0 -m-3 rounded-full bg-brand-500/30 blur-2xl" />
          <div className="relative flex h-16 w-16 items-center justify-center rounded-2xl bg-white p-2.5 shadow-lg sm:h-20 sm:w-20">
            <img src="/logo-mark.png" alt="OneDesk" className="h-full w-full object-contain" />
          </div>
        </div>

        <div>
          <p className="text-2xl font-extrabold leading-none tracking-tight sm:text-3xl">
            <span className="text-white">One</span>
            <span className="bg-gradient-to-r from-sky-400 via-teal-400 to-emerald-400 bg-clip-text text-transparent">
              Desk
            </span>
          </p>
          <p className="mt-2 text-sm leading-snug text-slate-400 sm:text-base">
            Unified Services,
            <br />
            Seamless Access
          </p>
        </div>
      </div>

      <div className="relative mt-6 h-px bg-white/10" />
    </div>
  )
}
