import { type FormEvent, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, Navigate } from 'react-router-dom'
import { BrandBanner } from '@/components/branding/BrandBanner'
import { LanguageSwitcher } from '@/components/shared/LanguageSwitcher'
import { Button } from '@/components/ui/Button'
import { Input, Label } from '@/components/ui/Input'
import { Spinner } from '@/components/ui/Spinner'
import { useAuth } from '@/context/AuthContext'
import { DirectGrantError, directGrantLogin } from '@/lib/directGrantAuth'
import { persistDirectGrantTokens } from '@/lib/keycloak'

export default function Login() {
  const { t } = useTranslation()
  const { isAuthenticated, login } = useAuth()
  const [identifier, setIdentifier] = useState('')
  const [password, setPassword] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    setSubmitting(true)
    try {
      const tokens = await directGrantLogin(identifier, password)
      persistDirectGrantTokens(tokens)
      // Full reload, not a client-side navigate — keycloak-js's init() is one-shot,
      // so the freshly-persisted tokens are picked up on the next fresh module load.
      window.location.assign('/dashboard')
    } catch (err) {
      setError(err instanceof DirectGrantError ? err.message : t('login.genericError'))
      setSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-gray-50 px-4">
      <div className="fixed inset-x-0 top-0 h-1 bg-gradient-to-r from-[#FF9933] via-white to-[#138808]" />
      <div className="fixed right-4 top-4">
        <LanguageSwitcher />
      </div>
      <div className="w-full max-w-sm">
        <div className="mb-6">
          <BrandBanner />
        </div>

        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-xs">
          <h1 className="text-base font-semibold text-gray-900">{t('login.title')}</h1>

          <form onSubmit={handleSubmit} className="mt-5 space-y-4">
            <div>
              <Label htmlFor="identifier">{t('login.identifierLabel')}</Label>
              <Input
                id="identifier"
                autoFocus
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                placeholder={t('login.identifierPlaceholder')}
                disabled={submitting}
              />
              <p className="mt-1 text-xs text-gray-400">{t('login.identifierHint')}</p>
            </div>

            <div>
              <Label htmlFor="password">{t('login.passwordLabel')}</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                disabled={submitting}
              />
            </div>

            {error && (
              <p className="rounded-md bg-danger-50 px-3 py-2 text-xs font-medium text-danger-700">{error}</p>
            )}

            <Button type="submit" className="w-full" size="lg" disabled={submitting}>
              {submitting ? (
                <>
                  <Spinner size="sm" className="border-white/30 border-t-white" /> {t('login.signingIn')}
                </>
              ) : (
                t('login.submit')
              )}
            </Button>
          </form>

          <button
            type="button"
            onClick={() => login()}
            className="mt-4 block w-full text-center text-xs text-gray-400 hover:text-gray-600"
          >
            {t('login.federatedFallback')}
          </button>

          <p className="mt-4 border-t border-gray-100 pt-4 text-center text-xs text-gray-500">
            {t('login.newCitizen')}{' '}
            <Link to="/register" className="font-medium text-brand-600 hover:text-brand-700">
              {t('login.registerHere')}
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
