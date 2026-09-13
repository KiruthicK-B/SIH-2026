import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { Button } from '@/components/ui/Button'
import { useToast } from '@/components/ui/Toast'
import { useDepartments } from '@/context/DepartmentsContext'
import { useRole } from '@/context/RoleContext'
import { api } from '@/lib/api'

interface ConnectorRegistryRow {
  name: string
  protocol: string
  health: string
  killSwitchEnabled: boolean
}

export function ConnectedSystemsTab() {
  const { t } = useTranslation()
  const { departments, loading } = useDepartments()

  return (
    <div className="space-y-6">
      <ConnectorKillSwitchPanel />

      <Card>
        <CardContent className="px-0 pb-0 pt-0">
          <Table>
            <THead>
              <TR>
                <TH>{t('connectedSystemsTab.colSystem')}</TH>
                <TH>{t('connectedSystemsTab.colTechnology')}</TH>
                <TH>{t('connectedSystemsTab.colStatus')}</TH>
                <TH>{t('connectedSystemsTab.colIntegration')}</TH>
              </TR>
            </THead>
            <TBody>
              {departments.map((d) => (
                <TR key={d.id}>
                  <TD className="font-medium text-gray-900">{d.name}</TD>
                  <TD>{d.interfaceType}</TD>
                  <TD>
                    <span
                      className={`flex items-center gap-1.5 text-xs font-medium ${
                        d.killSwitchEnabled ? 'text-danger-600' : d.hasLiveConnector ? 'text-success-600' : 'text-gray-500'
                      }`}
                    >
                      <span
                        className={`h-1.5 w-1.5 rounded-full ${
                          d.killSwitchEnabled ? 'bg-danger-600' : d.hasLiveConnector ? 'bg-success-600' : 'bg-gray-400'
                        }`}
                      />
                      {t(`status.${d.health}`, { defaultValue: d.health })}
                    </span>
                  </TD>
                  <TD className="text-gray-500">
                    {d.hasLiveConnector ? t('connectedSystemsTab.automatedConnector') : t('connectedSystemsTab.manualConnector')}
                  </TD>
                </TR>
              ))}
              {loading && (
                <TR>
                  <TD colSpan={4} className="py-6 text-center text-sm text-gray-400">
                    {t('connectedSystemsTab.loadingRegistry')}
                  </TD>
                </TR>
              )}
            </TBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}

// Backs the Business License flow's live connectors (see WorkflowService / ConnectorsService
// in core-api). This is the graceful-degradation demo control: kill a connector mid-flow
// and watch the affected step block while everything else keeps moving; restore to resume.
function ConnectorKillSwitchPanel() {
  const { t } = useTranslation()
  const { isAdminOnly } = useRole()
  const { showToast } = useToast()
  const [connectors, setConnectors] = useState<ConnectorRegistryRow[]>([])
  const [busy, setBusy] = useState<string | null>(null)

  const isAdmin = isAdminOnly

  const load = () => {
    api.get<ConnectorRegistryRow[]>('/admin/connectors').then(setConnectors)
  }

  useEffect(() => {
    if (isAdmin) load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAdmin])

  if (!isAdmin) return null

  const toggle = async (name: string, kill: boolean) => {
    setBusy(name)
    try {
      const updated = await api.post<ConnectorRegistryRow[]>(`/admin/connectors/${encodeURIComponent(name)}/${kill ? 'kill' : 'restore'}`)
      setConnectors(updated)
      showToast(
        kill ? t('connectedSystemsTab.killedToastTitle', { name }) : t('connectedSystemsTab.restoredToastTitle', { name }),
        kill ? t('connectedSystemsTab.killedToastDescription') : t('connectedSystemsTab.restoredToastDescription'),
      )
    } finally {
      setBusy(null)
    }
  }

  return (
    <Card className="border-teal-600/20 bg-teal-50/30">
      <CardHeader>
        <CardTitle>{t('connectedSystemsTab.killSwitchTitle')}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-2 pt-0">
        <p className="mb-3 text-xs text-gray-500">{t('connectedSystemsTab.killSwitchIntro')}</p>
        {connectors.map((c) => (
          <div key={c.name} className="flex items-center justify-between rounded-md border border-gray-200 bg-white px-4 py-2.5">
            <div>
              <p className="text-sm font-medium text-gray-900">{c.name}</p>
              <p className="text-xs text-gray-400">{c.protocol}</p>
            </div>
            <div className="flex items-center gap-3">
              <span
                className={`flex items-center gap-1.5 text-xs font-medium ${c.killSwitchEnabled ? 'text-danger-600' : 'text-success-600'}`}
              >
                <span className={`h-1.5 w-1.5 rounded-full ${c.killSwitchEnabled ? 'bg-danger-600' : 'bg-success-600'}`} />
                {t(`status.${c.health}`, { defaultValue: c.health })}
              </span>
              {c.killSwitchEnabled ? (
                <Button size="sm" variant="outline" disabled={busy === c.name} onClick={() => toggle(c.name, false)}>
                  {t('connectedSystemsTab.restore')}
                </Button>
              ) : (
                <Button size="sm" variant="outline" disabled={busy === c.name} onClick={() => toggle(c.name, true)}>
                  {t('connectedSystemsTab.kill')}
                </Button>
              )}
            </div>
          </div>
        ))}
        {connectors.length === 0 && <p className="text-sm text-gray-400">{t('connectedSystemsTab.loadingConnectorRegistry')}</p>}
      </CardContent>
    </Card>
  )
}
