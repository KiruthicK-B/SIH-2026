export type NotificationType = 'application' | 'consent' | 'document' | 'system'

export interface AppNotification {
  id: string
  type: NotificationType
  title: string
  description: string
  timestamp: string
  read: boolean
}

export const initialNotifications: AppNotification[] = [
  {
    id: 'ntf-1',
    type: 'application',
    title: 'Application APP-2026-1001',
    description: 'Eligibility verification is in progress with the Revenue Department.',
    timestamp: '2026-08-26T11:20:00',
    read: false,
  },
  {
    id: 'ntf-2',
    type: 'document',
    title: 'Application APP-2026-1002',
    description: 'Income certificate document has been verified.',
    timestamp: '2026-08-25T09:45:00',
    read: false,
  },
  {
    id: 'ntf-3',
    type: 'consent',
    title: 'Consent request',
    description: 'Education Department requested access to academic details.',
    timestamp: '2026-08-27T08:15:00',
    read: false,
  },
  {
    id: 'ntf-4',
    type: 'application',
    title: 'Application APP-2026-1003',
    description: 'Business registration has been approved by the Business Registry.',
    timestamp: '2026-08-24T16:30:00',
    read: true,
  },
  {
    id: 'ntf-5',
    type: 'system',
    title: 'Scheduled maintenance',
    description: 'Municipal Corporation connector will be briefly unavailable on 30 Aug, 11 PM–1 AM.',
    timestamp: '2026-08-23T10:00:00',
    read: true,
  },
  {
    id: 'ntf-6',
    type: 'application',
    title: 'Application APP-2026-1005',
    description: 'Ration card application has been completed.',
    timestamp: '2026-08-05T14:10:00',
    read: true,
  },
]
