// Mirrors onedesk/src/data/auditLogs.ts, plus `purpose` / `consentId` — added so the
// audit trail can actually answer "why" and "under what consent", not just who/what/when.

export type AuditResult = 'Success' | 'Failed' | 'Denied';
export type AuditAction = 'READ' | 'WRITE' | 'VERIFY' | 'GRANT CONSENT' | 'REVOKE CONSENT' | 'APPROVE';

export interface AuditLogEntry {
  id: string;
  timestamp: string;
  actor: string;
  department: string;
  action: AuditAction;
  resource: string;
  result: AuditResult;
  purpose?: string;
  consentId?: string;
}
