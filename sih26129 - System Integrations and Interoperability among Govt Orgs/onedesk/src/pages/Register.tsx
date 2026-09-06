import { Lock } from 'lucide-react'
import { motion } from 'motion/react'
import { type FormEvent, useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, Navigate } from 'react-router-dom'
import { BrandBanner } from '@/components/branding/BrandBanner'
import { LanguageSwitcher } from '@/components/shared/LanguageSwitcher'
import { Button } from '@/components/ui/Button'
import { Input, Label } from '@/components/ui/Input'
import { Spinner } from '@/components/ui/Spinner'
import { useAuth } from '@/context/AuthContext'
import { api, ApiError } from '@/lib/api'
import { DirectGrantError, directGrantLogin } from '@/lib/directGrantAuth'
import { persistDirectGrantTokens } from '@/lib/keycloak'
import { translateScopeLabel, translateScopeSource } from '@/lib/scopeI18n'

type LookupMedium = 'aadhaar' | 'pan' | 'phone'

interface GovtRecord {
  aadhaarNumber: string
  name: string
  dateOfBirth: string
  gender: string
  address: string
  panNumber: string | null
  phoneNumber: string | null
  employmentStatus: string | null
  employerName: string | null
  designation: string | null
  highestQualification: string | null
  institutionName: string | null
  fatherName: string | null
  motherName: string | null
  parentPhoneNumber: string | null
  siblings: string | null
  occupation: string | null
  hasPhoto: boolean
}

interface ScopeDefinition {
  key: string
  label: string
  sourceAuthority: string
  isDefault: boolean
}

function validateMediumValue(medium: LookupMedium, raw: string): string | null {
  if (medium === 'aadhaar') {
    const digits = raw.replace(/\D/g, '')
    return digits.length === 12 ? digits : null
  }
  if (medium === 'pan') {
    const upper = raw.trim().toUpperCase()
    return /^[A-Z]{5}\d{4}[A-Z]$/.test(upper) ? upper : null
  }
  const digits = raw.replace(/\D/g, '')
  return digits.length === 10 ? digits : null
}

const stepVariants = {
  initial: { opacity: 0, x: 16 },
  animate: { opacity: 1, x: 0 },
}

export default function Register() {
  const { t } = useTranslation()
  const { isAuthenticated } = useAuth()
  const [step, setStep] = useState<1 | 2 | 3 | 4>(1)
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  const MEDIA: { value: LookupMedium; label: string; placeholder: string }[] = [
    { value: 'aadhaar', label: t('register.mediumAadhaar'), placeholder: t('register.mediumAadhaarPlaceholder') },
    { value: 'pan', label: t('register.mediumPan'), placeholder: t('register.mediumPanPlaceholder') },
    { value: 'phone', label: t('register.mediumPhone'), placeholder: t('register.mediumPhonePlaceholder') },
  ]

  const [medium, setMedium] = useState<LookupMedium>('aadhaar')
  const [lookupInput, setLookupInput] = useState('')
  const [loginPhone, setLoginPhone] = useState('')
  const [record, setRecord] = useState<GovtRecord | null>(null)
  const [resolvedValue, setResolvedValue] = useState('')

  const [scopeCatalog, setScopeCatalog] = useState<ScopeDefinition[]>([])
  const [grantedScopes, setGrantedScopes] = useState<Set<string>>(new Set())

  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [consentGiven, setConsentGiven] = useState(false)

  useEffect(() => {
    api.get<ScopeDefinition[]>('/auth/register/scopes').then(setScopeCatalog).catch(() => {})
  }, [])

  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />
  }

  // Whichever identifier the citizen used to look themselves up is already known to
  // OneDesk by construction — the lookup call itself disclosed it. Letting that
  // scope be toggled off would show a consent screen that lies about what's already
  // been shared, so it's forced always-on here, not just isDefault from the catalog.
  const isMediumLockedScope = (key: string) =>
    (key === 'identity.aadhaar_number' && medium === 'aadhaar') || (key === 'identity.pan' && medium === 'pan')
  const isLockedScope = (s: ScopeDefinition) => s.isDefault || isMediumLockedScope(s.key)

  const optionalScopes = scopeCatalog.filter((s) => !isLockedScope(s))
  const defaultScopes = scopeCatalog.filter((s) => s.isDefault)
  const mediumLockedScopes = scopeCatalog.filter((s) => !s.isDefault && isMediumLockedScope(s.key))
  const activeMedium = MEDIA.find((m) => m.value === medium)!

  const toggleScope = (key: string) => {
    setGrantedScopes((prev) => {
      const next = new Set(prev)
      if (next.has(key)) next.delete(key)
      else next.add(key)
      return next
    })
  }

  const handleLookup = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    const cleaned = validateMediumValue(medium, lookupInput)
    if (!cleaned) {
      setError(t('register.invalidMediumError', { medium: activeMedium.label.toLowerCase() }))
      return
    }
    setSubmitting(true)
    try {
      const result = await api.post<GovtRecord>('/auth/register/lookup', { medium, value: cleaned })
      setRecord(result)
      setResolvedValue(cleaned)
      setStep(2)
    } catch (err) {
      setError(err instanceof ApiError ? err.message : t('register.lookupGenericError'))
    } finally {
      setSubmitting(false)
    }
  }

  const handleComplete = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    if (password.length < 6) {
      setError(t('register.passwordTooShortError'))
      return
    }
    if (password !== confirmPassword) {
      setError(t('register.passwordMismatchError'))
      return
    }
    if (!consentGiven) {
      setError(t('register.consentRequiredError'))
      return
    }
    if (!record) return

    // If phone itself was the lookup medium, that number doubles as the login
    // contact — no need to ask for it twice.
    const phoneNumber = medium === 'phone' ? resolvedValue : loginPhone.trim() || undefined

    setSubmitting(true)
    try {
      // Medium-locked scopes (e.g. Aadhaar number when Aadhaar was the lookup
      // medium) are never rendered as togglable, so they can't already be in
      // grantedScopes from a checkbox click — added here to actually be granted.
      const finalGrantedScopes = new Set(grantedScopes)
      for (const s of mediumLockedScopes) finalGrantedScopes.add(s.key)

      const { username } = await api.post<{ masterId: string; username: string }>('/auth/register/complete', {
        medium,
        value: resolvedValue,
        phoneNumber,
        password,
        consentGiven,
        grantedScopes: Array.from(finalGrantedScopes),
      })

      const tokens = await directGrantLogin(username, password)
      persistDirectGrantTokens(tokens)
      window.location.assign('/dashboard')
    } catch (err) {
      setError(
        err instanceof ApiError
          ? err.message
          : err instanceof DirectGrantError
            ? err.message
            : t('register.completeGenericError'),
      )
      setSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-8">
      <div className="fixed inset-x-0 top-0 h-1 bg-gradient-to-r from-[#FF9933] via-white to-[#138808]" />
      <div className="fixed right-4 top-4">
        <LanguageSwitcher />
      </div>
      <div className="w-full max-w-md">
        <div className="mb-6">
          <BrandBanner />
        </div>

        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-xs">
          <div className="mb-5 flex items-center gap-2">
            {[1, 2, 3, 4].map((n) => (
              <div
                key={n}
                className={`h-1.5 flex-1 rounded-full ${n <= step ? 'bg-brand-600' : 'bg-gray-200'}`}
              />
            ))}
          </div>

          {step === 1 && (
            <motion.div key="step1" initial="initial" animate="animate" variants={stepVariants}>
              <h1 className="text-base font-semibold text-gray-900">{t('register.step1Title')}</h1>

              <form onSubmit={handleLookup} className="mt-5 space-y-4">
                <div>
                  <Label>{t('register.mediumQuestion')}</Label>
                  <div className="mt-1.5 grid grid-cols-3 gap-2">
                    {MEDIA.map((m) => (
                      <button
                        key={m.value}
                        type="button"
                        onClick={() => {
                          setMedium(m.value)
                          setLookupInput('')
                        }}
                        disabled={submitting}
                        className={`rounded-md border px-3 py-2 text-sm font-medium transition-colors ${
                          medium === m.value
                            ? 'border-brand-500 bg-brand-50 text-brand-700 ring-1 ring-brand-500'
                            : 'border-gray-200 text-gray-600 hover:border-gray-300'
                        }`}
                      >
                        {m.label}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <Label htmlFor="lookupValue">{t('register.lookupValueLabel', { medium: activeMedium.label })}</Label>
                  <Input
                    id="lookupValue"
                    autoFocus
                    value={lookupInput}
                    onChange={(e) => setLookupInput(medium === 'pan' ? e.target.value.toUpperCase() : e.target.value)}
                    placeholder={activeMedium.placeholder}
                    maxLength={medium === 'aadhaar' ? 14 : 10}
                    disabled={submitting}
                  />
                </div>

                {medium !== 'phone' && (
                  <div>
                    <Label htmlFor="loginPhone">{t('register.loginPhoneLabel')}</Label>
                    <Input
                      id="loginPhone"
                      value={loginPhone}
                      onChange={(e) => setLoginPhone(e.target.value.replace(/\D/g, ''))}
                      placeholder={t('register.loginPhonePlaceholder')}
                      maxLength={10}
                      disabled={submitting}
                    />
                  </div>
                )}

                {error && (
                  <p className="rounded-md bg-danger-50 px-3 py-2 text-xs font-medium text-danger-700">{error}</p>
                )}

                <Button type="submit" className="w-full" size="lg" disabled={submitting}>
                  {submitting ? (
                    <>
                      <Spinner size="sm" className="border-white/30 border-t-white" /> {t('register.verifying')}
                    </>
                  ) : (
                    t('register.verifyMedium', { medium: activeMedium.label })
                  )}
                </Button>
              </form>
            </motion.div>
          )}

          {step === 2 && record && (
            <motion.div key="step2" initial="initial" animate="animate" variants={stepVariants}>
              <h1 className="text-base font-semibold text-gray-900">{t('register.step2Title')}</h1>
              <p className="mt-1 text-sm text-gray-500">
                {t('register.step2Subtitle', { medium: activeMedium.label.toLowerCase() })}
              </p>

              <div className="mt-4 space-y-1.5 rounded-md border border-gray-200 bg-gray-50 p-3 text-sm">
                <Field label={t('register.fieldName')} value={record.name} />
                <Field label={t('register.fieldDob')} value={record.dateOfBirth} />
                <Field label={t('register.fieldGender')} value={record.gender} />
                <Field label={t('register.fieldAddress')} value={record.address} />
                {record.panNumber && <Field label={t('register.fieldPan')} value={record.panNumber} />}
                {record.employmentStatus && <Field label={t('register.fieldEmployment')} value={record.employmentStatus} />}
                {record.occupation && <Field label={t('register.fieldOccupation')} value={record.occupation} />}
                {record.highestQualification && <Field label={t('register.fieldQualification')} value={record.highestQualification} />}
                {record.institutionName && <Field label={t('register.fieldInstitution')} value={record.institutionName} />}
                {record.fatherName && <Field label={t('register.fieldFatherName')} value={record.fatherName} />}
                {record.motherName && <Field label={t('register.fieldMotherName')} value={record.motherName} />}
                {record.siblings && <Field label={t('register.fieldSiblings')} value={record.siblings} />}
              </div>

              <div className="mt-4 flex gap-2">
                <Button type="button" variant="outline" onClick={() => setStep(1)} className="flex-1">
                  {t('common.back')}
                </Button>
                <Button type="button" onClick={() => setStep(3)} className="flex-1">
                  {t('common.continue')}
                </Button>
              </div>
            </motion.div>
          )}

          {step === 3 && (
            <motion.div key="step3" initial="initial" animate="animate" variants={stepVariants}>
              <h1 className="text-base font-semibold text-gray-900">{t('register.step3Title')}</h1>
              <p className="mt-1 text-sm text-gray-500">{t('register.step3Subtitle')}</p>

              <div className="mt-4 space-y-2">
                {defaultScopes.map((s) => (
                  <div key={s.key} className="flex items-start gap-2 rounded-md border border-gray-200 bg-gray-50 px-3 py-2">
                    <Lock className="mt-0.5 h-3.5 w-3.5 shrink-0 text-gray-400" />
                    <div>
                      <p className="text-sm font-medium text-gray-700">{translateScopeLabel(t, s.key, s.label)}</p>
                      <p className="text-xs text-gray-400">
                        {t('register.alwaysShared')} · {translateScopeSource(t, s.key, s.sourceAuthority)}
                      </p>
                    </div>
                  </div>
                ))}
                {mediumLockedScopes.map((s) => (
                  <div key={s.key} className="flex items-start gap-2 rounded-md border border-gray-200 bg-gray-50 px-3 py-2">
                    <Lock className="mt-0.5 h-3.5 w-3.5 shrink-0 text-gray-400" />
                    <div>
                      <p className="text-sm font-medium text-gray-700">{translateScopeLabel(t, s.key, s.label)}</p>
                      <p className="text-xs text-gray-400">
                        {t('register.alreadySharedMedium')} · {translateScopeSource(t, s.key, s.sourceAuthority)}
                      </p>
                    </div>
                  </div>
                ))}
                {optionalScopes.map((s) => (
                  <label
                    key={s.key}
                    className="flex cursor-pointer items-start gap-2 rounded-md border border-gray-200 px-3 py-2 hover:border-brand-300"
                  >
                    <input
                      type="checkbox"
                      checked={grantedScopes.has(s.key)}
                      onChange={() => toggleScope(s.key)}
                      className="mt-0.5 h-3.5 w-3.5 rounded border-gray-300 text-brand-600 focus:ring-brand-500"
                    />
                    <div>
                      <p className="text-sm font-medium text-gray-900">{translateScopeLabel(t, s.key, s.label)}</p>
                      <p className="text-xs text-gray-400">{translateScopeSource(t, s.key, s.sourceAuthority)}</p>
                    </div>
                  </label>
                ))}
              </div>

              <div className="mt-4 flex gap-2">
                <Button type="button" variant="outline" onClick={() => setStep(2)} className="flex-1">
                  {t('common.back')}
                </Button>
                <Button type="button" onClick={() => setStep(4)} className="flex-1">
                  {t('common.continue')}
                </Button>
              </div>
            </motion.div>
          )}

          {step === 4 && (
            <motion.div key="step4" initial="initial" animate="animate" variants={stepVariants}>
              <h1 className="text-base font-semibold text-gray-900">{t('register.step4Title')}</h1>

              <form onSubmit={handleComplete} className="mt-4 space-y-4">
                <div>
                  <Label htmlFor="password">{t('register.passwordLabel')}</Label>
                  <Input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder={t('register.passwordPlaceholder')}
                    disabled={submitting}
                  />
                </div>
                <div>
                  <Label htmlFor="confirmPassword">{t('register.confirmPasswordLabel')}</Label>
                  <Input
                    id="confirmPassword"
                    type="password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    placeholder={t('register.confirmPasswordPlaceholder')}
                    disabled={submitting}
                  />
                </div>

                <label className="flex items-start gap-2 text-xs text-gray-600">
                  <input
                    type="checkbox"
                    checked={consentGiven}
                    onChange={(e) => setConsentGiven(e.target.checked)}
                    className="mt-0.5 h-3.5 w-3.5 rounded border-gray-300 text-brand-600 focus:ring-brand-500"
                    disabled={submitting}
                  />
                  <span>{t('register.consentLabel', { medium: activeMedium.label })}</span>
                </label>

                {error && (
                  <p className="rounded-md bg-danger-50 px-3 py-2 text-xs font-medium text-danger-700">{error}</p>
                )}

                <div className="flex gap-2">
                  <Button type="button" variant="outline" onClick={() => setStep(3)} className="flex-1" disabled={submitting}>
                    {t('common.back')}
                  </Button>
                  <Button type="submit" className="flex-1" disabled={submitting}>
                    {submitting ? (
                      <>
                        <Spinner size="sm" className="border-white/30 border-t-white" /> {t('register.creating')}
                      </>
                    ) : (
                      t('register.createButton')
                    )}
                  </Button>
                </div>
              </form>
            </motion.div>
          )}

          <p className="mt-4 text-center text-xs text-gray-400">
            {t('register.alreadyHaveId')}{' '}
            <Link to="/login" className="font-medium text-brand-600 hover:text-brand-700">
              {t('register.signInLink')}
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-4">
      <span className="shrink-0 text-gray-500">{label}</span>
      <span className="text-right font-medium text-gray-900">{value}</span>
    </div>
  )
}
