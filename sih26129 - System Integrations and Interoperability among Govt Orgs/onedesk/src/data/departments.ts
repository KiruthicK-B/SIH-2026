export type SystemTechnology = 'REST API' | 'Legacy SOAP' | 'File/SFTP' | 'Database Connector' | 'OAuth / Federation'

export interface Department {
  id: string
  name: string
  serviceCount: number
  connected: boolean
  description: string
  interfaceType: SystemTechnology
  onboardedOn: string
  lastSyncedAt: string
  modernization: {
    percent: number
    target: string
    status: string
  }
}

export const departments: Department[] = [
  {
    id: 'dept-education',
    name: 'Education Department',
    serviceCount: 12,
    connected: true,
    description: 'Manages scholarships, student certification, and academic verification services statewide.',
    interfaceType: 'REST API',
    onboardedOn: '2025-03-10',
    lastSyncedAt: '2026-08-27T10:41:00',
    modernization: { percent: 100, target: 'Modern REST service', status: 'Fully modernized' },
  },
  {
    id: 'dept-revenue',
    name: 'Revenue Department',
    serviceCount: 9,
    connected: true,
    description: 'Issues income and residence certificates, and manages property tax records.',
    interfaceType: 'REST API',
    onboardedOn: '2025-04-22',
    lastSyncedAt: '2026-08-27T10:39:00',
    modernization: { percent: 85, target: 'Modern REST service', status: 'Migration in progress' },
  },
  {
    id: 'dept-municipal',
    name: 'Municipal Corporation',
    serviceCount: 8,
    connected: true,
    description: 'Handles utility connections, property services, and civil registration records.',
    interfaceType: 'Database Connector',
    onboardedOn: '2025-05-18',
    lastSyncedAt: '2026-08-27T10:22:00',
    modernization: { percent: 60, target: 'Modern REST service', status: 'Migration planned' },
  },
  {
    id: 'dept-health',
    name: 'Health Department',
    serviceCount: 6,
    connected: true,
    description: 'Administers state health benefit schemes and insurance enrollment.',
    interfaceType: 'REST API',
    onboardedOn: '2025-06-30',
    lastSyncedAt: '2026-08-27T10:35:00',
    modernization: { percent: 100, target: 'Modern REST service', status: 'Fully modernized' },
  },
  {
    id: 'dept-food-supplies',
    name: 'Food & Civil Supplies',
    serviceCount: 7,
    connected: true,
    description: 'Manages ration card issuance and public distribution system records.',
    interfaceType: 'File/SFTP',
    onboardedOn: '2025-07-15',
    lastSyncedAt: '2026-08-27T09:58:00',
    modernization: { percent: 35, target: 'Event-driven API adapter', status: 'Integration only' },
  },
  {
    id: 'dept-welfare',
    name: 'Social Welfare Department',
    serviceCount: 6,
    connected: true,
    description: 'Administers pension schemes and welfare benefit disbursement.',
    interfaceType: 'REST API',
    onboardedOn: '2025-08-01',
    lastSyncedAt: '2026-08-27T10:18:00',
    modernization: { percent: 100, target: 'Modern REST service', status: 'Fully modernized' },
  },
  {
    id: 'dept-business-registry',
    name: 'Business Registry',
    serviceCount: 5,
    connected: true,
    description: 'Maintains business entity registration records and micro-enterprise licensing history.',
    interfaceType: 'Legacy SOAP',
    onboardedOn: '2025-09-12',
    lastSyncedAt: '2026-08-27T10:44:00',
    modernization: { percent: 40, target: 'Modern REST service', status: 'Adapter connected · migration planned' },
  },
  {
    id: 'dept-license-authority',
    name: 'License Authority',
    serviceCount: 4,
    connected: true,
    description: 'Issues and renews statutory business and trade licenses across the state.',
    interfaceType: 'REST API',
    onboardedOn: '2025-10-01',
    lastSyncedAt: '2026-08-27T10:46:00',
    modernization: { percent: 100, target: 'Modern REST service', status: 'Fully modernized' },
  },
  {
    id: 'dept-identity',
    name: 'Identity Service',
    serviceCount: 1,
    connected: true,
    description: 'Platform-wide federated identity and single sign-on service used by every connected department.',
    interfaceType: 'OAuth / Federation',
    onboardedOn: '2025-01-15',
    lastSyncedAt: '2026-08-27T10:47:00',
    modernization: { percent: 100, target: 'Federated identity', status: 'Native to platform' },
  },
]

export function getDepartmentById(id: string) {
  return departments.find((d) => d.id === id)
}

/** Departments citizens browse directly. Excludes platform-internal systems like Identity Service. */
export const citizenFacingDepartments = departments.filter((d) => d.interfaceType !== 'OAuth / Federation')
