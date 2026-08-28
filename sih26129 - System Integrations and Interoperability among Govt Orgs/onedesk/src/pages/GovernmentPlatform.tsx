import { RequirePlatformAccess } from '@/components/layout/RequirePlatformAccess'
import { ConnectedSystemsTab } from '@/components/platform/ConnectedSystemsTab'
import { DataStandardsTab } from '@/components/platform/DataStandardsTab'
import { ExceptionsTab } from '@/components/platform/ExceptionsTab'
import { ModernizationTab } from '@/components/platform/ModernizationTab'
import { OverviewTab } from '@/components/platform/OverviewTab'
import { SlaTab } from '@/components/platform/SlaTab'
import { PageHeader } from '@/components/shared/PageHeader'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/Tabs'
import { useRole } from '@/context/RoleContext'

export default function GovernmentPlatform() {
  const { role } = useRole()

  return (
    <RequirePlatformAccess>
      <PageHeader
        title="Government Platform"
        subtitle={`Signed in as ${role} — one connected view of the otherwise fragmented department ecosystem.`}
      />

      <Tabs defaultValue="overview">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="systems">Connected Systems</TabsTrigger>
          <TabsTrigger value="standards">Data Standards</TabsTrigger>
          <TabsTrigger value="exceptions">Exceptions</TabsTrigger>
          <TabsTrigger value="sla">SLA</TabsTrigger>
          <TabsTrigger value="modernization">Modernization</TabsTrigger>
        </TabsList>

        <TabsContent value="overview">
          <OverviewTab />
        </TabsContent>
        <TabsContent value="systems">
          <ConnectedSystemsTab />
        </TabsContent>
        <TabsContent value="standards">
          <DataStandardsTab />
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
    </RequirePlatformAccess>
  )
}
