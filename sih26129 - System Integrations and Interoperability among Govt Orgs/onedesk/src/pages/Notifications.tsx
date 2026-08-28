import { Bell, CheckCircle2, FileText, ShieldCheck } from 'lucide-react'
import { PageHeader } from '@/components/shared/PageHeader'
import { Button } from '@/components/ui/Button'
import { Card } from '@/components/ui/Card'
import { useNotifications } from '@/context/NotificationsContext'
import { cn, formatDateTime } from '@/lib/utils'

const iconByType = {
  application: FileText,
  consent: ShieldCheck,
  document: CheckCircle2,
  system: Bell,
}

export default function Notifications() {
  const { notifications, markAsRead, markAllAsRead } = useNotifications()

  return (
    <div>
      <PageHeader
        title="Notifications"
        subtitle="Updates on your applications, consent requests, and platform activity."
        action={
          <Button variant="outline" size="sm" onClick={markAllAsRead}>
            Mark all as read
          </Button>
        }
      />

      <Card>
        <div className="divide-y divide-gray-100">
          {notifications.map((n) => {
            const Icon = iconByType[n.type]
            return (
              <button
                key={n.id}
                onClick={() => markAsRead(n.id)}
                className={cn('flex w-full items-start gap-3 px-5 py-4 text-left transition-colors hover:bg-gray-50', !n.read && 'bg-brand-50/40')}
              >
                <div
                  className={cn(
                    'mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-full',
                    n.read ? 'bg-gray-100 text-gray-400' : 'bg-brand-100 text-brand-600',
                  )}
                >
                  <Icon className="h-4 w-4" />
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <p className={cn('text-sm', n.read ? 'font-medium text-gray-700' : 'font-semibold text-gray-900')}>{n.title}</p>
                    {!n.read && <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-brand-600" />}
                  </div>
                  <p className="mt-0.5 text-sm text-gray-500">{n.description}</p>
                  <p className="mt-1 text-xs text-gray-400">{formatDateTime(n.timestamp)}</p>
                </div>
              </button>
            )
          })}
        </div>
      </Card>
    </div>
  )
}
