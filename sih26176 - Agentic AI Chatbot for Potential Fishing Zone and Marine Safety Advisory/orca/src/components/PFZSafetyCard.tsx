import { Fish, Navigation, ShieldCheck } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from './ui/Card'
import { PFZBandBadge, SafetyBadge } from './ui/Badge'
import type { PFZResult, SafetyResult } from '@/data/types'

export function PFZSafetyCard({ pfzResult, safety, date }: { pfzResult?: PFZResult; safety?: SafetyResult; date: string }) {
  if (!pfzResult && !safety) return null

  return (
    <Card>
      <CardHeader>
        <CardTitle>PFZ &amp; Safety Summary</CardTitle>
        <span className="text-[11px] text-slate-400">{date}</span>
      </CardHeader>
      <CardContent className="space-y-4">
        {pfzResult && (
          <div>
            <p className="mb-2 flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wide text-slate-400">
              <Fish className="h-3.5 w-3.5" /> Nearest Potential Fishing Zone
            </p>
            <div className="grid grid-cols-3 gap-3 text-center">
              <div className="rounded-lg bg-navy-700/60 py-2.5">
                <p className="text-lg font-bold text-white">{pfzResult.distanceKm} km</p>
                <p className="text-[10px] text-slate-400">Distance</p>
              </div>
              <div className="rounded-lg bg-navy-700/60 py-2.5">
                <p className="flex items-center justify-center gap-1 text-lg font-bold text-white">
                  <Navigation className="h-3.5 w-3.5 text-cyan-400" /> {pfzResult.direction}
                </p>
                <p className="text-[10px] text-slate-400">Direction</p>
              </div>
              <div className="rounded-lg bg-navy-700/60 py-2.5">
                <p className="text-lg font-bold text-white">{Math.round(pfzResult.likelihood * 100)}%</p>
                <p className="text-[10px] text-slate-400">Likelihood</p>
              </div>
            </div>
            <div className="mt-2 flex justify-center">
              <PFZBandBadge band={pfzResult.band} />
            </div>
          </div>
        )}

        {safety && (
          <div className="border-t border-navy-600 pt-4">
            <p className="mb-2 flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wide text-slate-400">
              <ShieldCheck className="h-3.5 w-3.5" /> Safety Assessment
            </p>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="relative h-14 w-14">
                  <svg viewBox="0 0 60 60" className="h-14 w-14 -rotate-90">
                    <circle cx="30" cy="30" r="26" fill="none" stroke="#1c3a56" strokeWidth="6" />
                    <circle
                      cx="30"
                      cy="30"
                      r="26"
                      fill="none"
                      stroke={safety.category === 'Safe' ? '#22c55e' : safety.category === 'Caution' ? '#f59e0b' : '#ef4444'}
                      strokeWidth="6"
                      strokeLinecap="round"
                      strokeDasharray={2 * Math.PI * 26}
                      strokeDashoffset={2 * Math.PI * 26 * (1 - safety.score / 100)}
                    />
                  </svg>
                  <span className="absolute inset-0 flex items-center justify-center text-sm font-bold text-white">{safety.score}</span>
                </div>
                <SafetyBadge category={safety.category} />
              </div>
            </div>
            <ul className="mt-3 space-y-1.5">
              {safety.warnings.map((w, i) => (
                <li key={i} className="text-xs leading-relaxed text-slate-300">
                  • {w}
                </li>
              ))}
            </ul>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
