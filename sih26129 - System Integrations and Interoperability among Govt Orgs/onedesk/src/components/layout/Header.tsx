import * as DropdownMenu from '@radix-ui/react-dropdown-menu'
import { Bell, Building2, ChevronDown, FileText, LayoutGrid, LogOut, Search, Settings, User } from 'lucide-react'
import { type ReactNode, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { useNavigate } from 'react-router-dom'
import { RoleSwitcher } from '@/components/layout/RoleSwitcher'
import { LanguageSwitcher } from '@/components/shared/LanguageSwitcher'
import { useAuth } from '@/context/AuthContext'
import { useIdentity } from '@/context/IdentityContext'
import { useNotifications } from '@/context/NotificationsContext'
import { useRole } from '@/context/RoleContext'
import { useSearch } from '@/context/SearchContext'
import { useAuthenticatedImage } from '@/lib/useAuthenticatedImage'
import { cn } from '@/lib/utils'

function initialsOf(name: string) {
  const parts = name.trim().split(/\s+/)
  return ((parts[0]?.[0] ?? '') + (parts[1]?.[0] ?? '')).toUpperCase() || '?'
}

export function Header() {
  const { t } = useTranslation()
  const { query, setQuery, results } = useSearch()
  const { unreadCount } = useNotifications()
  const { logout, name, username } = useAuth()
  const { identity } = useIdentity()
  const { role } = useRole()
  const displayName = name ?? username ?? 'Signed-in user'
  const photoObjectUrl = useAuthenticatedImage(identity?.photoUrl ?? null)
  const navigate = useNavigate()
  const [searchFocused, setSearchFocused] = useState(false)

  const hasResults = results.applications.length + results.services.length + results.departments.length > 0
  const showDropdown = searchFocused && query.trim().length > 0

  const goTo = (path: string) => {
    setQuery('')
    setSearchFocused(false)
    navigate(path)
  }

  return (
    <header className="flex h-16 shrink-0 items-center justify-between gap-4 border-b border-gray-200 bg-white px-6">
      <div className="relative w-full max-w-md">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setSearchFocused(true)}
          onBlur={() => setTimeout(() => setSearchFocused(false), 150)}
          placeholder={t('header.searchPlaceholder')}
          className="h-9 w-full rounded-md border border-gray-300 bg-gray-50 pl-9 pr-3 text-sm text-gray-700 placeholder:text-gray-400 focus:border-brand-500 focus:bg-white focus:outline-none focus:ring-1 focus:ring-brand-500"
        />

        {showDropdown && (
          <div className="absolute left-0 right-0 top-11 z-40 max-h-96 overflow-y-auto rounded-md border border-gray-200 bg-white p-2 shadow-lg">
            {!hasResults && <p className="px-3 py-4 text-sm text-gray-400">{t('header.noMatches')}</p>}

            {results.applications.length > 0 && (
              <SearchGroup label={t('header.groupApplications')}>
                {results.applications.map((a) => (
                  <SearchRow
                    key={a.id}
                    icon={FileText}
                    title={a.id}
                    subtitle={`${a.service} · ${a.department}`}
                    onClick={() => goTo(`/applications/${a.id}`)}
                  />
                ))}
              </SearchGroup>
            )}

            {results.services.length > 0 && (
              <SearchGroup label={t('header.groupServices')}>
                {results.services.map((s) => (
                  <SearchRow
                    key={s.id}
                    icon={LayoutGrid}
                    title={s.name}
                    subtitle={s.department}
                    onClick={() => goTo(`/services/${s.id}`)}
                  />
                ))}
              </SearchGroup>
            )}

            {results.departments.length > 0 && (
              <SearchGroup label={t('header.groupDepartments')}>
                {results.departments.map((d) => (
                  <SearchRow
                    key={d.id}
                    icon={Building2}
                    title={d.name}
                    subtitle={`${d.serviceCount} services`}
                    onClick={() => goTo(`/departments/${d.id}`)}
                  />
                ))}
              </SearchGroup>
            )}
          </div>
        )}
      </div>

      <div className="flex items-center gap-3">
        <LanguageSwitcher />
        <div className="hidden h-6 w-px bg-gray-200 md:block" />
        <RoleSwitcher />
        <div className="hidden h-6 w-px bg-gray-200 md:block" />
        <button
          onClick={() => navigate('/notifications')}
          className="relative flex h-9 w-9 items-center justify-center rounded-md text-gray-500 hover:bg-gray-100 hover:text-gray-700"
        >
          <Bell className="h-[18px] w-[18px]" />
          {unreadCount > 0 && (
            <span className="absolute right-1.5 top-1.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-danger-600 px-1 text-[10px] font-semibold text-white">
              {unreadCount}
            </span>
          )}
        </button>

        <DropdownMenu.Root>
          <DropdownMenu.Trigger asChild>
            <button className="flex items-center gap-2 rounded-md py-1.5 pl-1.5 pr-2 text-left hover:bg-gray-100">
              {photoObjectUrl ? (
                <img src={photoObjectUrl} alt="" className="h-7 w-7 rounded-full object-cover" />
              ) : (
                <div className="flex h-7 w-7 items-center justify-center rounded-full bg-navy-800 text-xs font-semibold text-white">
                  {initialsOf(displayName)}
                </div>
              )}
              <div className="hidden sm:block">
                <p className="text-sm font-medium leading-tight text-gray-900">{displayName}</p>
                <p className="text-[11px] leading-tight text-gray-500">{role}</p>
              </div>
              <ChevronDown className="h-3.5 w-3.5 text-gray-400" />
            </button>
          </DropdownMenu.Trigger>
          <DropdownMenu.Portal>
            <DropdownMenu.Content
              align="end"
              sideOffset={8}
              className="z-50 w-48 rounded-md border border-gray-200 bg-white p-1 shadow-md"
            >
              <DropdownMenu.Item
                onSelect={() => navigate('/settings')}
                className={cn(
                  'flex cursor-pointer items-center gap-2 rounded-sm px-2.5 py-2 text-sm text-gray-700 outline-none',
                  'data-[highlighted]:bg-gray-100',
                )}
              >
                <User className="h-4 w-4" /> {t('header.profile')}
              </DropdownMenu.Item>
              <DropdownMenu.Item
                onSelect={() => navigate('/settings')}
                className="flex cursor-pointer items-center gap-2 rounded-sm px-2.5 py-2 text-sm text-gray-700 outline-none data-[highlighted]:bg-gray-100"
              >
                <Settings className="h-4 w-4" /> {t('header.settings')}
              </DropdownMenu.Item>
              <DropdownMenu.Separator className="my-1 h-px bg-gray-100" />
              <DropdownMenu.Item
                onSelect={() => logout()}
                className="flex cursor-pointer items-center gap-2 rounded-sm px-2.5 py-2 text-sm text-gray-700 outline-none data-[highlighted]:bg-gray-100"
              >
                <LogOut className="h-4 w-4" /> {t('header.signOut')}
              </DropdownMenu.Item>
            </DropdownMenu.Content>
          </DropdownMenu.Portal>
        </DropdownMenu.Root>
      </div>
    </header>
  )
}

function SearchGroup({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="mb-1">
      <p className="px-3 py-1 text-[10px] font-semibold uppercase tracking-wide text-gray-400">{label}</p>
      {children}
    </div>
  )
}

function SearchRow({
  icon: Icon,
  title,
  subtitle,
  onClick,
}: {
  icon: typeof FileText
  title: string
  subtitle: string
  onClick: () => void
}) {
  return (
    <button
      onMouseDown={(e) => e.preventDefault()}
      onClick={onClick}
      className="flex w-full items-center gap-2.5 rounded-sm px-3 py-2 text-left hover:bg-gray-50"
    >
      <Icon className="h-4 w-4 shrink-0 text-gray-400" />
      <div className="min-w-0">
        <p className="truncate text-sm font-medium text-gray-900">{title}</p>
        <p className="truncate text-xs text-gray-500">{subtitle}</p>
      </div>
    </button>
  )
}
