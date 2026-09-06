// Runtime identity data now lives in core-api/Postgres (see IdentityContext.tsx,
// which fetches from GET /identity/me). This file keeps only the shared type contract.

export interface DepartmentIdentifier {
  department: string
  identifier: string
}
