import { createContext, useContext, type ReactNode } from 'react'
import { useOrcaChat } from '@/lib/useOrcaChat'

type OrcaChatValue = ReturnType<typeof useOrcaChat>

const OrcaChatContext = createContext<OrcaChatValue | null>(null)

export function OrcaChatProvider({ children }: { children: ReactNode }) {
  const value = useOrcaChat()
  return <OrcaChatContext.Provider value={value}>{children}</OrcaChatContext.Provider>
}

export function useOrcaChatContext() {
  const ctx = useContext(OrcaChatContext)
  if (!ctx) throw new Error('useOrcaChatContext must be used within OrcaChatProvider')
  return ctx
}
