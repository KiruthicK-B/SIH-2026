import Keycloak from 'keycloak-js'

export const keycloak = new Keycloak({
  url: import.meta.env.VITE_KEYCLOAK_URL ?? 'http://localhost:8080',
  realm: import.meta.env.VITE_KEYCLOAK_REALM ?? 'onedesk',
  clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID ?? 'onedesk-frontend',
})

const STORAGE_KEY = 'onedesk_direct_grant_tokens'

interface StoredTokens {
  token: string
  refreshToken: string
  idToken: string
}

/** Called right after a successful custom-form login (see directGrantAuth.ts), and
 * kept rolling on every token refresh — a direct-grant session never gets Keycloak's
 * own browser SSO cookie, so `check-sso` can't restore it on a hard reload the way
 * the old redirect flow could. This is the substitute persistence. */
export function persistDirectGrantTokens(tokens: StoredTokens) {
  sessionStorage.setItem(STORAGE_KEY, JSON.stringify(tokens))
}

export function clearDirectGrantTokens() {
  sessionStorage.removeItem(STORAGE_KEY)
}

function readStoredTokens(): StoredTokens | null {
  const raw = sessionStorage.getItem(STORAGE_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as StoredTokens
  } catch {
    return null
  }
}

let initPromise: Promise<boolean> | null = null

/** Idempotent — safe to call more than once (React StrictMode double-invokes effects). */
export function initKeycloak(): Promise<boolean> {
  if (!initPromise) {
    const stored = readStoredTokens()

    keycloak.onAuthRefreshSuccess = () => {
      if (keycloak.token && keycloak.refreshToken) {
        persistDirectGrantTokens({ token: keycloak.token, refreshToken: keycloak.refreshToken, idToken: keycloak.idToken ?? '' })
      }
    }

    initPromise = keycloak
      .init(
        stored
          ? {
              token: stored.token,
              refreshToken: stored.refreshToken,
              idToken: stored.idToken,
              // A direct-grant session never gets Keycloak's own browser SSO cookie
              // (no redirect ever happened) — the login-status iframe check has
              // nothing valid to compare against and was flipping the session back
              // to unauthenticated moments after a successful login.
              checkLoginIframe: false,
            }
          : {
              onLoad: 'check-sso',
              pkceMethod: 'S256',
              silentCheckSsoRedirectUri: `${window.location.origin}/silent-check-sso.html`,
              checkLoginIframe: false,
            },
      )
      .then((authenticated) => {
        if (authenticated && keycloak.token && keycloak.refreshToken) {
          persistDirectGrantTokens({ token: keycloak.token, refreshToken: keycloak.refreshToken, idToken: keycloak.idToken ?? '' })
        } else {
          clearDirectGrantTokens()
        }
        return authenticated
      })
      .catch(() => {
        // A stored token pair that's fully expired (refresh token too) fails init —
        // fall back to a clean unauthenticated state rather than a stuck error screen.
        clearDirectGrantTokens()
        return false
      })
  }
  return initPromise
}
