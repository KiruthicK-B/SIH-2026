import { useEffect } from 'react'
import { keycloak } from './keycloak'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8010/api'

/**
 * Subscribes to core-api's application-events SSE stream and invokes `onMessage` for
 * every update. The browser's native EventSource can't send an Authorization header,
 * so the token travels as a query param — verified server-side the same way as every
 * other request (see ApplicationsEventsController).
 */
export function useApplicationEvents(onMessage: (data: unknown) => void, enabled: boolean) {
  useEffect(() => {
    if (!enabled || !keycloak.token) return

    const url = `${API_BASE_URL}/applications/events/stream?token=${encodeURIComponent(keycloak.token)}`
    const source = new EventSource(url)

    source.onmessage = (event) => {
      try {
        onMessage(JSON.parse(event.data))
      } catch {
        // heartbeat / comment lines have no `data:` payload and never reach onmessage
      }
    }

    return () => source.close()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [enabled, keycloak.token])
}
