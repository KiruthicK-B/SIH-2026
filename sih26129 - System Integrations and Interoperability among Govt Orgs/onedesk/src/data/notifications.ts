export type NotificationType = 'application' | 'consent' | 'document' | 'system'

export interface AppNotification {
  id: string
  type: NotificationType
  title: string
  description: string
  timestamp: string
  read: boolean
}
