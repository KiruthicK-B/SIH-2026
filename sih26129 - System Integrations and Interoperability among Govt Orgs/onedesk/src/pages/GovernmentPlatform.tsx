import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { ArchitectureTab } from '@/components/platform/ArchitectureTab'
import { ConnectedSystemsTab } from '@/components/platform/ConnectedSystemsTab'
import { ConsentAccessTab } from '@/components/platform/ConsentAccessTab'
import { DataMappingTab } from '@/components/platform/DataMappingTab'
import { DataQualityTab } from '@/components/platform/DataQualityTab'
import { DataStandardsTab } from '@/components/platform/DataStandardsTab'
import { ExceptionsTab } from '@/components/platform/ExceptionsTab'
import { GovtRegistryTab } from '@/components/platform/GovtRegistryTab'
import { OverviewTab } from '@/components/platform/OverviewTab'
import { SlaTab } from '@/components/platform/SlaTab'
import { WorkflowsTab } from '@/components/platform/WorkflowsTab'
import { PageHeader } from '@/components/shared/PageHeader'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/Tabs'
import { useRole } from '@/context/RoleContext'

// Second-tier nav for a section that groups more than one previously-standalone
// tab — visually distinct (pill, no boxed background) from the top-level TabsList
// so the two levels read as a hierarchy, not two identical bars stacked on top of
// each other.
const subTabsListClass = 'inline-flex items-center gap-1.5 rounded-none bg-transparent p-0'
const subTabTriggerClass =
  'rounded-full border border-gray-200 bg-white px-3 py-1 text-xs font-medium text-gray-500 shadow-none ' +
  'data-[state=active]:border-brand-500 data-[state=active]:bg-brand-50 data-[state=active]:text-brand-700 data-[state=active]:shadow-none'

// One page, one shell — Architecture and Govt Registry used to be separate routes
// with their own PageHeader/Tabs; they're sections of the same admin console, so
// they're tabs here instead. Ordered to read top-to-bottom as a monitoring layer:
// the whole system first (Overview), then how departments actually connect
// (Interoperability, admin-only), then data/consent, then day-to-day operations,
// then the admin-only citizen registry.
export default function GovernmentPlatform() {
  const { t } = useTranslation()
  const { role, isAdminOnly } = useRole()
  const roleLabel = t(`roles.${role}`, { defaultValue: role })
  const [activeTab, setActiveTab] = useState('overview')

  return (
    <>
      <PageHeader title={t('governmentPlatform.title')} subtitle={t('governmentPlatform.subtitle', { role: roleLabel })} />

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <div className="overflow-x-auto">
          <TabsList>
            <TabsTrigger value="overview">{t('governmentPlatform.tabOverview')}</TabsTrigger>
            {isAdminOnly && <TabsTrigger value="interoperability">{t('governmentPlatform.tabInteroperability')}</TabsTrigger>}
            <TabsTrigger value="dataConsent">{t('governmentPlatform.tabDataConsent')}</TabsTrigger>
            <TabsTrigger value="operations">{t('governmentPlatform.tabOperations')}</TabsTrigger>
            {isAdminOnly && <TabsTrigger value="registry">{t('governmentPlatform.tabRegistry')}</TabsTrigger>}
          </TabsList>
        </div>

        <TabsContent value="overview">
          <OverviewTab onNavigate={setActiveTab} isAdminOnly={isAdminOnly} />
        </TabsContent>

        {isAdminOnly && (
          <TabsContent value="interoperability">
            <Tabs defaultValue="topology">
              <TabsList className={subTabsListClass}>
                <TabsTrigger value="topology" className={subTabTriggerClass}>
                  {t('governmentPlatform.subTopology')}
                </TabsTrigger>
                <TabsTrigger value="mapping" className={subTabTriggerClass}>
                  {t('governmentPlatform.subDataMapping')}
                </TabsTrigger>
                <TabsTrigger value="connectors" className={subTabTriggerClass}>
                  {t('governmentPlatform.subConnectorRegistry')}
                </TabsTrigger>
              </TabsList>
              <TabsContent value="topology">
                <ArchitectureTab />
              </TabsContent>
              <TabsContent value="mapping">
                <DataMappingTab />
              </TabsContent>
              <TabsContent value="connectors">
                <ConnectedSystemsTab />
              </TabsContent>
            </Tabs>
          </TabsContent>
        )}

        <TabsContent value="dataConsent">
          <Tabs defaultValue="standards">
            <TabsList className={subTabsListClass}>
              <TabsTrigger value="standards" className={subTabTriggerClass}>
                {t('governmentPlatform.subStandardsQuality')}
              </TabsTrigger>
              <TabsTrigger value="consentLedger" className={subTabTriggerClass}>
                {t('governmentPlatform.subConsentLedger')}
              </TabsTrigger>
            </TabsList>
            <TabsContent value="standards">
              <div className="space-y-6">
                <DataStandardsTab />
                <DataQualityTab />
              </div>
            </TabsContent>
            <TabsContent value="consentLedger">
              <ConsentAccessTab />
            </TabsContent>
          </Tabs>
        </TabsContent>

        <TabsContent value="operations">
          <Tabs defaultValue="workflows">
            <TabsList className={subTabsListClass}>
              <TabsTrigger value="workflows" className={subTabTriggerClass}>
                {t('governmentPlatform.tabWorkflows')}
              </TabsTrigger>
              <TabsTrigger value="exceptions" className={subTabTriggerClass}>
                {t('governmentPlatform.tabExceptions')}
              </TabsTrigger>
              <TabsTrigger value="sla" className={subTabTriggerClass}>
                {t('governmentPlatform.tabSla')}
              </TabsTrigger>
            </TabsList>
            <TabsContent value="workflows">
              <WorkflowsTab />
            </TabsContent>
            <TabsContent value="exceptions">
              <ExceptionsTab />
            </TabsContent>
            <TabsContent value="sla">
              <SlaTab />
            </TabsContent>
          </Tabs>
        </TabsContent>

        {isAdminOnly && (
          <TabsContent value="registry">
            <GovtRegistryTab />
          </TabsContent>
        )}
      </Tabs>
    </>
  )
}
