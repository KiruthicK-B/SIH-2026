import { createContext, type ReactNode, useContext, useEffect, useState } from 'react'
import { PageLoader } from '@/components/layout/PageLoader'
import { clearDirectGrantTokens, initKeycloak, keycloak } from '@/lib/keycloak'

interface AuthContextValue {
  isAuthenticated: boolean
  username: string | null
  name: string | null
  email: string | null
  masterId: string | null
  login: (loginHint?: string) => void
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [ready, setReady] = useState(false)
  const [isAuthenticated, setIsAuthenticated] = useState(false)

  useEffect(() => {
    keycloak.onAuthSuccess = () => setIsAuthenticated(true)
    keycloak.onAuthLogout = () => setIsAuthenticated(false)
    keycloak.onTokenExpired = () => {
      // A dead refresh token means the session is over — this fires from
      // keycloak-js's own background timer, with no user action involved, so it
      // must never silently redirect to Keycloak's raw hosted login page (that's
      // exactly what directGrantAuth.ts's custom Login page exists to replace).
      keycloak.updateToken(30).catch(() => {
        clearDirectGrantTokens()
        window.location.assign('/login')
      })
    }

    initKeycloak().then((authenticated) => {
      setIsAuthenticated(authenticated)
      setReady(true)
    })
  }, [])

  // loginHint pre-fills (doesn't lock) the username field on Keycloak's hosted login
  // page — used by the identifier-resolution flow (mobile / citizen ID / Aadhaar-style
  // number all resolve to the same underlying Keycloak username before redirecting).
  const login = (loginHint?: string) => keycloak.login(loginHint ? { loginHint } : undefined)
  const logout = () => {
    clearDirectGrantTokens()
    keycloak.logout({ redirectUri: `${window.location.origin}/login` })
  }

  if (!ready) return <PageLoader />

  return (
    <AuthContext.Provider
      value={{
        isAuthenticated,
        username: (keycloak.tokenParsed?.['preferred_username'] as string) ?? null,
        name: (keycloak.tokenParsed?.['name'] as string) ?? null,
        email: (keycloak.tokenParsed?.['email'] as string) ?? null,
        masterId: (keycloak.tokenParsed?.['master_id'] as string) ?? null,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
