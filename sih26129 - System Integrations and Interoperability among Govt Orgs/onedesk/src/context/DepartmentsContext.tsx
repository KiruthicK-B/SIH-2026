import { createContext, type ReactNode, useContext, useEffect, useState } from 'react'
import { useAuth } from '@/context/AuthContext'
import type { Department } from '@/data/departments'
import { api } from '@/lib/api'

interface DepartmentsContextValue {
  departments: Department[]
  citizenFacingDepartments: Department[]
  loading: boolean
  getDepartmentById: (id: string) => Department | undefined
  refresh: () => Promise<void>
}

const DepartmentsContext = createContext<DepartmentsContextValue | null>(null)

export function DepartmentsProvider({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth()
  const [departments, setDepartments] = useState<Department[]>([])
  const [loading, setLoading] = useState(true)

  const refresh = async () => {
    const data = await api.get<Department[]>('/departments')
    setDepartments(data)
  }

  useEffect(() => {
    if (!isAuthenticated) return
    setLoading(true)
    refresh().finally(() => setLoading(false))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isAuthenticated])

  const getDepartmentById = (id: string) => departments.find((d) => d.id === id)
  const citizenFacingDepartments = departments.filter((d) => d.name !== 'Identity Service')

  return (
    <DepartmentsContext.Provider value={{ departments, citizenFacingDepartments, loading, getDepartmentById, refresh }}>
      {children}
    </DepartmentsContext.Provider>
  )
}

export function useDepartments() {
  const ctx = useContext(DepartmentsContext)
  if (!ctx) throw new Error('useDepartments must be used within DepartmentsProvider')
  return ctx
}
