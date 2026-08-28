import { ShieldAlert } from 'lucide-react'

export function DisclaimerBanner({ compact = false }: { compact?: boolean }) {
  return (
    <div className="flex items-start gap-2 rounded-lg border border-brand-200 bg-brand-50 px-3.5 py-2.5 text-brand-800">
      <ShieldAlert className="mt-0.5 h-4 w-4 shrink-0" />
      <p className="text-xs leading-relaxed">
        RetinaXAI is an <strong>AI-assisted screening and decision-support tool</strong> — it is not an autonomous
        diagnostic system. {!compact && 'Final diagnosis and treatment decisions must be made by a qualified ophthalmologist.'}
      </p>
    </div>
  )
}
