import { type FormEvent, useState } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { BrandBanner } from '@/components/branding/BrandBanner'
import { Button } from '@/components/ui/Button'
import { Input, Label } from '@/components/ui/Input'
import { Spinner } from '@/components/ui/Spinner'
import { useAuth } from '@/context/AuthContext'

export default function Login() {
  const { isAuthenticated, login } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [citizenId, setCitizenId] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />
  }

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    if (!citizenId.trim() || !password.trim()) {
      setError('Enter a citizen ID and password to continue.')
      return
    }
    setError('')
    setIsSubmitting(true)
    setTimeout(() => {
      login(citizenId.trim(), password)
      const redirectTo = (location.state as { from?: string } | null)?.from ?? '/dashboard'
      navigate(redirectTo, { replace: true })
    }, 700)
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-sm">
        <div className="mb-6">
          <BrandBanner />
        </div>

        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-xs">
          <h1 className="text-base font-semibold text-gray-900">Sign in to your account</h1>
          <p className="mt-1 text-sm text-gray-500">Access every connected government service from one login.</p>

          <form onSubmit={handleSubmit} className="mt-5 space-y-4">
            <div>
              <Label htmlFor="citizenId">Citizen ID / Username</Label>
              <Input
                id="citizenId"
                autoFocus
                disabled={isSubmitting}
                value={citizenId}
                onChange={(e) => setCitizenId(e.target.value)}
                placeholder="e.g. CIT-10282"
              />
            </div>
            <div>
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                disabled={isSubmitting}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
              />
            </div>

            {error && <p className="text-xs font-medium text-danger-600">{error}</p>}

            <Button type="submit" className="w-full" size="lg" disabled={isSubmitting}>
              {isSubmitting ? (
                <>
                  <Spinner size="sm" className="border-white/30 border-t-white" /> Signing in…
                </>
              ) : (
                'Sign In'
              )}
            </Button>
          </form>

          <p className="mt-4 text-center text-xs text-gray-400">
            Demo environment — any ID and password will sign you in.
          </p>
        </div>
      </div>
    </div>
  )
}
