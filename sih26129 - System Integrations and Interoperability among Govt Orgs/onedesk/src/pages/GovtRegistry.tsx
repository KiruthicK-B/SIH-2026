import { useTranslation } from 'react-i18next'
import { GovtRegistryTab } from '@/components/platform/GovtRegistryTab'
import { PageHeader } from '@/components/shared/PageHeader'

export default function GovtRegistry() {
  const { t } = useTranslation()
  return (
    <div>
      <PageHeader title={t('nav.govtIdentityRegistry')} />
      <GovtRegistryTab />
    </div>
  )
}
