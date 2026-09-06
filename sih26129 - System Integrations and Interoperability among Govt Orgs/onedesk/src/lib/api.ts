import { clearDirectGrantTokens, keycloak } from './keycloak'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8010/api'
const MDM_BASE_URL = import.meta.env.VITE_MDM_BASE_URL ?? 'http://localhost:8010/mdm'

// A dead refresh token means the session is over — send the browser back to
// OneDesk's own custom-branded Login page, never to Keycloak's raw hosted login
// screen (keycloak.login() would redirect there, which is exactly the login flow
// this app deliberately replaced with directGrantAuth.ts).
function expireSession(): never {
  clearDirectGrantTokens()
  window.location.assign('/login')
  throw new ApiError(401, 'session expired')
}

export class ApiError extends Error {
  status: number

  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}

function makeClient(baseUrl: string) {
  async function request<T>(path: string, init?: RequestInit): Promise<T> {
    if (keycloak.token) {
      try {
        await keycloak.updateToken(30)
      } catch {
        expireSession()
      }
    }

    // FormData bodies must NOT get a JSON Content-Type — the browser sets its own
    // multipart boundary, which is lost if we override it here.
    const isFormData = init?.body instanceof FormData

    const res = await fetch(`${baseUrl}${path}`, {
      ...init,
      headers: {
        ...(isFormData ? {} : { 'Content-Type': 'application/json' }),
        ...(keycloak.token ? { Authorization: `Bearer ${keycloak.token}` } : {}),
        ...init?.headers,
      },
    })

    if (!res.ok) {
      const body = await res.json().catch(() => ({}))
      throw new ApiError(res.status, body.message ?? res.statusText)
    }
    if (res.status === 204) return undefined as T
    return res.json()
  }

  async function getBlob(path: string): Promise<Blob> {
    if (keycloak.token) {
      try {
        await keycloak.updateToken(30)
      } catch {
        expireSession()
      }
    }
    const res = await fetch(`${baseUrl}${path}`, {
      headers: keycloak.token ? { Authorization: `Bearer ${keycloak.token}` } : {},
    })
    if (!res.ok) throw new ApiError(res.status, res.statusText)
    return res.blob()
  }

  return {
    get: <T>(path: string) => request<T>(path),
    post: <T>(path: string, body?: unknown) => request<T>(path, { method: 'POST', body: body ? JSON.stringify(body) : undefined }),
    postFile: <T>(path: string, file: File) => {
      const formData = new FormData()
      formData.append('file', file)
      return request<T>(path, { method: 'POST', body: formData })
    },
    getBlob,
  }
}

/** core-api, via Kong's /api route. */
export const api = makeClient(API_BASE_URL)

/** mdm-service, via Kong's /mdm route — separate path prefix, same gateway. */
export const mdmApi = makeClient(MDM_BASE_URL)
