import { createContext, type ReactNode, useContext, useState } from 'react'

export type Role = 'Citizen' | 'Department Officer' | 'Platform Administrator'

export const roleDescriptions: Record<Role, string> = {
  Citizen: 'View your own applications, grant or revoke consent, and receive notifications.',
  'Department Officer': 'View applications authorized to your department and process workflow steps. Cannot access unrelated department data.',
  'Platform Administrator': 'Monitor connected systems, integration health, exceptions, SLA compliance, and audit trails across all departments.',
}

interface RoleContextValue {
  role: Role
  setRole: (role: Role) => void
  isPlatformRole: boolean
}

const RoleContext = createContext<RoleContextValue | null>(null)
const STORAGE_KEY = 'onedesk.role'

export function RoleProvider({ children }: { children: ReactNode }) {
  const [role, setRole] = useState<Role>(() => (localStorage.getItem(STORAGE_KEY) as Role) || 'Citizen')

  const updateRole = (next: Role) => {
    localStorage.setItem(STORAGE_KEY, next)
    setRole(next)
  }

  return (
    <RoleContext.Provider value={{ role, setRole: updateRole, isPlatformRole: role !== 'Citizen' }}>
      {children}
    </RoleContext.Provider>
  )
}

export function useRole() {
  const ctx = useContext(RoleContext)
  if (!ctx) throw new Error('useRole must be used within RoleProvider')
  return ctx
}
