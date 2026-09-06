import { createContext, type ReactNode, useContext, useMemo, useState } from 'react'
import { useApplications } from '@/context/ApplicationsContext'
import { useDepartments } from '@/context/DepartmentsContext'
import { useServices } from '@/context/ServicesContext'
import type { Application } from '@/data/applications'
import type { Department } from '@/data/departments'
import type { Service } from '@/data/services'

interface SearchResultGroup {
  applications: Application[]
  services: Service[]
  departments: Department[]
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
  const { citizenFacingDepartments: departments } = useDepartments()
  const { services } = useServices()

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
  }, [query, applications, departments, services])

  return <SearchContext.Provider value={{ query, setQuery, results }}>{children}</SearchContext.Provider>
}

export function useSearch() {
  const ctx = useContext(SearchContext)
  if (!ctx) throw new Error('useSearch must be used within SearchProvider')
  return ctx
}
