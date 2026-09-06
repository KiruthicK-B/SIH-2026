import { ShieldAlert } from 'lucide-react'
import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/Button'
import { useRole } from '@/context/RoleContext'

export function RequirePlatformAccess({ children }: { children: ReactNode }) {
  const { t } = useTranslation()
  const { isPlatformRole } = useRole()
  const navigate = useNavigate()

  if (isPlatformRole) {
    return <>{children}</>
  }

  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center text-center">
      <div className="flex h-14 w-14 items-center justify-center rounded-full bg-gray-100 text-gray-400">
        <ShieldAlert className="h-6 w-6" />
      </div>
      <h1 className="mt-4 text-base font-semibold text-gray-900">{t('requirePlatformAccess.title')}</h1>
      <p className="mt-1.5 max-w-sm text-sm text-gray-500">{t('requirePlatformAccess.description')}</p>
      <Button variant="outline" className="mt-5" onClick={() => navigate('/dashboard')}>
        {t('requirePlatformAccess.backButton')}
      </Button>
    </div>
  )
}
