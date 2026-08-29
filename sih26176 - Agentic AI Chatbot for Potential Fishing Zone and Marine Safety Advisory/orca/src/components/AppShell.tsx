import { type ReactNode, useState } from 'react'
import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard,
  MessageSquare,
  Map as MapIcon,
  AlertTriangle,
  Fish,
  CloudSun,
  Waves,
  Navigation2,
  ShieldAlert,
  FileBarChart,
  Settings as SettingsIcon,
  Search,
  Bell,
  Globe,
  Send,
} from 'lucide-react'
import { useOrcaChatContext } from '@/context/OrcaChatContext'

const NAV = [
  { label: 'Dashboard', to: '/', icon: LayoutDashboard },
  { label: 'Chat with ORCA', to: '/chat', icon: MessageSquare },
  { label: 'Marine Map', to: '/marine-map', icon: MapIcon },
  { label: 'Alerts', to: '/alerts', icon: AlertTriangle },
  { label: 'PFZ Finder', to: '/pfz-finder', icon: Fish },
  { label: 'Weather & Ocean', to: '/weather', icon: CloudSun },
  { label: 'Tides', to: '/tides', icon: Waves },
  { label: 'Routes & Navigation', to: '/routes', icon: Navigation2 },
  { label: 'Boundaries', to: '/boundaries', icon: ShieldAlert },
  { label: 'Reports', to: '/reports', icon: FileBarChart },
  { label: 'Settings', to: '/settings', icon: SettingsIcon },
]

export function AppShell({ children }: { children: ReactNode }) {
  const { messages, sendMessage } = useOrcaChatContext()
  const navigate = useNavigate()
  const [search, setSearch] = useState('')

  const lastAlerts = [...messages].reverse().find((m) => m.attachment?.alerts?.length)?.attachment?.alerts ?? []

  function handleSearch() {
    if (!search.trim()) return
    sendMessage(search)
    setSearch('')
    navigate('/chat')
  }

  return (
    <div className="flex h-screen bg-navy-950">
      <aside className="flex w-60 shrink-0 flex-col border-r border-navy-700 bg-navy-900">
        <div className="flex items-center gap-2 border-b border-navy-700 px-4 py-4">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-cyan-500/15 text-lg">🐋</div>
          <div>
            <p className="text-sm font-bold leading-tight text-white">ORCA</p>
            <p className="text-[9px] leading-tight text-slate-500">Marine Intelligence</p>
          </div>
        </div>

        <nav className="flex-1 space-y-0.5 overflow-y-auto px-2.5 py-3">
          {NAV.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                `flex items-center justify-between rounded-lg px-3 py-2 text-xs font-medium transition-colors ${
                  isActive ? 'bg-cyan-500/15 text-cyan-300' : 'text-slate-400 hover:bg-navy-800 hover:text-slate-200'
                }`
              }
            >
              <span className="flex items-center gap-2.5">
                <item.icon className="h-4 w-4" />
                {item.label}
              </span>
              {item.label === 'Alerts' && lastAlerts.length > 0 && (
                <span className="rounded-full bg-danger-500 px-1.5 py-0.5 text-[9px] font-bold text-white">{lastAlerts.length}</span>
              )}
            </NavLink>
          ))}
        </nav>

        <div className="space-y-1.5 border-t border-navy-700 px-3.5 py-3">
          <p className="flex items-center gap-1.5 text-[10px] font-medium text-success-500">
            <span className="h-1.5 w-1.5 rounded-full bg-success-500" /> All Systems Operational
          </p>
          <p className="text-[9px] text-slate-500">Data updated {new Date().toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })}</p>
        </div>
      </aside>

      <div className="flex flex-1 flex-col overflow-hidden">
        <header className="flex items-center gap-4 border-b border-navy-700 bg-navy-900 px-5 py-3">
          <div className="relative flex-1 max-w-xl">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
              placeholder="Ask anything about oceans..."
              className="w-full rounded-lg border border-navy-600 bg-navy-800 py-2 pl-9 pr-9 text-sm text-slate-100 placeholder:text-slate-500 outline-none focus:border-cyan-500"
            />
            <button onClick={handleSearch} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-500 hover:text-cyan-400">
              <Send className="h-3.5 w-3.5" />
            </button>
          </div>

          <button className="flex items-center gap-1.5 rounded-lg border border-navy-600 px-2.5 py-1.5 text-xs text-slate-300">
            <Globe className="h-3.5 w-3.5" /> English
          </button>

          <button onClick={() => navigate('/alerts')} className="relative text-slate-400 hover:text-slate-200">
            <Bell className="h-5 w-5" />
            {lastAlerts.length > 0 && (
              <span className="absolute -right-1.5 -top-1.5 flex h-4 w-4 items-center justify-center rounded-full bg-danger-500 text-[9px] font-bold text-white">
                {lastAlerts.length}
              </span>
            )}
          </button>

          <div className="flex items-center gap-2 border-l border-navy-700 pl-4">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-cyan-500/20 text-xs font-bold text-cyan-300">FS</div>
            <div>
              <p className="text-xs font-semibold text-white">Fisherman</p>
              <p className="text-[10px] text-slate-500">Chennai, India</p>
            </div>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto p-5">{children}</main>
      </div>
    </div>
  )
}
