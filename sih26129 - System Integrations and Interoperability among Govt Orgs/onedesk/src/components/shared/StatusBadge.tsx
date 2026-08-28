import { Badge, type BadgeTone } from '@/components/ui/Badge'

const statusToneMap: Record<string, BadgeTone> = {
  'In Progress': 'warning',
  'Under Review': 'info',
  Approved: 'success',
  Completed: 'success',
  Rejected: 'danger',
  Active: 'success',
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
  return <Badge tone={statusToneMap[status] ?? 'neutral'}>{status}</Badge>
}
