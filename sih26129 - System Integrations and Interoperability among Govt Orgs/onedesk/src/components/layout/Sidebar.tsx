import {
  Bell,
  Building2,
  ClipboardCheck,
  Database,
  FileText,
  FolderOpen,
  GitBranch,
  HelpCircle,
  LayoutDashboard,
  LayoutGrid,
  MessageSquareWarning,
  Network,
  Settings,
  ShieldCheck,
  UserCheck,
  type LucideIcon,
} from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { NavLink } from 'react-router-dom'
import { Wordmark } from '@/components/branding/Wordmark'
import { useAuth } from '@/context/AuthContext'
import { useRole } from '@/context/RoleContext'
import { cn } from '@/lib/utils'

interface NavItem {
  labelKey: string
  to: string
  icon: LucideIcon
}

interface NavGroup {
  titleKey: string
  items: NavItem[]
}

const navGroups: NavGroup[] = [
  {
    titleKey: 'nav.groupOverview',
    items: [
      { labelKey: 'nav.dashboard', to: '/dashboard', icon: LayoutDashboard },
      { labelKey: 'nav.myApplications', to: '/applications', icon: FileText },
    ],
  },
  {
    titleKey: 'nav.groupServices',
    items: [
      { labelKey: 'nav.browseServices', to: '/services', icon: LayoutGrid },
      { labelKey: 'nav.departments', to: '/departments', icon: Building2 },
    ],
  },
  {
    titleKey: 'nav.groupDataAccess',
    items: [
      { labelKey: 'nav.myConsents', to: '/consents', icon: ShieldCheck },
      { labelKey: 'nav.myDocuments', to: '/documents', icon: FolderOpen },
    ],
  },
  {
    titleKey: 'nav.groupSupport',
    items: [
      { labelKey: 'nav.notifications', to: '/notifications', icon: Bell },
      { labelKey: 'nav.grievances', to: '/grievances', icon: MessageSquareWarning },
      { labelKey: 'nav.helpSupport', to: '/help', icon: HelpCircle },
    ],
  },
]

const platformNavGroup: NavGroup = {
  titleKey: 'nav.groupPlatform',
  items: [
    { labelKey: 'nav.officerDashboard', to: '/officer-dashboard', icon: UserCheck },
    { labelKey: 'nav.governmentPlatform', to: '/platform', icon: Network },
    { labelKey: 'nav.auditCompliance', to: '/audit', icon: ClipboardCheck },
  ],
}

// Platform Administrator's entire job is administering the interoperability
// layer — Government Platform leads, not a citizen dashboard with "Platform"
// bolted on underneath. Applying for a service is a citizen action (see
// RequireCitizenAccess), so nothing citizen-self-service-shaped appears here.
const adminNavGroups: NavGroup[] = [
  {
    titleKey: 'nav.groupPlatform',
    items: [
      { labelKey: 'nav.governmentPlatform', to: '/platform', icon: Network },
      { labelKey: 'nav.architectureDataMapping', to: '/architecture', icon: GitBranch },
      { labelKey: 'nav.govtIdentityRegistry', to: '/govt-registry', icon: Database },
      { labelKey: 'nav.auditCompliance', to: '/audit', icon: ClipboardCheck },
      { labelKey: 'nav.officerDashboard', to: '/officer-dashboard', icon: UserCheck },
    ],
  },
  {
    titleKey: 'nav.groupDirectory',
    items: [{ labelKey: 'nav.departments', to: '/departments', icon: Building2 }],
  },
  {
    titleKey: 'nav.groupSupport',
    items: [
      { labelKey: 'nav.notifications', to: '/notifications', icon: Bell },
      { labelKey: 'nav.helpSupport', to: '/help', icon: HelpCircle },
    ],
  },
]

function initialsOf(name: string) {
  const parts = name.trim().split(/\s+/)
  return ((parts[0]?.[0] ?? '') + (parts[1]?.[0] ?? '')).toUpperCase() || '?'
}

export function Sidebar() {
  const { t } = useTranslation()
  const { role, isPlatformRole, isAdminOnly } = useRole()
  const { name, username, masterId } = useAuth()
  const displayName = name ?? username ?? 'Signed-in user'

  const visibleNavGroups = isAdminOnly ? adminNavGroups : navGroups
  // Officers get the citizen nav plus this teal-branded addendum below; admins
  // already have their platform items as the primary (first) group above.
  const showPlatformAddendum = isPlatformRole && !isAdminOnly

  return (
    <aside className="flex h-full w-64 shrink-0 flex-col bg-navy-950 text-white">
      <div className="px-5 py-5">
        <Wordmark size="sm" dark />
        <p className="mt-1 text-[11px] leading-tight text-slate-400">{t('sidebar.tagline')}</p>
      </div>

      <nav className="scrollbar-thin flex-1 space-y-6 overflow-y-auto px-3 py-2">
        {visibleNavGroups.map((group) => (
          <div key={group.titleKey}>
            <p className="mb-1.5 px-3 text-[10px] font-semibold uppercase tracking-wider text-slate-500">
              {t(group.titleKey)}
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
                  {t(item.labelKey)}
                </NavLink>
              ))}
            </div>
          </div>
        ))}

        {showPlatformAddendum && (
          <div>
            <p className="mb-1.5 flex items-center gap-1.5 px-3 text-[10px] font-semibold uppercase tracking-wider text-teal-400">
              <span className="h-1 w-1 rounded-full bg-teal-400" /> {t(platformNavGroup.titleKey)} ·{' '}
              {t(`roles.${role}`, { defaultValue: role })}
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
                  {t(item.labelKey)}
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
          {t('nav.settings')}
        </NavLink>
      </div>

      <div className="flex items-center gap-3 border-t border-white/10 px-5 py-4">
        <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-brand-500/20 text-sm font-semibold text-brand-100">
          {initialsOf(displayName)}
        </div>
        <div className="min-w-0">
          <p className="text-[11px] uppercase tracking-wide text-slate-500">{t(`roles.${role}`, { defaultValue: role })}</p>
          <p className="truncate text-sm font-medium text-white">{displayName}</p>
          {masterId && <p className="truncate text-xs text-slate-500">{t('sidebar.oneDeskId', { id: masterId })}</p>}
        </div>
      </div>
    </aside>
  )
}
