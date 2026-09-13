// Runtime application data now lives in core-api/Postgres (see ApplicationsContext.tsx,
// which fetches from GET /applications). This file keeps only the shared type contract —
// the wire format core-api's ApplicationsController serializes to.

export type ApplicationStatus = 'In Progress' | 'Under Review' | 'Approved' | 'Completed' | 'Rejected' | 'Revalidation Required'

export type TimelineStepStatus = 'done' | 'active' | 'blocked' | 'pending' | 'awaiting_department' | 'rejected'

export interface TimelineStep {
  label: string
  department: string
  status: TimelineStepStatus
  date?: string
  systemType?: string
  note?: string
  blockedReasonCode?: string
}

export interface Application {
  id: string
  service: string
  department: string
  status: ApplicationStatus
  lastUpdated: string
  submittedOn: string
  citizenName: string
  description: string
  timeline: TimelineStep[]
  flagship?: boolean
  citizenMasterId?: string
}
