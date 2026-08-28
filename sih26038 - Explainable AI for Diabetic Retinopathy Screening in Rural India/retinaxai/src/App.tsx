import { Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider, useAuth } from '@/context/AuthContext'
import { ScreeningsProvider } from '@/context/ScreeningsContext'
import type { ReactNode } from 'react'

import Landing from '@/pages/Landing'
import Login from '@/pages/Login'
import Dashboard from '@/pages/clinician/Dashboard'
import Upload from '@/pages/clinician/Upload'
import QualityAssessment from '@/pages/clinician/QualityAssessment'
import AnalysisProgress from '@/pages/clinician/AnalysisProgress'
import ResultSummary from '@/pages/clinician/ResultSummary'
import LesionOverlay from '@/pages/clinician/LesionOverlay'
import VesselMap from '@/pages/clinician/VesselMap'
import AnatomicalLandmarksPage from '@/pages/clinician/AnatomicalLandmarks'
import GradCamView from '@/pages/clinician/GradCamView'
import FullReport from '@/pages/clinician/FullReport'
import ScreeningsList from '@/pages/clinician/ScreeningsList'
import PatientsList from '@/pages/clinician/PatientsList'
import Profile from '@/pages/clinician/Profile'
import OperatorDashboard from '@/pages/operator/OperatorDashboard'
import SimulinkSimulation from '@/pages/operator/SimulinkSimulation'

function RequireAuth({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth()
  if (!isAuthenticated) return <Navigate to="/login" replace />
  return <>{children}</>
}

export default function App() {
  return (
    <AuthProvider>
      <ScreeningsProvider>
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/login" element={<Login />} />

          <Route path="/app/dashboard" element={<RequireAuth><Dashboard /></RequireAuth>} />
          <Route path="/app/upload" element={<RequireAuth><Upload /></RequireAuth>} />
          <Route path="/app/screenings" element={<RequireAuth><ScreeningsList /></RequireAuth>} />
          <Route path="/app/patients" element={<RequireAuth><PatientsList /></RequireAuth>} />
          <Route path="/app/reports" element={<RequireAuth><ScreeningsList reportsMode /></RequireAuth>} />
          <Route path="/app/profile" element={<RequireAuth><Profile /></RequireAuth>} />

          <Route path="/app/screening/:id/quality" element={<RequireAuth><QualityAssessment /></RequireAuth>} />
          <Route path="/app/screening/:id/analyzing" element={<RequireAuth><AnalysisProgress /></RequireAuth>} />
          <Route path="/app/screening/:id/result" element={<RequireAuth><ResultSummary /></RequireAuth>} />
          <Route path="/app/screening/:id/lesions" element={<RequireAuth><LesionOverlay /></RequireAuth>} />
          <Route path="/app/screening/:id/vessels" element={<RequireAuth><VesselMap /></RequireAuth>} />
          <Route path="/app/screening/:id/anatomy" element={<RequireAuth><AnatomicalLandmarksPage /></RequireAuth>} />
          <Route path="/app/screening/:id/gradcam" element={<RequireAuth><GradCamView /></RequireAuth>} />
          <Route path="/app/screening/:id/report" element={<RequireAuth><FullReport /></RequireAuth>} />

          <Route path="/operator/dashboard" element={<RequireAuth><OperatorDashboard /></RequireAuth>} />
          <Route path="/operator/patients" element={<RequireAuth><PatientsList area="operator" /></RequireAuth>} />
          <Route path="/operator/screenings" element={<RequireAuth><ScreeningsList area="operator" /></RequireAuth>} />
          <Route path="/operator/simulation" element={<RequireAuth><SimulinkSimulation /></RequireAuth>} />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </ScreeningsProvider>
    </AuthProvider>
  )
}
