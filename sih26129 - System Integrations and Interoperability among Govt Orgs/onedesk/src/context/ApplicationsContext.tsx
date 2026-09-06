import { createContext, type ReactNode, useContext, useEffect, useState } from 'react'
import { useAuth } from '@/context/AuthContext'
import type { Application } from '@/data/applications'
import { api } from '@/lib/api'
import { useApplicationEvents } from '@/lib/useEventSource'

interface NewApplicationInput {
  service: string
  department: string
  citizenName: string
  description: string
  documentIds?: string[]
}

export interface WorkflowEvent {
  title: string
  description: string
  tone: 'success' | 'warning'
}

interface ApplicationsContextValue {
  applications: Application[]
  loading: boolean
  getApplicationById: (id: string) => Application | undefined
  submitApplication: (input: NewApplicationInput) => Promise<Application>
  advanceApplication: (id: string) => Promise<WorkflowEvent | null>
  approveMunicipalReview: (id: string) => Promise<WorkflowEvent>
  refresh: () => Promise<void>
}

const ApplicationsContext = createContext<ApplicationsContextValue | null>(null)

export function ApplicationsProvider({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth()
  const [applications, setApplications] = useState<Application[]>([])
  const [loading, setLoading] = useState(true)

  const refresh = async () => {
    const data = await api.get<Application[]>('/applications')
    setApplications(data)
  }

  useEffect(() => {
    if (!isAuthenticated) return
    setLoading(true)
    refresh().finally(() => setLoading(false))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated])

  // Live cross-department orchestration pushes updates over SSE — no polling, no
  // manual refresh needed to watch a Business License move across departments.
  useApplicationEvents((data) => {
    const updated = data as Application
    setApplications((prev) => (prev.some((a) => a.id === updated.id) ? prev.map((a) => (a.id === updated.id ? updated : a)) : prev))
  }, isAuthenticated)

  const submitApplication = async (input: NewApplicationInput) => {
    const created = await api.post<Application>('/applications', input)
    setApplications((prev) => [created, ...prev])
    return created
  }

  const getApplicationById = (id: string) => applications.find((a) => a.id === id)

  const advanceApplication = async (id: string): Promise<WorkflowEvent | null> => {
    const event = await api.post<WorkflowEvent | null>(`/applications/${id}/advance`)
    const updated = await api.get<Application>(`/applications/${id}`)
    setApplications((prev) => prev.map((a) => (a.id === id ? updated : a)))
    return event
  }

  const approveMunicipalReview = async (id: string): Promise<WorkflowEvent> => {
    // The SSE stream also carries the resulting timeline update — this call just
    // triggers it and returns the event for the toast/notification.
    return api.post<WorkflowEvent>(`/applications/${id}/municipal-review/approve`)
  }

  return (
    <ApplicationsContext.Provider
      value={{ applications, loading, getApplicationById, submitApplication, advanceApplication, approveMunicipalReview, refresh }}
    >
      {children}
    </ApplicationsContext.Provider>
  )
}

export function useApplications() {
  const ctx = useContext(ApplicationsContext)
  if (!ctx) throw new Error('useApplications must be used within ApplicationsProvider')
  return ctx
}
