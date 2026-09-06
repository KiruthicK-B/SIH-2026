import { api } from './api'

const KEYCLOAK_URL = import.meta.env.VITE_KEYCLOAK_URL ?? 'http://localhost:8080'
const KEYCLOAK_REALM = import.meta.env.VITE_KEYCLOAK_REALM ?? 'onedesk'
const KEYCLOAK_CLIENT_ID = import.meta.env.VITE_KEYCLOAK_CLIENT_ID ?? 'onedesk-frontend'

export interface DirectGrantTokens {
  token: string
  refreshToken: string
  idToken: string
}

export class DirectGrantError extends Error {}

/**
 * Custom-branded sign-in against Keycloak's Direct Access Grant (Resource Owner
 * Password Credentials) flow — already enabled on the `onedesk-frontend` client.
 * Replaces the old redirect-to-Keycloak's-own-hosted-page flow: identifier and
 * password are both collected on this page, in one step, never on a Keycloak-branded
 * screen. The identifier (mobile / citizen ID / Aadhaar) still resolves to the
 * underlying Keycloak username first, via the same endpoint the old flow used.
 */
export async function directGrantLogin(identifier: string, password: string): Promise<DirectGrantTokens> {
  const trimmed = identifier.trim()
  let username = trimmed
  try {
    const resolved = await api.post<{ username: string }>('/auth/resolve-identifier', { identifier: trimmed })
    username = resolved.username
  } catch {
    // Not a phone/citizen-ID/Aadhaar match — officers/admins sign in with their own
    // username directly, which won't resolve here; fall back to using it as-is.
  }

  const res = await fetch(`${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'password',
      client_id: KEYCLOAK_CLIENT_ID,
      scope: 'openid',
      username,
      password,
    }),
  })

  if (!res.ok) {
    throw new DirectGrantError('Incorrect ID or password.')
  }

  const data = await res.json()
  return { token: data.access_token, refreshToken: data.refresh_token, idToken: data.id_token }
}
