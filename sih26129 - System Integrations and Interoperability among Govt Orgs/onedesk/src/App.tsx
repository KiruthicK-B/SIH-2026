import { Navigate, Route, Routes } from 'react-router-dom'
import { AppShell } from '@/components/layout/AppShell'
import { RequirePlatformAccess } from '@/components/layout/RequirePlatformAccess'
import { useAuth } from '@/context/AuthContext'
import ApplicationDetails from '@/pages/ApplicationDetails'
import Applications from '@/pages/Applications'
import ApplicationWizard from '@/pages/ApplicationWizard'
import AuditLog from '@/pages/AuditLog'
import Consents from '@/pages/Consents'
import Dashboard from '@/pages/Dashboard'
import DepartmentDetails from '@/pages/DepartmentDetails'
import Departments from '@/pages/Departments'
import Documents from '@/pages/Documents'
import GovernmentPlatform from '@/pages/GovernmentPlatform'
import Grievances from '@/pages/Grievances'
import Help from '@/pages/Help'
import Login from '@/pages/Login'
import Notifications from '@/pages/Notifications'
import ServiceDetails from '@/pages/ServiceDetails'
import Services from '@/pages/Services'
import Settings from '@/pages/Settings'

function RequireAuth() {
  const { isAuthenticated } = useAuth()
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }
  return <AppShell />
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/" element={<RequireAuth />}>
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<Dashboard />} />
        <Route path="applications" element={<Applications />} />
        <Route path="applications/:id" element={<ApplicationDetails />} />
        <Route path="services" element={<Services />} />
        <Route path="services/:id" element={<ServiceDetails />} />
        <Route path="services/:id/apply" element={<ApplicationWizard />} />
        <Route path="departments" element={<Departments />} />
        <Route path="departments/:id" element={<DepartmentDetails />} />
        <Route path="consents" element={<Consents />} />
        <Route path="documents" element={<Documents />} />
        <Route path="notifications" element={<Notifications />} />
        <Route path="grievances" element={<Grievances />} />
        <Route path="platform" element={<GovernmentPlatform />} />
        <Route
          path="audit"
          element={
            <RequirePlatformAccess>
              <AuditLog />
            </RequirePlatformAccess>
          }
        />
        <Route path="help" element={<Help />} />
        <Route path="settings" element={<Settings />} />
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Route>
    </Routes>
  )
}
