import { type ReactNode } from 'react'
import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard,
  ScanEye,
  Users,
  FileText,
  User,
  Settings,
  LogOut,
  Eye,
  ShieldCheck,
} from 'lucide-react'
import { useAuth } from '@/context/AuthContext'
import { DisclaimerBanner } from './DisclaimerBanner'

interface NavItem {
  label: string
  to: string
  icon: typeof LayoutDashboard
}

const clinicianNav: NavItem[] = [
  { label: 'Dashboard', to: '/app/dashboard', icon: LayoutDashboard },
  { label: 'Screenings', to: '/app/screenings', icon: ScanEye },
  { label: 'Patients', to: '/app/patients', icon: Users },
  { label: 'Reports', to: '/app/reports', icon: FileText },
  { label: 'Profile', to: '/app/profile', icon: User },
]

const operatorNav: NavItem[] = [
  { label: 'Dashboard', to: '/operator/dashboard', icon: LayoutDashboard },
  { label: 'Patients', to: '/operator/patients', icon: Users },
  { label: 'Screenings', to: '/operator/screenings', icon: ScanEye },
  { label: 'Simulation', to: '/operator/simulation', icon: Settings },
]

export function AppShell({ children, area }: { children: ReactNode; area: 'clinician' | 'operator' }) {
  const { clinicianName, role, setRole, logout } = useAuth()
  const navigate = useNavigate()
  const nav = area === 'clinician' ? clinicianNav : operatorNav

  return (
    <div className="flex min-h-screen bg-[#f4f6fb]">
      <aside className="flex w-64 shrink-0 flex-col border-r border-gray-200 bg-white">
        <div className="flex items-center gap-2 border-b border-gray-100 px-5 py-4">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-brand-600 text-white">
            <Eye className="h-5 w-5" />
          </div>
          <div>
            <p className="text-sm font-bold leading-tight text-gray-900">RetinaXAI</p>
            <p className="text-[10px] leading-tight text-gray-400">Detect. Explain. Assist.</p>
          </div>
        </div>

        <nav className="flex-1 space-y-1 px-3 py-4">
          {nav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                  isActive ? 'bg-brand-50 text-brand-700' : 'text-gray-600 hover:bg-gray-50'
                }`
              }
            >
              <item.icon className="h-4.5 w-4.5" />
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="space-y-3 border-t border-gray-100 p-3">
          <button
            onClick={() => {
              const next = role === 'Clinician' ? 'Operator' : 'Clinician'
              setRole(next)
              navigate(next === 'Clinician' ? '/app/dashboard' : '/operator/dashboard')
            }}
            className="flex w-full items-center gap-2 rounded-lg border border-gray-200 px-3 py-2 text-xs font-medium text-gray-600 hover:bg-gray-50"
          >
            <ShieldCheck className="h-3.5 w-3.5" />
            Switch to {role === 'Clinician' ? 'Operator' : 'Clinician'} view
          </button>
          <div className="flex items-center gap-2 rounded-lg bg-gray-50 px-3 py-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-100 text-xs font-bold text-brand-700">
              {clinicianName
                .split(' ')
                .map((s) => s[0])
                .join('')}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-xs font-semibold text-gray-800">{clinicianName}</p>
              <p className="text-[10px] text-gray-400">{role}</p>
            </div>
            <button onClick={() => { logout(); navigate('/') }} className="text-gray-400 hover:text-gray-600" aria-label="Log out">
              <LogOut className="h-4 w-4" />
            </button>
          </div>
        </div>
      </aside>

      <main className="flex-1 overflow-y-auto">
        <div className="mx-auto max-w-7xl px-6 py-6">
          <div className="mb-5">
            <DisclaimerBanner compact />
          </div>
          {children}
        </div>
      </main>
    </div>
  )
}
