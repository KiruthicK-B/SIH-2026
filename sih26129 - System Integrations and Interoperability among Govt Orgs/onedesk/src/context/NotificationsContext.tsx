import { createContext, type ReactNode, useContext, useState } from 'react'
import { type AppNotification, type NotificationType, initialNotifications } from '@/data/notifications'

interface NotificationsContextValue {
  notifications: AppNotification[]
  unreadCount: number
  markAsRead: (id: string) => void
  markAllAsRead: () => void
  addNotification: (input: { type: NotificationType; title: string; description: string }) => void
}

const NotificationsContext = createContext<NotificationsContextValue | null>(null)

export function NotificationsProvider({ children }: { children: ReactNode }) {
  const [notifications, setNotifications] = useState<AppNotification[]>(initialNotifications)

  const markAsRead = (id: string) => {
    setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, read: true } : n)))
  }

  const markAllAsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })))
  }

  const addNotification: NotificationsContextValue['addNotification'] = ({ type, title, description }) => {
    setNotifications((prev) => [
      { id: `ntf-${Date.now()}`, type, title, description, timestamp: new Date().toISOString(), read: false },
      ...prev,
    ])
  }

  const unreadCount = notifications.filter((n) => !n.read).length

  return (
    <NotificationsContext.Provider value={{ notifications, unreadCount, markAsRead, markAllAsRead, addNotification }}>
      {children}
    </NotificationsContext.Provider>
  )
}

export function useNotifications() {
  const ctx = useContext(NotificationsContext)
  if (!ctx) throw new Error('useNotifications must be used within NotificationsProvider')
  return ctx
}
