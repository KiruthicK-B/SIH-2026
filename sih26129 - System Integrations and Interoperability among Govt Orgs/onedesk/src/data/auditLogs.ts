export type AuditResult = 'Success' | 'Failed' | 'Denied'
export type AuditAction = 'READ' | 'WRITE' | 'VERIFY' | 'GRANT CONSENT' | 'REVOKE CONSENT' | 'APPROVE'

export interface AuditLogEntry {
  id: string
  timestamp: string
  actor: string
  department: string
  action: AuditAction
  resource: string
  result: AuditResult
}

export const auditLogs: AuditLogEntry[] = [
  { id: 'aud-1', timestamp: '2026-08-27T10:42:00', actor: 'Education Officer', department: 'Education Department', action: 'READ', resource: 'Income Information', result: 'Success' },
  { id: 'aud-2', timestamp: '2026-08-27T10:41:00', actor: 'Citizen', department: 'Unified Portal', action: 'GRANT CONSENT', resource: 'Academic Details', result: 'Success' },
  { id: 'aud-3', timestamp: '2026-08-27T10:39:00', actor: 'Revenue Officer', department: 'Revenue Department', action: 'VERIFY', resource: 'Income Certificate', result: 'Success' },
  { id: 'aud-4', timestamp: '2026-08-26T16:05:00', actor: 'Municipal Officer', department: 'Municipal Corporation', action: 'READ', resource: 'Property Records', result: 'Denied' },
  { id: 'aud-5', timestamp: '2026-08-26T14:22:00', actor: 'Citizen', department: 'Unified Portal', action: 'REVOKE CONSENT', resource: 'Health Records', result: 'Success' },
  { id: 'aud-6', timestamp: '2026-08-26T11:10:00', actor: 'Health Officer', department: 'Health Department', action: 'READ', resource: 'Insurance Eligibility', result: 'Success' },
  { id: 'aud-7', timestamp: '2026-08-25T09:47:00', actor: 'Revenue Officer', department: 'Revenue Department', action: 'WRITE', resource: 'Income Certificate Status', result: 'Success' },
  { id: 'aud-8', timestamp: '2026-08-25T09:02:00', actor: 'System', department: 'Interoperability Layer', action: 'VERIFY', resource: 'Citizen Identity Mapping', result: 'Failed' },
  { id: 'aud-9', timestamp: '2026-08-24T16:32:00', actor: 'Business Registry Officer', department: 'Business Registry', action: 'APPROVE', resource: 'Business Registration APP-2026-1003', result: 'Success' },
  { id: 'aud-10', timestamp: '2026-08-23T10:15:00', actor: 'Welfare Officer', department: 'Social Welfare Department', action: 'READ', resource: 'Pension Eligibility', result: 'Success' },
  { id: 'aud-11', timestamp: '2026-08-20T12:03:00', actor: 'Citizen', department: 'Unified Portal', action: 'GRANT CONSENT', resource: 'Income Certificate', result: 'Success' },
  { id: 'aud-12', timestamp: '2026-08-19T15:40:00', actor: 'Education Officer', department: 'Education Department', action: 'READ', resource: 'Academic Records', result: 'Success' },
]

export const auditDepartments = Array.from(new Set(auditLogs.map((l) => l.department)))
export const auditActions = Array.from(new Set(auditLogs.map((l) => l.action)))
export const auditResults: AuditResult[] = ['Success', 'Failed', 'Denied']
