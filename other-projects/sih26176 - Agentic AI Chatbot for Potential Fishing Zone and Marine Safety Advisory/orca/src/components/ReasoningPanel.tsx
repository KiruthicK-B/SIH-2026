import { useState } from 'react'
import { ChevronDown, Brain } from 'lucide-react'
import type { Explanation } from '@/data/types'
import { cn } from '@/lib/utils'

export function ReasoningPanel({ explanation, defaultOpen = false }: { explanation: Explanation; defaultOpen?: boolean }) {
  const [open, setOpen] = useState(defaultOpen)

  return (
    <div className="rounded-lg border border-navy-600 bg-navy-800/40">
      <button
        onClick={() => setOpen((o) => !o)}
        className="flex w-full items-center justify-between gap-2 px-3 py-2.5 text-left"
      >
        <span className="flex items-center gap-2 text-xs font-semibold text-cyan-400">
          <Brain className="h-3.5 w-3.5" /> Show reasoning
        </span>
        <ChevronDown className={cn('h-4 w-4 text-slate-400 transition-transform', open && 'rotate-180')} />
      </button>

      {open && (
        <div className="space-y-3 border-t border-navy-600 px-3 py-3">
          <p className="text-xs leading-relaxed text-slate-300">{explanation.summary}</p>

          <div>
            <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-wide text-slate-500">Steps</p>
            <ol className="space-y-1">
              {explanation.steps.map((step, i) => (
                <li key={i} className="flex gap-2 text-[11px] leading-relaxed text-slate-300">
                  <span className="shrink-0 text-cyan-500">{i + 1}.</span>
                  {step}
                </li>
              ))}
            </ol>
          </div>

          <div>
            <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-wide text-slate-500">Rules applied</p>
            <ul className="space-y-1">
              {explanation.rulesApplied.map((rule, i) => (
                <li key={i} className="text-[11px] leading-relaxed text-slate-300">
                  • {rule}
                </li>
              ))}
            </ul>
          </div>

          <div>
            <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-wide text-slate-500">Data references</p>
            <ul className="space-y-1">
              {explanation.dataReferences.map((ref, i) => (
                <li key={i} className="text-[11px] italic leading-relaxed text-slate-500">
                  {ref}
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}
    </div>
  )
}
