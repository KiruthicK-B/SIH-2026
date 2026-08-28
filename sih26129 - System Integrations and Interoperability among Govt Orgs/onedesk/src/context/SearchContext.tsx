import { createContext, type ReactNode, useContext, useMemo, useState } from 'react'
import { useApplications } from '@/context/ApplicationsContext'
import type { Application } from '@/data/applications'
import { citizenFacingDepartments as departments } from '@/data/departments'
import { services } from '@/data/services'

interface SearchResultGroup {
  applications: Application[]
  services: typeof services
  departments: typeof departments
}

interface SearchContextValue {
  query: string
  setQuery: (q: string) => void
  results: SearchResultGroup
}

const SearchContext = createContext<SearchContextValue | null>(null)

export function SearchProvider({ children }: { children: ReactNode }) {
  const [query, setQuery] = useState('')
  const { applications } = useApplications()

  const results = useMemo<SearchResultGroup>(() => {
    const q = query.trim().toLowerCase()
    if (!q) {
      return { applications: [], services: [], departments: [] }
    }
    return {
      applications: applications.filter(
        (a) => a.id.toLowerCase().includes(q) || a.service.toLowerCase().includes(q) || a.department.toLowerCase().includes(q),
      ),
      services: services.filter((s) => s.name.toLowerCase().includes(q) || s.department.toLowerCase().includes(q)),
      departments: departments.filter((d) => d.name.toLowerCase().includes(q)),
    }
  }, [query, applications])

  return <SearchContext.Provider value={{ query, setQuery, results }}>{children}</SearchContext.Provider>
}

export function useSearch() {
  const ctx = useContext(SearchContext)
  if (!ctx) throw new Error('useSearch must be used within SearchProvider')
  return ctx
}
