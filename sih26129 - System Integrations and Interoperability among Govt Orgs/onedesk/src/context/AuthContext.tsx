import { createContext, type ReactNode, useContext, useState } from 'react'

interface AuthContextValue {
  isAuthenticated: boolean
  citizenId: string | null
  login: (citizenId: string, password: string) => void
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)
const STORAGE_KEY = 'onedesk.citizenId'

export function AuthProvider({ children }: { children: ReactNode }) {
  const [citizenId, setCitizenId] = useState<string | null>(() => localStorage.getItem(STORAGE_KEY))

  const login = (id: string, _password: string) => {
    localStorage.setItem(STORAGE_KEY, id)
    setCitizenId(id)
  }

  const logout = () => {
    localStorage.removeItem(STORAGE_KEY)
    setCitizenId(null)
  }

  return (
    <AuthContext.Provider value={{ isAuthenticated: !!citizenId, citizenId, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
