import { Link, Navigate } from 'react-router-dom'
import { Eye, ScanEye, Sparkles, ShieldCheck } from 'lucide-react'
import { useAuth } from '@/context/AuthContext'
import { DisclaimerBanner } from '@/components/shared/DisclaimerBanner'

export default function Landing() {
  const { isAuthenticated } = useAuth()
  if (isAuthenticated) return <Navigate to="/app/dashboard" replace />

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-navy-900 via-brand-900 to-navy-800 px-4">
      <div className="w-full max-w-md">
        <div className="rounded-2xl border border-white/10 bg-white/5 p-8 text-center backdrop-blur-sm shadow-2xl">
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-white/10">
            <Eye className="h-9 w-9 text-brand-300" />
          </div>
          <h1 className="text-2xl font-bold text-white">RetinaXAI</h1>
          <p className="mt-1 text-sm text-brand-200">
            Explainable AI-Based Diabetic Retinopathy Screening
          </p>

          <div className="my-6 flex justify-center">
            <div className="relative h-28 w-28 rounded-full border-4 border-brand-400/40">
              <div className="absolute inset-2 rounded-full bg-gradient-to-br from-orange-500 via-red-600 to-amber-800 opacity-80" />
              <ScanEye className="absolute inset-0 m-auto h-8 w-8 text-white/90" />
            </div>
          </div>

          <p className="text-xs leading-relaxed text-brand-100/80">
            AI-powered screening with explainability, clinical evidence &amp; workflow simulation for
            resource-constrained, telemedicine-oriented care.
          </p>

          <div className="mt-6 flex flex-col gap-3">
            <Link
              to="/login"
              className="flex items-center justify-center gap-2 rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-brand-600"
            >
              <Sparkles className="h-4 w-4" />
              Login / Register
            </Link>
          </div>

          <p className="mt-5 text-[11px] italic text-brand-200/70">Detect. Explain. Assist.</p>
        </div>

        <div className="mt-4">
          <DisclaimerBanner />
        </div>

        <div className="mt-4 flex items-center justify-center gap-1.5 text-[11px] text-brand-200/60">
          <ShieldCheck className="h-3.5 w-3.5" />
          SIH 2026 · PS 26038 · Screening &amp; clinical decision-support prototype
        </div>
      </div>
    </div>
  )
}
