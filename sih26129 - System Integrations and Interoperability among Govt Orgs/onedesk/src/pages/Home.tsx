import { Building2, FileCheck2, KeyRound, ShieldCheck } from 'lucide-react'
import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, Navigate } from 'react-router-dom'
import { Wordmark } from '@/components/branding/Wordmark'
import { LanguageSwitcher } from '@/components/shared/LanguageSwitcher'
import { Button } from '@/components/ui/Button'
import { useAuth } from '@/context/AuthContext'
import { useRole } from '@/context/RoleContext'

const TEXT_SIZES = ['text-base', 'text-lg', 'text-xl'] as const

export default function Home() {
  const { t, i18n } = useTranslation()
  const { isAuthenticated } = useAuth()
  const { isAdminOnly } = useRole()
  const [textSizeIdx, setTextSizeIdx] = useState(1)

  if (isAuthenticated) {
    return <Navigate to={isAdminOnly ? '/platform' : '/dashboard'} replace />
  }

  const features = [
    { icon: KeyRound, title: t('home.featureKeycloakTitle'), description: t('home.featureKeycloakDescription') },
    { icon: ShieldCheck, title: t('home.featureConsentTitle'), description: t('home.featureConsentDescription') },
    { icon: Building2, title: t('home.featureConnectorsTitle'), description: t('home.featureConnectorsDescription') },
    { icon: FileCheck2, title: t('home.featureTrackingTitle'), description: t('home.featureTrackingDescription') },
  ]

  const stats = [
    { label: t('home.statsLiveConnectors'), value: '5' },
    { label: t('home.statsDepartmentsModeled'), value: '10' },
    { label: t('home.statsIamAuthority'), value: 'Keycloak' },
  ]

  return (
    <div className={TEXT_SIZES[textSizeIdx]}>
      {/* Accessibility utility bar — a real skip link, functional text-size controls,
          and a real language switcher, matching the GIGW accessibility-tooling
          convention. */}
      <div className="flex items-center justify-between gap-4 bg-navy-950 px-4 py-1.5 text-xs text-slate-300">
        <a href="#main" className="rounded-sm underline-offset-2 hover:text-white hover:underline">
          {t('common.skipToMain')}
        </a>
        <div className="flex items-center gap-4">
          <LanguageSwitcher variant="dark" />
          <a href="#accessibility" className="hover:text-white hover:underline">
            {t('common.accessibility')}
          </a>
          <div className="flex items-center gap-1" role="group" aria-label={t('common.textSize')}>
            <span className="mr-1 text-slate-400">{t('common.textSize')}</span>
            <button
              type="button"
              onClick={() => setTextSizeIdx((i) => Math.max(0, i - 1))}
              className="flex h-5 w-5 items-center justify-center rounded border border-white/20 text-[10px] hover:bg-white/10"
              aria-label={t('common.decreaseTextSize')}
            >
              A−
            </button>
            <button
              type="button"
              onClick={() => setTextSizeIdx(1)}
              className="flex h-5 w-5 items-center justify-center rounded border border-white/20 text-[10px] hover:bg-white/10"
              aria-label={t('common.resetTextSize')}
            >
              A
            </button>
            <button
              type="button"
              onClick={() => setTextSizeIdx((i) => Math.min(2, i + 1))}
              className="flex h-5 w-5 items-center justify-center rounded border border-white/20 text-[10px] hover:bg-white/10"
              aria-label={t('common.increaseTextSize')}
            >
              A+
            </button>
          </div>
        </div>
      </div>

      {/* Header */}
      <header className="border-b border-gray-200 bg-white">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4 sm:px-6">
          <div className="flex items-center gap-3">
            <Wordmark size="lg" />
          </div>
          <nav className="flex items-center gap-2">
            <Button asChild variant="ghost" size="sm">
              <Link to="/login">{t('common.signIn')}</Link>
            </Button>
            <Button asChild size="sm">
              <Link to="/register">{t('common.register')}</Link>
            </Button>
          </nav>
        </div>
      </header>
      {/* A tasteful color nod to the national flag's palette — not a literal flag
          graphic — under the header, in the spirit of GIGW-styled government
          sites. */}
      <div className="h-1 bg-gradient-to-r from-[#FF9933] via-white to-[#138808]" />

      <main id="main">
        {/* Hero */}
        <section className="relative overflow-hidden bg-gradient-to-b from-brand-50 to-white">
          <img
            src="/dashboard-skyline.png"
            alt=""
            className="pointer-events-none absolute inset-y-0 right-0 hidden h-full w-auto max-w-[50%] object-contain object-right opacity-70 lg:block"
          />
          <div className="relative mx-auto max-w-6xl px-4 py-16 sm:px-6 lg:py-24">
            <div className="max-w-xl">
              <h1 className="text-3xl font-bold tracking-tight text-gray-900 sm:text-4xl">
                {t('home.heroTitleLine1')}
                <br />
                {t('home.heroTitleLine2')}
              </h1>
              <p className="mt-4 text-gray-600">{t('home.heroSubtitle')}</p>
              <div className="mt-7 flex flex-wrap gap-3">
                <Button asChild size="lg">
                  <Link to="/register">{t('home.heroCtaRegister')}</Link>
                </Button>
                <Button asChild variant="outline" size="lg">
                  <Link to="/login">{t('common.signIn')}</Link>
                </Button>
              </div>
            </div>
          </div>
        </section>

        {/* Stats strip — only verifiable facts about what's actually built */}
        <section className="border-y border-gray-200 bg-white">
          <div className="mx-auto grid max-w-6xl grid-cols-1 gap-6 px-4 py-8 sm:grid-cols-3 sm:px-6">
            {stats.map((s) => (
              <div key={s.label} className="text-center">
                <p className="text-2xl font-bold text-navy-900">{s.value}</p>
                <p className="mt-1 text-sm text-gray-500">{s.label}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Features */}
        <section className="mx-auto max-w-6xl px-4 py-14 sm:px-6">
          <h2 className="text-center text-2xl font-semibold text-gray-900">{t('home.featuresTitle')}</h2>
          <div className="mt-10 grid grid-cols-1 gap-6 sm:grid-cols-2">
            {features.map((f) => (
              <div key={f.title} className="rounded-lg border border-gray-200 bg-white p-5">
                <div className="flex h-10 w-10 items-center justify-center rounded-md bg-brand-50 text-brand-600">
                  <f.icon className="h-5 w-5" />
                </div>
                <p className="mt-3 text-sm font-semibold text-gray-900">{f.title}</p>
                <p className="mt-1.5 text-sm text-gray-500">{f.description}</p>
              </div>
            ))}
          </div>
        </section>
      </main>

      {/* Footer — GIGW-flavored structure, honestly attributed */}
      <footer id="accessibility" className="border-t border-gray-200 bg-navy-950 text-slate-300">
        <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
          <div className="flex flex-col gap-6 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <Wordmark size="md" dark />
              <p className="mt-2 max-w-sm text-xs text-slate-400">{t('home.footerTagline')}</p>
            </div>
            <div className="flex gap-10 text-xs">
              <div>
                <p className="font-semibold uppercase tracking-wide text-slate-400">{t('home.footerAccessLabel')}</p>
                <div className="mt-2 flex flex-col gap-1.5">
                  <Link to="/login" className="hover:text-white hover:underline">
                    {t('common.signIn')}
                  </Link>
                  <Link to="/register" className="hover:text-white hover:underline">
                    {t('common.register')}
                  </Link>
                </div>
              </div>
              <div>
                <p className="font-semibold uppercase tracking-wide text-slate-400">{t('home.footerAccessibilityLabel')}</p>
                <p className="mt-2 max-w-[16rem] text-slate-400">{t('home.footerAccessibilityDescription')}</p>
              </div>
            </div>
          </div>
          <div className="mt-8 border-t border-white/10 pt-4 text-[11px] text-slate-500">
            {t('home.footerLastUpdated', {
              date: new Date().toLocaleDateString(i18n.language, { year: 'numeric', month: 'long', day: 'numeric' }),
            })}
          </div>
        </div>
      </footer>
    </div>
  )
}
