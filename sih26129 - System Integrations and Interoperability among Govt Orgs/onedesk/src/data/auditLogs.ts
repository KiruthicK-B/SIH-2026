// Runtime audit data now lives in core-api/Postgres (see pages/AuditLog.tsx, which
// fetches from GET /audit, /audit/departments, /audit/actions). This file keeps only
// the shared type contract.

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
  purpose?: string
  consentId?: string
}

export const auditResults: AuditResult[] = ['Success', 'Failed', 'Denied']
