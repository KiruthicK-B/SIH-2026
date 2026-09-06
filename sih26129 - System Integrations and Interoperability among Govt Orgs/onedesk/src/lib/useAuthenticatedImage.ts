import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

/** Fetches an auth-protected image path (e.g. /identity/me/photo) as a blob and
 * exposes it as an object URL — a plain <img src> can't carry the Bearer token. */
export function useAuthenticatedImage(path: string | null): string | null {
  const [objectUrl, setObjectUrl] = useState<string | null>(null)

  useEffect(() => {
    if (!path) {
      setObjectUrl(null)
      return
    }
    let url: string | null = null
    api
      .getBlob(path)
      .then((blob) => {
        url = URL.createObjectURL(blob)
        setObjectUrl(url)
      })
      .catch(() => setObjectUrl(null))
    return () => {
      if (url) URL.revokeObjectURL(url)
    }
  }, [path])

  return objectUrl
}
