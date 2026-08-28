import { ShieldAlert } from 'lucide-react'
import type { ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { Button } from '@/components/ui/Button'
import { useRole } from '@/context/RoleContext'

export function RequirePlatformAccess({ children }: { children: ReactNode }) {
  const { isPlatformRole } = useRole()
  const navigate = useNavigate()

  if (isPlatformRole) {
    return <>{children}</>
  }

  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center text-center">
      <div className="flex h-14 w-14 items-center justify-center rounded-full bg-gray-100 text-gray-400">
        <ShieldAlert className="h-6 w-6" />
      </div>
      <h1 className="mt-4 text-base font-semibold text-gray-900">Platform access restricted</h1>
      <p className="mt-1.5 max-w-sm text-sm text-gray-500">
        This area is for department officers and platform administrators. Citizens only see their own
        applications, documents, and consents — never internal integration or system data.
      </p>
      <Button variant="outline" className="mt-5" onClick={() => navigate('/dashboard')}>
        Back to dashboard
      </Button>
    </div>
  )
}
