// Runtime department data now lives in core-api/Postgres (see DepartmentsContext.tsx,
// which fetches from GET /departments). This file keeps only the shared type contract.

export type SystemTechnology = 'REST API' | 'Legacy SOAP' | 'File/SFTP' | 'Database Connector' | 'OAuth / Federation'
export type ConnectorHealth = 'Healthy' | 'Degraded' | 'Down' | 'Manual Processing'

export interface Department {
  id: string
  name: string
  description: string
  serviceCount: number
  interfaceType: SystemTechnology
  onboardedOn: string
  modernization: {
    percent: number
    target: string
    status: string
  }
  hasLiveConnector: boolean
  health: ConnectorHealth
  killSwitchEnabled: boolean
}
