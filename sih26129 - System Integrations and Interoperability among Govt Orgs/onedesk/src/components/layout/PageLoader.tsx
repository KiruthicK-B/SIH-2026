import { useTranslation } from 'react-i18next'
import { Spinner } from '@/components/ui/Spinner'

export function PageLoader() {
  const { t } = useTranslation()
  return (
    <div className="flex h-full min-h-[60vh] flex-col items-center justify-center gap-3">
      <Spinner size="lg" />
      <p className="text-sm text-gray-400">{t('common.loading')}</p>
    </div>
  )
}
