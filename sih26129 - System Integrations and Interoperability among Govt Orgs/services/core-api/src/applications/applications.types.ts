// Mirrors onedesk/src/data/applications.ts exactly — this is the wire contract.

export type ApplicationStatus = 'In Progress' | 'Under Review' | 'Approved' | 'Completed' | 'Rejected' | 'Revalidation Required';
export type TimelineStepStatus = 'done' | 'active' | 'blocked' | 'pending';
export type BlockedReasonCode = 'connector_killed' | 'consent_revoked' | 'data_quarantined' | 'identity_status_changed' | null;

export interface TimelineStep {
  label: string;
  department: string;
  status: TimelineStepStatus;
  date?: string;
  systemType?: string;
  note?: string;
  blockedReasonCode?: BlockedReasonCode;
}

export interface Application {
  id: string;
  service: string;
  department: string;
  status: ApplicationStatus;
  lastUpdated: string;
  submittedOn: string;
  citizenName: string;
  description: string;
  timeline: TimelineStep[];
  flagship?: boolean;
  citizenMasterId?: string;
}

export interface NewApplicationInput {
  service: string;
  department: string;
  citizenName: string;
  description: string;
  citizenMasterId?: string;
  documentIds?: string[];
}

export interface WorkflowEvent {
  title: string;
  description: string;
  tone: 'success' | 'warning';
}
