import { useTranslation } from 'react-i18next'
import { useRole } from '@/context/RoleContext'

// Role used to be a client-settable dropdown (setRole persisted to localStorage) — that
// was the exact RBAC gap closed in this build: role now comes from the Keycloak-issued
// JWT and can't be changed from the UI. This is now a read-only badge; switching roles
// for a demo means signing in as a different seeded user (see services/keycloak/seed-users.md).
export function RoleSwitcher() {
  const { t } = useTranslation()
  const { role, department } = useRole()

  return (
    <div className="hidden items-center gap-2 md:flex">
      <span className="text-xs font-medium text-gray-400">{t('roleSwitcher.signedInAs')}</span>
      <span className="rounded-full border border-gray-200 bg-gray-50 px-3 py-1 text-xs font-medium text-gray-700">
        {t(`roles.${role}`, { defaultValue: role })}
        {department ? ` · ${department}` : ''}
      </span>
    </div>
  )
}
