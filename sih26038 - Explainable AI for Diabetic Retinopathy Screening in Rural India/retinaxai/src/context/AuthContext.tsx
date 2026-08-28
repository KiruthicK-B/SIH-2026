import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react'

export type Role = 'Clinician' | 'Operator'

interface AuthState {
  isAuthenticated: boolean
  clinicianName: string
  role: Role
  login: (name?: string) => void
  logout: () => void
  setRole: (role: Role) => void
}

const AuthContext = createContext<AuthState | null>(null)

const STORAGE_KEY = 'retinaxai.auth'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(() => localStorage.getItem(STORAGE_KEY) === 'true')
  const [clinicianName, setClinicianName] = useState(() => localStorage.getItem('retinaxai.clinician') || 'Dr. Smith')
  const [role, setRoleState] = useState<Role>(() => (localStorage.getItem('retinaxai.role') as Role) || 'Clinician')

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, String(isAuthenticated))
  }, [isAuthenticated])

  useEffect(() => {
    localStorage.setItem('retinaxai.clinician', clinicianName)
  }, [clinicianName])

  useEffect(() => {
    localStorage.setItem('retinaxai.role', role)
  }, [role])

  const value = useMemo<AuthState>(
    () => ({
      isAuthenticated,
      clinicianName,
      role,
      login: (name?: string) => {
        if (name) setClinicianName(name)
        setIsAuthenticated(true)
      },
      logout: () => setIsAuthenticated(false),
      setRole: (r: Role) => setRoleState(r),
    }),
    [isAuthenticated, clinicianName, role],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
