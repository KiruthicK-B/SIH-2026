export interface ConnectedSystem {
  name: string
  connected: boolean
}

export const connectedSystems: ConnectedSystem[] = [
  { name: 'Education Department', connected: true },
  { name: 'Revenue Department', connected: true },
  { name: 'Municipal Corporation', connected: true },
  { name: 'Health Department', connected: true },
  { name: 'Social Welfare Department', connected: true },
  { name: 'Food & Civil Supplies', connected: true },
  { name: 'Business Registry', connected: true },
  { name: 'License Authority', connected: true },
  { name: 'Identity Service', connected: true },
]

export const integrationHealth = {
  apiRequests: 284291,
  successful: 281904,
  failed: 2387,
  avgResponseMs: 182,
  availability: 99.9,
  activeWorkflows: 1248,
  slaCompliance: 97.8,
  connectedSystemsCount: connectedSystems.length,
}

export type InterfaceHealth = 'Healthy' | 'Degraded' | 'Down'

export interface ConnectedInterface {
  name: string
  health: InterfaceHealth
}

export const connectedInterfaces: ConnectedInterface[] = [
  { name: 'REST API', health: 'Healthy' },
  { name: 'Legacy SOAP', health: 'Healthy' },
  { name: 'Database Connector', health: 'Healthy' },
  { name: 'File/SFTP Connector', health: 'Healthy' },
  { name: 'OAuth / Federation', health: 'Healthy' },
  { name: 'Event Notifications', health: 'Healthy' },
]

export interface IntegrationEvent {
  id: string
  timestamp: string
  type: string
  actor: string
}

export const recentEvents: IntegrationEvent[] = [
  { id: 'evt-1', timestamp: '10:42:12', type: 'APPLICATION_STATUS_UPDATED', actor: 'Education Department' },
  { id: 'evt-2', timestamp: '10:41:55', type: 'CONSENT_GRANTED', actor: 'Citizen CIT-10282' },
  { id: 'evt-3', timestamp: '10:40:31', type: 'DOCUMENT_VERIFIED', actor: 'Revenue Department' },
  { id: 'evt-4', timestamp: '10:39:12', type: 'APPLICATION_SUBMITTED', actor: 'Municipal Corporation' },
  { id: 'evt-5', timestamp: '10:37:48', type: 'ELIGIBILITY_CHECK_COMPLETED', actor: 'Health Department' },
  { id: 'evt-6', timestamp: '10:35:20', type: 'WORKFLOW_STEP_COMPLETED', actor: 'Welfare Department' },
]
