import { createContext, type ReactNode, useContext } from 'react'
import { useAuth } from '@/context/AuthContext'
import { keycloak } from '@/lib/keycloak'

export type Role = 'Citizen' | 'Department Officer' | 'Platform Administrator'

export const roleDescriptions: Record<Role, string> = {
  Citizen: 'View your own applications, grant or revoke consent, and receive notifications.',
  'Department Officer': 'View applications authorized to your department and process workflow steps. Cannot access unrelated department data.',
  'Platform Administrator': 'Monitor connected systems, integration health, exceptions, SLA compliance, and audit trails across all departments.',
}

// Realm roles (Keycloak) -> frontend Role labels. Role is now issued by Keycloak and
// carried in the JWT's realm_access.roles claim — it is no longer a client-settable
// value, closing the devtools/localStorage RBAC-bypass gap the old RoleContext had.
const REALM_ROLE_TO_FRONTEND: Record<string, Role> = {
  citizen: 'Citizen',
  officer: 'Department Officer',
  'platform-admin': 'Platform Administrator',
}

interface RoleContextValue {
  role: Role
  department: string | null
  isPlatformRole: boolean
  isAdminOnly: boolean
}

const RoleContext = createContext<RoleContextValue | null>(null)

export function RoleProvider({ children }: { children: ReactNode }) {
  // Subscribing to useAuth() ties RoleProvider's re-renders to Keycloak auth-state
  // changes (login/logout/token refresh) so `role` below stays in sync.
  const { isAuthenticated } = useAuth()

  const realmRoles = (keycloak.tokenParsed?.['realm_access']?.roles ?? []) as string[]
  const matchedRealmRole = Object.keys(REALM_ROLE_TO_FRONTEND).find((r) => realmRoles.includes(r))
  const role: Role = isAuthenticated && matchedRealmRole ? REALM_ROLE_TO_FRONTEND[matchedRealmRole] : 'Citizen'
  const department = (keycloak.tokenParsed?.['department'] as string | undefined) ?? null

  return (
    <RoleContext.Provider
      value={{ role, department, isPlatformRole: role !== 'Citizen', isAdminOnly: role === 'Platform Administrator' }}
    >
      {children}
    </RoleContext.Provider>
  )
}

export function useRole() {
  const ctx = useContext(RoleContext)
  if (!ctx) throw new Error('useRole must be used within RoleProvider')
  return ctx
}
