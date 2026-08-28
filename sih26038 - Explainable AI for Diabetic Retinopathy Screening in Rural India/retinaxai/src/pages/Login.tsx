import { useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import { Eye, LogIn } from 'lucide-react'
import { useAuth } from '@/context/AuthContext'
import { Button } from '@/components/ui/Button'

export default function Login() {
  const { isAuthenticated, login } = useAuth()
  const navigate = useNavigate()
  const [name, setName] = useState('Dr. Smith')
  const [password, setPassword] = useState('')

  if (isAuthenticated) return <Navigate to="/app/dashboard" replace />

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    login(name || 'Dr. Smith')
    navigate('/app/dashboard')
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#f4f6fb] px-4">
      <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-7 shadow-sm">
        <div className="mb-6 flex flex-col items-center text-center">
          <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-brand-600 text-white">
            <Eye className="h-6 w-6" />
          </div>
          <h1 className="text-lg font-bold text-gray-900">Welcome to RetinaXAI</h1>
          <p className="mt-1 text-xs text-gray-500">Sign in to continue screening</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">Clinician Name</label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
              placeholder="Dr. Smith"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-500 focus:ring-1 focus:ring-brand-500"
              placeholder="••••••••"
            />
          </div>
          <Button type="submit" className="w-full">
            <LogIn className="h-4 w-4" />
            Sign In
          </Button>
        </form>

        <p className="mt-5 text-center text-[11px] text-gray-400">
          Demo prototype — any credentials will sign you in as a clinician.
        </p>
      </div>
    </div>
  )
}
