import {
  Bell,
  Building2,
  ClipboardCheck,
  FileText,
  FolderOpen,
  HelpCircle,
  LayoutDashboard,
  LayoutGrid,
  MessageSquareWarning,
  Network,
  Settings,
  ShieldCheck,
  type LucideIcon,
} from 'lucide-react'
import { NavLink } from 'react-router-dom'
import { useRole } from '@/context/RoleContext'
import { cn } from '@/lib/utils'

interface NavItem {
  label: string
  to: string
  icon: LucideIcon
}

interface NavGroup {
  title: string
  items: NavItem[]
}

const navGroups: NavGroup[] = [
  {
    title: 'Overview',
    items: [
      { label: 'Dashboard', to: '/dashboard', icon: LayoutDashboard },
      { label: 'My Applications', to: '/applications', icon: FileText },
    ],
  },
  {
    title: 'Services',
    items: [
      { label: 'Browse Services', to: '/services', icon: LayoutGrid },
      { label: 'Departments', to: '/departments', icon: Building2 },
    ],
  },
  {
    title: 'Data & Access',
    items: [
      { label: 'My Consents', to: '/consents', icon: ShieldCheck },
      { label: 'My Documents', to: '/documents', icon: FolderOpen },
    ],
  },
  {
    title: 'Support',
    items: [
      { label: 'Notifications', to: '/notifications', icon: Bell },
      { label: 'Grievances', to: '/grievances', icon: MessageSquareWarning },
      { label: 'Help & Support', to: '/help', icon: HelpCircle },
    ],
  },
]

const platformNavGroup: NavGroup = {
  title: 'Platform',
  items: [
    { label: 'Government Platform', to: '/platform', icon: Network },
    { label: 'Audit & Compliance', to: '/audit', icon: ClipboardCheck },
  ],
}

export function Sidebar() {
  const { role, isPlatformRole } = useRole()

  return (
    <aside className="flex h-full w-64 shrink-0 flex-col bg-navy-950 text-white">
      <div className="flex items-center gap-2.5 px-5 py-5">
        <img src="/logo-mark.png" alt="OneDesk" className="h-9 w-9 object-contain" />
        <div>
          <p className="text-sm font-semibold leading-tight text-white">OneDesk</p>
          <p className="text-[11px] leading-tight text-slate-400">
            Unified Services, Seamless Access
          </p>
        </div>
      </div>

      <nav className="scrollbar-thin flex-1 space-y-6 overflow-y-auto px-3 py-2">
        {navGroups.map((group) => (
          <div key={group.title}>
            <p className="mb-1.5 px-3 text-[10px] font-semibold uppercase tracking-wider text-slate-500">
              {group.title}
            </p>
            <div className="space-y-0.5">
              {group.items.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  className={({ isActive }) =>
                    cn(
                      'flex items-center gap-2.5 rounded-md px-3 py-2 text-sm font-medium text-slate-300 transition-colors',
                      'hover:bg-white/5 hover:text-white',
                      isActive && 'bg-brand-500/15 text-white',
                    )
                  }
                >
                  <item.icon className="h-4 w-4 shrink-0" />
                  {item.label}
                </NavLink>
              ))}
            </div>
          </div>
        ))}

        {isPlatformRole && (
          <div>
            <p className="mb-1.5 flex items-center gap-1.5 px-3 text-[10px] font-semibold uppercase tracking-wider text-teal-400">
              <span className="h-1 w-1 rounded-full bg-teal-400" /> {platformNavGroup.title} · {role}
            </p>
            <div className="space-y-0.5">
              {platformNavGroup.items.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  className={({ isActive }) =>
                    cn(
                      'flex items-center gap-2.5 rounded-md px-3 py-2 text-sm font-medium text-slate-300 transition-colors',
                      'hover:bg-white/5 hover:text-white',
                      isActive && 'bg-teal-500/15 text-white',
                    )
                  }
                >
                  <item.icon className="h-4 w-4 shrink-0" />
                  {item.label}
                </NavLink>
              ))}
            </div>
          </div>
        )}
      </nav>

      <div className="border-t border-white/10 px-3 py-3">
        <NavLink
          to="/settings"
          className={({ isActive }) =>
            cn(
              'flex items-center gap-2.5 rounded-md px-3 py-2 text-sm font-medium text-slate-300 transition-colors hover:bg-white/5 hover:text-white',
              isActive && 'bg-brand-500/15 text-white',
            )
          }
        >
          <Settings className="h-4 w-4 shrink-0" />
          Settings
        </NavLink>
      </div>

      <div className="flex items-center gap-3 border-t border-white/10 px-5 py-4">
        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-brand-500/20 text-sm font-semibold text-brand-100">
          KB
        </div>
        <div className="min-w-0">
          <p className="text-[11px] uppercase tracking-wide text-slate-500">Citizen</p>
          <p className="truncate text-sm font-medium text-white">Kiruthick B</p>
          <p className="truncate text-xs text-slate-500">OneDesk ID: CIT-10282</p>
        </div>
      </div>
    </aside>
  )
}
