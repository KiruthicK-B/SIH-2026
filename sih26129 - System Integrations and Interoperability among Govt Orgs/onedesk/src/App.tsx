import { Navigate, Route, Routes } from 'react-router-dom'
import { AppShell } from '@/components/layout/AppShell'
import { RequireCitizenAccess } from '@/components/layout/RequireCitizenAccess'
import { RequirePlatformAccess } from '@/components/layout/RequirePlatformAccess'
import { useAuth } from '@/context/AuthContext'
import { useRole } from '@/context/RoleContext'
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
import GovtRegistry from '@/pages/GovtRegistry'
import Help from '@/pages/Help'
import Home from '@/pages/Home'
import Login from '@/pages/Login'
import Notifications from '@/pages/Notifications'
import OfficerDashboard from '@/pages/OfficerDashboard'
import Register from '@/pages/Register'
import ServiceDetails from '@/pages/ServiceDetails'
import Services from '@/pages/Services'
import Settings from '@/pages/Settings'
import SystemArchitecture from '@/pages/SystemArchitecture'

function RequireAuth() {
  const { isAuthenticated } = useAuth()
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }
  return <AppShell />
}

function DashboardRoute() {
  const { isAdminOnly } = useRole()
  if (isAdminOnly) return <Navigate to="/platform" replace />
  return <Dashboard />
}

// The govt registry holds full mock-citizen PII and is platform-admin-only on the
// backend (RolesGuard @Roles('platform-admin')) — officers get redirected rather
// than hitting a 403 from every fetch.
function GovtRegistryRoute() {
  const { isAdminOnly } = useRole()
  if (!isAdminOnly) return <Navigate to="/platform" replace />
  return <GovtRegistry />
}

// Same restriction the tabs had inline (role === 'Platform Administrator') before
// being promoted out of Government Platform's tab list — officers redirected rather
// than landing on an admin-only diagram.
function SystemArchitectureRoute() {
  const { isAdminOnly } = useRole()
  if (!isAdminOnly) return <Navigate to="/platform" replace />
  return <SystemArchitecture />
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      {/* Pathless layout route — RequireAuth wraps every authenticated page without
          itself claiming "/", which the public Home route above owns. Children still
          resolve to their normal absolute paths (/dashboard, /applications, ...). */}
      <Route element={<RequireAuth />}>
        <Route path="dashboard" element={<DashboardRoute />} />
        <Route
          path="applications"
          element={
            <RequireCitizenAccess>
              <Applications />
            </RequireCitizenAccess>
          }
        />
        <Route
          path="applications/:id"
          element={
            <RequireCitizenAccess>
              <ApplicationDetails />
            </RequireCitizenAccess>
          }
        />
        <Route
          path="services"
          element={
            <RequireCitizenAccess>
              <Services />
            </RequireCitizenAccess>
          }
        />
        <Route path="services/:id" element={<ServiceDetails />} />
        <Route
          path="services/:id/apply"
          element={
            <RequireCitizenAccess>
              <ApplicationWizard />
            </RequireCitizenAccess>
          }
        />
        <Route path="departments" element={<Departments />} />
        <Route path="departments/:id" element={<DepartmentDetails />} />
        <Route path="consents" element={<Consents />} />
        <Route
          path="documents"
          element={
            <RequireCitizenAccess>
              <Documents />
            </RequireCitizenAccess>
          }
        />
        <Route path="notifications" element={<Notifications />} />
        <Route
          path="grievances"
          element={
            <RequireCitizenAccess>
              <Grievances />
            </RequireCitizenAccess>
          }
        />
        <Route
          path="platform"
          element={
            <RequirePlatformAccess>
              <GovernmentPlatform />
            </RequirePlatformAccess>
          }
        />
        <Route
          path="govt-registry"
          element={
            <RequirePlatformAccess>
              <GovtRegistryRoute />
            </RequirePlatformAccess>
          }
        />
        <Route
          path="architecture"
          element={
            <RequirePlatformAccess>
              <SystemArchitectureRoute />
            </RequirePlatformAccess>
          }
        />
        <Route
          path="officer-dashboard"
          element={
            <RequirePlatformAccess>
              <OfficerDashboard />
            </RequirePlatformAccess>
          }
        />
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
