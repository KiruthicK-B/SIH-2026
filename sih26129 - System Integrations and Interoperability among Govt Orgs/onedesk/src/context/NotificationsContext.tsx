import { createContext, type ReactNode, useContext, useEffect, useState } from 'react'
import { useAuth } from '@/context/AuthContext'
import type { AppNotification } from '@/data/notifications'
import { api } from '@/lib/api'

interface NotificationsContextValue {
  notifications: AppNotification[]
  unreadCount: number
  loading: boolean
  markAsRead: (id: string) => void
  markAllAsRead: () => void
  refresh: () => Promise<void>
}

const NotificationsContext = createContext<NotificationsContextValue | null>(null)

export function NotificationsProvider({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth()
  const [notifications, setNotifications] = useState<AppNotification[]>([])
  const [loading, setLoading] = useState(true)

  const refresh = async () => {
    const data = await api.get<AppNotification[]>('/notifications')
    setNotifications(data)
  }

  useEffect(() => {
    if (!isAuthenticated) return
    setLoading(true)
    refresh().finally(() => setLoading(false))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated])

  const markAsRead = (id: string) => {
    setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, read: true } : n)))
    void api.post(`/notifications/${id}/read`)
  }

  const markAllAsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })))
    void api.post('/notifications/read-all')
  }

  const unreadCount = notifications.filter((n) => !n.read).length

  return (
    <NotificationsContext.Provider value={{ notifications, unreadCount, loading, markAsRead, markAllAsRead, refresh }}>
      {children}
    </NotificationsContext.Provider>
  )
}

export function useNotifications() {
  const ctx = useContext(NotificationsContext)
  if (!ctx) throw new Error('useNotifications must be used within NotificationsProvider')
  return ctx
}
