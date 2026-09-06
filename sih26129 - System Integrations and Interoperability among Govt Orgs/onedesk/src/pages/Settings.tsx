import { CheckCircle2, Lock, User as UserIcon } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { PageHeader } from '@/components/shared/PageHeader'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Input, Label } from '@/components/ui/Input'
import { useToast } from '@/components/ui/Toast'
import { useAuth } from '@/context/AuthContext'
import { useIdentity } from '@/context/IdentityContext'
import { api, ApiError } from '@/lib/api'
import { translateScopeLabel, translateScopeSource } from '@/lib/scopeI18n'
import { useAuthenticatedImage } from '@/lib/useAuthenticatedImage'

interface ScopeGrant {
  key: string
  label: string
  sourceAuthority: string
  isDefault: boolean
  granted: boolean
}

export default function Settings() {
  const { t } = useTranslation()
  const { showToast } = useToast()
  const { name, email } = useAuth()
  const { identity, loading } = useIdentity()
  const [notifyEmail, setNotifyEmail] = useState(true)
  const [notifySms, setNotifySms] = useState(true)
  const photoObjectUrl = useAuthenticatedImage(identity?.photoUrl ?? null)

  const [scopes, setScopes] = useState<ScopeGrant[]>([])
  const [scopesLoading, setScopesLoading] = useState(true)
  const [pendingScopeKey, setPendingScopeKey] = useState<string | null>(null)

  const refreshScopes = () => {
    setScopesLoading(true)
    api
      .get<ScopeGrant[]>('/identity/scopes')
      .then(setScopes)
      .catch(() => setScopes([]))
      .finally(() => setScopesLoading(false))
  }

  useEffect(() => {
    refreshScopes()
  }, [])

  const toggleScope = async (scope: ScopeGrant) => {
    setPendingScopeKey(scope.key)
    const label = translateScopeLabel(t, scope.key, scope.label).toLowerCase()
    try {
      await api.post(`/identity/scopes/${scope.key}/${scope.granted ? 'revoke' : 'grant'}`)
      showToast(
        scope.granted ? t('settings.scopeRevokedTitle') : t('settings.scopeGrantedTitle'),
        scope.granted ? t('settings.scopeRevokedDescription', { label }) : t('settings.scopeGrantedDescription', { label }),
      )
      refreshScopes()
    } catch (err) {
      showToast(t('settings.scopeUpdateFailedTitle'), err instanceof ApiError ? err.message : t('settings.genericError'))
    } finally {
      setPendingScopeKey(null)
    }
  }

  return (
    <div>
      <PageHeader title={t('settings.title')} subtitle={t('settings.subtitle')} />

      <div className="mb-6">
        <Card>
          <CardHeader>
            <CardTitle>{t('settings.identityCardTitle')}</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="mb-4 text-sm text-gray-500">{t('settings.identityIntro')}</p>
            <div className="flex flex-wrap items-center gap-4">
              <div className="rounded-md border border-consent-600/30 bg-consent-50 px-4 py-3">
                <p className="text-xs font-semibold uppercase tracking-wide text-consent-700">{t('settings.oneDeskId')}</p>
                <p className="mt-0.5 font-mono text-lg font-semibold text-consent-700">{identity?.masterId ?? '—'}</p>
              </div>
              <div className="flex flex-1 flex-wrap gap-2">
                {!loading &&
                  identity?.departmentIdentifiers.map((d) => (
                    <span
                      key={d.department}
                      className="flex items-center gap-1.5 rounded-full border border-success-600/20 bg-success-50 px-3 py-1.5 text-xs font-medium text-success-700"
                    >
                      <CheckCircle2 className="h-3.5 w-3.5" /> {d.department} · {d.identifier}
                    </span>
                  ))}
                {!loading && identity?.departmentIdentifiers.length === 0 && (
                  <span className="text-xs text-gray-400">{t('settings.noDepartmentIdentifiers')}</span>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>{t('settings.profileTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-3">
              {photoObjectUrl ? (
                <img src={photoObjectUrl} alt="Profile" className="h-14 w-14 rounded-full object-cover" />
              ) : (
                <div className="flex h-14 w-14 items-center justify-center rounded-full bg-gray-100 text-gray-400">
                  <UserIcon className="h-6 w-6" />
                </div>
              )}
              <p className="text-xs text-gray-400">
                {identity?.photoUrl ? t('settings.photoFromRegistry') : t('settings.noPhotoOnFile')}
              </p>
            </div>
            <div>
              <Label htmlFor="name">{t('settings.fullName')}</Label>
              <Input id="name" defaultValue={name ?? ''} disabled />
            </div>
            <div>
              <Label htmlFor="citizenId">{t('settings.oneDeskId')}</Label>
              <Input id="citizenId" defaultValue={identity?.masterId ?? ''} disabled />
            </div>
            <div>
              <Label htmlFor="email">{t('settings.email')}</Label>
              <Input id="email" type="email" defaultValue={email ?? ''} disabled />
            </div>
            <div>
              <Label htmlFor="mobile">{t('settings.mobileNumber')}</Label>
              <Input id="mobile" defaultValue={identity?.phoneNumber ?? ''} disabled />
            </div>
            <p className="text-xs text-gray-400">{t('settings.federatedNote')}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>{t('settings.notificationPrefsTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <ToggleRow
              label={t('settings.emailNotifications')}
              description={t('settings.emailNotificationsDescription')}
              checked={notifyEmail}
              onChange={setNotifyEmail}
            />
            <ToggleRow
              label={t('settings.smsNotifications')}
              description={t('settings.smsNotificationsDescription')}
              checked={notifySms}
              onChange={setNotifySms}
            />
            <Button onClick={() => showToast(t('settings.preferencesUpdatedTitle'), t('settings.preferencesUpdatedDescription'))}>
              {t('settings.saveChanges')}
            </Button>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>{t('settings.scopesTitle')}</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <p className="mb-2 text-sm text-gray-500">{t('settings.scopesIntro')}</p>
            {!scopesLoading &&
              scopes.map((s) => (
                <div
                  key={s.key}
                  className={`flex items-start justify-between gap-4 rounded-md border px-3 py-2 ${s.isDefault ? 'border-gray-200 bg-gray-50' : 'border-gray-200'}`}
                >
                  <div>
                    <p className="text-sm font-medium text-gray-900">{translateScopeLabel(t, s.key, s.label)}</p>
                    <p className="text-xs text-gray-400">{translateScopeSource(t, s.key, s.sourceAuthority)}</p>
                  </div>
                  {s.isDefault ? (
                    <span className="flex shrink-0 items-center gap-1 rounded-full bg-gray-200 px-2.5 py-1 text-xs font-medium text-gray-600">
                      <Lock className="h-3 w-3" /> {t('settings.alwaysShared')}
                    </span>
                  ) : (
                    <button
                      onClick={() => toggleScope(s)}
                      disabled={pendingScopeKey === s.key}
                      className={`relative h-5 w-9 shrink-0 rounded-full transition-colors disabled:opacity-50 ${s.granted ? 'bg-brand-600' : 'bg-gray-200'}`}
                    >
                      <span
                        className={`absolute top-0.5 h-4 w-4 rounded-full bg-white transition-transform ${s.granted ? 'translate-x-[18px]' : 'translate-x-0.5'}`}
                      />
                    </button>
                  )}
                </div>
              ))}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

function ToggleRow({
  label,
  description,
  checked,
  onChange,
}: {
  label: string
  description: string
  checked: boolean
  onChange: (value: boolean) => void
}) {
  return (
    <div className="flex items-start justify-between gap-4">
      <div>
        <p className="text-sm font-medium text-gray-900">{label}</p>
        <p className="text-xs text-gray-500">{description}</p>
      </div>
      <button
        onClick={() => onChange(!checked)}
        className={`relative h-5 w-9 shrink-0 rounded-full transition-colors ${checked ? 'bg-brand-600' : 'bg-gray-200'}`}
      >
        <span
          className={`absolute top-0.5 h-4 w-4 rounded-full bg-white transition-transform ${checked ? 'translate-x-[18px]' : 'translate-x-0.5'}`}
        />
      </button>
    </div>
  )
}
