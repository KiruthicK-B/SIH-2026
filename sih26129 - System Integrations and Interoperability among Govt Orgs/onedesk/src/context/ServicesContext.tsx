import { createContext, type ReactNode, useContext, useEffect, useState } from 'react'
import { useAuth } from '@/context/AuthContext'
import type { Service } from '@/data/services'
import { api } from '@/lib/api'

interface ServicesContextValue {
  services: Service[]
  categories: string[]
  loading: boolean
  getServiceById: (id: string) => Service | undefined
  getServicesByCategory: (category: string) => Service[]
}

const ServicesContext = createContext<ServicesContextValue | null>(null)

export function ServicesProvider({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth()
  const [services, setServices] = useState<Service[]>([])
  const [categories, setCategories] = useState<string[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!isAuthenticated) return
    setLoading(true)
    api
      .get<{ categories: string[]; services: Service[] }>('/services')
      .then((data) => {
        setCategories(data.categories)
        setServices(data.services)
      })
      .finally(() => setLoading(false))
  }, [isAuthenticated])

  const getServiceById = (id: string) => services.find((s) => s.id === id)
  const getServicesByCategory = (category: string) => services.filter((s) => s.category === category)

  return (
    <ServicesContext.Provider value={{ services, categories, loading, getServiceById, getServicesByCategory }}>
      {children}
    </ServicesContext.Provider>
  )
}

export function useServices() {
  const ctx = useContext(ServicesContext)
  if (!ctx) throw new Error('useServices must be used within ServicesProvider')
  return ctx
}
