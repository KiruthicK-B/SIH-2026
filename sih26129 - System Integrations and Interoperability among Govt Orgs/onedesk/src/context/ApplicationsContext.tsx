import { createContext, type ReactNode, useContext, useState } from 'react'
import { type Application, applications as initialApplications } from '@/data/applications'

interface NewApplicationInput {
  service: string
  department: string
  citizenName: string
  description: string
}

export interface WorkflowEvent {
  title: string
  description: string
  tone: 'success' | 'warning'
}

interface ApplicationsContextValue {
  applications: Application[]
  getApplicationById: (id: string) => Application | undefined
  submitApplication: (input: NewApplicationInput) => Application
  advanceApplication: (id: string) => WorkflowEvent | null
}

const ApplicationsContext = createContext<ApplicationsContextValue | null>(null)

let sequence = 1007

export function ApplicationsProvider({ children }: { children: ReactNode }) {
  const [applications, setApplications] = useState<Application[]>(initialApplications)

  const submitApplication = (input: NewApplicationInput) => {
    const today = new Date().toISOString().slice(0, 10)
    const isBusinessLicense = input.service === 'Business License'

    const newApplication: Application = {
      id: isBusinessLicense ? `BL-2026-${sequence++}` : `APP-2026-${sequence++}`,
      service: input.service,
      department: input.department,
      status: 'In Progress',
      lastUpdated: today,
      submittedOn: today,
      citizenName: input.citizenName,
      description: input.description,
      flagship: isBusinessLicense,
      timeline: isBusinessLicense
        ? [
            { label: 'Application Submitted', department: 'OneDesk', status: 'done', date: today, systemType: 'Unified Portal' },
            { label: 'Identity Verified', department: 'Identity Service', status: 'active', systemType: 'OAuth / Federation' },
            { label: 'Business Details Verified', department: 'Business Registry', status: 'pending', systemType: 'Legacy SOAP' },
            { label: 'Tax Verification', department: 'Revenue Department', status: 'pending', systemType: 'REST API' },
            { label: 'Municipal Review', department: 'Municipal Corporation', status: 'pending', systemType: 'Legacy Database Adapter' },
            { label: 'Final Approval', department: 'License Authority', status: 'pending', systemType: 'REST API' },
          ]
        : [
            { label: 'Application Submitted', department: 'Unified Portal', status: 'done', date: today },
            { label: 'Documents Verified', department: input.department, status: 'pending' },
            { label: 'Eligibility Verification', department: input.department, status: 'pending' },
            { label: 'Department Approval', department: input.department, status: 'pending' },
            { label: 'Application Completed', department: input.department, status: 'pending' },
          ],
    }
    setApplications((prev) => [newApplication, ...prev])
    return newApplication
  }

  const getApplicationById = (id: string) => applications.find((a) => a.id === id)

  const advanceApplication = (id: string): WorkflowEvent | null => {
    const today = new Date().toISOString().slice(0, 10)
    let event: WorkflowEvent | null = null

    setApplications((prev) =>
      prev.map((app) => {
        if (app.id !== id) return app
        const steps = app.timeline.map((s) => ({ ...s }))

        const blockedIdx = steps.findIndex((s) => s.status === 'blocked')
        if (blockedIdx !== -1) {
          const step = steps[blockedIdx]
          steps[blockedIdx] = { ...step, status: 'done', date: today, note: undefined }
          event = {
            title: `${step.label} completed`,
            description: `${step.department} recovered and confirmed ${step.label.toLowerCase()} after retry.`,
            tone: 'success',
          }
          const nextIdx = steps.findIndex((s, i) => i > blockedIdx && s.status === 'pending')
          if (nextIdx !== -1) steps[nextIdx] = { ...steps[nextIdx], status: 'active' }
        } else {
          const activeIdx = steps.findIndex((s) => s.status === 'active')
          if (activeIdx === -1) return app

          const step = steps[activeIdx]
          const isFlakySystem = step.department === 'Municipal Corporation'

          if (isFlakySystem) {
            steps[activeIdx] = {
              ...step,
              status: 'blocked',
              note: `${step.department} system is temporarily unavailable. Retry scheduled — other steps are unaffected.`,
            }
            event = {
              title: `${step.department} unavailable`,
              description: `${step.label} could not complete right now. The platform has scheduled an automatic retry.`,
              tone: 'warning',
            }
          } else {
            steps[activeIdx] = { ...step, status: 'done', date: today }
            event = {
              title: `${step.label} completed`,
              description: `${step.department} confirmed ${step.label.toLowerCase()}.`,
              tone: 'success',
            }
            const nextIdx = activeIdx + 1
            if (nextIdx < steps.length && steps[nextIdx].status === 'pending') {
              steps[nextIdx] = { ...steps[nextIdx], status: 'active' }
            }
          }
        }

        const allDone = steps.every((s) => s.status === 'done')
        return {
          ...app,
          timeline: steps,
          status: allDone ? 'Completed' : app.status,
          lastUpdated: today,
        }
      }),
    )

    return event
  }

  return (
    <ApplicationsContext.Provider value={{ applications, getApplicationById, submitApplication, advanceApplication }}>
      {children}
    </ApplicationsContext.Provider>
  )
}

export function useApplications() {
  const ctx = useContext(ApplicationsContext)
  if (!ctx) throw new Error('useApplications must be used within ApplicationsProvider')
  return ctx
}
