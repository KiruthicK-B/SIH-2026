import { createContext, type ReactNode, useContext, useEffect, useState } from 'react'
import { useAuth } from '@/context/AuthContext'
import { api } from '@/lib/api'

export interface DepartmentIdentifier {
  department: string
  identifier: string
  confidence?: number
}

export interface MasterIdentity {
  masterId: string
  citizenName: string
  phoneNumber: string | null
  dateOfBirth: string | null
  gender: string | null
  address: string | null
  annualIncome: string | null
  educationDetails: string | null
  panNumber: string | null
  employmentStatus: string | null
  employerName: string | null
  designation: string | null
  highestQualification: string | null
  institutionName: string | null
  occupation: string | null
  fatherName: string | null
  motherName: string | null
  parentPhoneNumber: string | null
  siblings: string | null
  photoUrl: string | null
  departmentIdentifiers: DepartmentIdentifier[]
}

interface IdentityContextValue {
  identity: MasterIdentity | null
  loading: boolean
}

const IdentityContext = createContext<IdentityContextValue | null>(null)

export function IdentityProvider({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth()
  const [identity, setIdentity] = useState<MasterIdentity | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!isAuthenticated) return
    setLoading(true)
    api
      .get<MasterIdentity>('/identity/me')
      .then(setIdentity)
      .catch(() => setIdentity(null))
      .finally(() => setLoading(false))
  }, [isAuthenticated])

  return <IdentityContext.Provider value={{ identity, loading }}>{children}</IdentityContext.Provider>
}

export function useIdentity() {
  const ctx = useContext(IdentityContext)
  if (!ctx) throw new Error('useIdentity must be used within IdentityProvider')
  return ctx
}
