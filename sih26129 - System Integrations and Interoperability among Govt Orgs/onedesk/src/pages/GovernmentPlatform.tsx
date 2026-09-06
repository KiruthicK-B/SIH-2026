import { useTranslation } from 'react-i18next'
import { ConnectedSystemsTab } from '@/components/platform/ConnectedSystemsTab'
import { ConsentAccessTab } from '@/components/platform/ConsentAccessTab'
import { DataQualityTab } from '@/components/platform/DataQualityTab'
import { DataStandardsTab } from '@/components/platform/DataStandardsTab'
import { ExceptionsTab } from '@/components/platform/ExceptionsTab'
import { ModernizationTab } from '@/components/platform/ModernizationTab'
import { OverviewTab } from '@/components/platform/OverviewTab'
import { SlaTab } from '@/components/platform/SlaTab'
import { WorkflowsTab } from '@/components/platform/WorkflowsTab'
import { PageHeader } from '@/components/shared/PageHeader'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/Tabs'
import { useRole } from '@/context/RoleContext'

// Ordered to read top-to-bottom as a monitoring layer: the whole system first
// (Overview), then how data actually moves through it (Data Mapping), then
// progressively narrower detail views.
export default function GovernmentPlatform() {
  const { t } = useTranslation()
  const { role } = useRole()
  const roleLabel = t(`roles.${role}`, { defaultValue: role })

  return (
    <>
      <PageHeader title={t('governmentPlatform.title')} subtitle={t('governmentPlatform.subtitle', { role: roleLabel })} />

      <Tabs defaultValue="overview">
        <div className="overflow-x-auto">
          <TabsList>
            <TabsTrigger value="overview">{t('governmentPlatform.tabOverview')}</TabsTrigger>
            <TabsTrigger value="standards">{t('governmentPlatform.tabStandards')}</TabsTrigger>
            <TabsTrigger value="quality">{t('governmentPlatform.tabQuality')}</TabsTrigger>
            <TabsTrigger value="systems">{t('governmentPlatform.tabSystems')}</TabsTrigger>
            <TabsTrigger value="workflows">{t('governmentPlatform.tabWorkflows')}</TabsTrigger>
            <TabsTrigger value="consent">{t('governmentPlatform.tabConsent')}</TabsTrigger>
            <TabsTrigger value="exceptions">{t('governmentPlatform.tabExceptions')}</TabsTrigger>
            <TabsTrigger value="sla">{t('governmentPlatform.tabSla')}</TabsTrigger>
            <TabsTrigger value="modernization">{t('governmentPlatform.tabModernization')}</TabsTrigger>
          </TabsList>
        </div>

        <TabsContent value="overview">
          <OverviewTab />
        </TabsContent>
        <TabsContent value="standards">
          <DataStandardsTab />
        </TabsContent>
        <TabsContent value="quality">
          <DataQualityTab />
        </TabsContent>
        <TabsContent value="systems">
          <ConnectedSystemsTab />
        </TabsContent>
        <TabsContent value="workflows">
          <WorkflowsTab />
        </TabsContent>
        <TabsContent value="consent">
          <ConsentAccessTab />
        </TabsContent>
        <TabsContent value="exceptions">
          <ExceptionsTab />
        </TabsContent>
        <TabsContent value="sla">
          <SlaTab />
        </TabsContent>
        <TabsContent value="modernization">
          <ModernizationTab />
        </TabsContent>
      </Tabs>
    </>
  )
}
