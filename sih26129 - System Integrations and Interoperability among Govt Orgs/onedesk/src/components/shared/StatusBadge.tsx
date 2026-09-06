import { useTranslation } from 'react-i18next'
import { Badge, type BadgeTone } from '@/components/ui/Badge'

const statusToneMap: Record<string, BadgeTone> = {
  'In Progress': 'warning',
  'Under Review': 'info',
  Approved: 'success',
  Completed: 'success',
  Rejected: 'danger',
  'Revalidation Required': 'warning',
  Active: 'success',
  ACTIVE: 'success',
  DECEASED: 'danger',
  Revoked: 'danger',
  Expired: 'neutral',
  Open: 'warning',
  Resolved: 'success',
  Success: 'success',
  Failed: 'danger',
  Denied: 'danger',
  Healthy: 'success',
  Degraded: 'warning',
  Down: 'danger',
  Verified: 'success',
  'Pending Verification': 'warning',
}

export function StatusBadge({ status }: { status: string }) {
  const { t } = useTranslation()
  return <Badge tone={statusToneMap[status] ?? 'neutral'}>{t(`status.${status}`, { defaultValue: status })}</Badge>
}
