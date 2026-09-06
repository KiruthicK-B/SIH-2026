import { useTranslation } from 'react-i18next'
import { ArchitectureTab } from '@/components/platform/ArchitectureTab'
import { DataMappingTab } from '@/components/platform/DataMappingTab'
import { PageHeader } from '@/components/shared/PageHeader'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/Tabs'

export default function SystemArchitecture() {
  const { t } = useTranslation()
  return (
    <div>
      <PageHeader title={t('systemArchitecture.title')} subtitle={t('systemArchitecture.subtitle')} />

      <Tabs defaultValue="architecture">
        <TabsList>
          <TabsTrigger value="architecture">{t('systemArchitecture.tabArchitecture')}</TabsTrigger>
          <TabsTrigger value="mapping">{t('systemArchitecture.tabMapping')}</TabsTrigger>
        </TabsList>

        <TabsContent value="architecture">
          <ArchitectureTab />
        </TabsContent>
        <TabsContent value="mapping">
          <DataMappingTab />
        </TabsContent>
      </Tabs>
    </div>
  )
}
