import { Route, Routes } from 'react-router-dom'
import { OrcaChatProvider } from '@/context/OrcaChatContext'

import Dashboard from '@/pages/Dashboard'
import ChatPage from '@/pages/ChatPage'
import MarineMap from '@/pages/MarineMap'
import AlertsPage from '@/pages/AlertsPage'
import PFZFinder from '@/pages/PFZFinder'
import WeatherOcean from '@/pages/WeatherOcean'
import Tides from '@/pages/Tides'
import RoutesNavigation from '@/pages/RoutesNavigation'
import Boundaries from '@/pages/Boundaries'
import Reports from '@/pages/Reports'
import Settings from '@/pages/Settings'
import About from '@/pages/About'

export default function App() {
  return (
    <OrcaChatProvider>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/chat" element={<ChatPage />} />
        <Route path="/marine-map" element={<MarineMap />} />
        <Route path="/alerts" element={<AlertsPage />} />
        <Route path="/pfz-finder" element={<PFZFinder />} />
        <Route path="/weather" element={<WeatherOcean />} />
        <Route path="/tides" element={<Tides />} />
        <Route path="/routes" element={<RoutesNavigation />} />
        <Route path="/boundaries" element={<Boundaries />} />
        <Route path="/reports" element={<Reports />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/about" element={<About />} />
      </Routes>
    </OrcaChatProvider>
  )
}
