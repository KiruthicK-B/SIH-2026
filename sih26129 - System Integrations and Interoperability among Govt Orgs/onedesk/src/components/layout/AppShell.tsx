import { useEffect, useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import { Header } from '@/components/layout/Header'
import { PageLoader } from '@/components/layout/PageLoader'
import { Sidebar } from '@/components/layout/Sidebar'

export function AppShell() {
  const location = useLocation()
  const [isLoading, setIsLoading] = useState(false)

  useEffect(() => {
    setIsLoading(true)
    const timer = setTimeout(() => setIsLoading(false), 450)
    return () => clearTimeout(timer)
  }, [location.pathname])

  return (
    <div className="flex h-screen w-full overflow-hidden bg-gray-50">
      <Sidebar />
      <div className="flex min-w-0 flex-1 flex-col">
        <Header />
        <div className="h-1 shrink-0 bg-gradient-to-r from-[#FF9933] via-white to-[#138808]" />
        <main className="scrollbar-thin flex-1 overflow-y-auto px-6 py-6">
          <div className="mx-auto max-w-[1400px]">{isLoading ? <PageLoader /> : <Outlet />}</div>
        </main>
      </div>
    </div>
  )
}
