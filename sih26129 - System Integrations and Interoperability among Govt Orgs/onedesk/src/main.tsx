import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import App from './App.tsx'
import { ToastProvider } from '@/components/ui/Toast'
import { ApplicationsProvider } from '@/context/ApplicationsContext'
import { AuthProvider } from '@/context/AuthContext'
import { ConsentsProvider } from '@/context/ConsentsContext'
import { DepartmentsProvider } from '@/context/DepartmentsContext'
import { IdentityProvider } from '@/context/IdentityContext'
import { NotificationsProvider } from '@/context/NotificationsContext'
import { RoleProvider } from '@/context/RoleContext'
import { SearchProvider } from '@/context/SearchContext'
import { ServicesProvider } from '@/context/ServicesContext'
import './i18n/config'
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <AuthProvider>
        <RoleProvider>
          <ToastProvider>
            <NotificationsProvider>
              <IdentityProvider>
                <DepartmentsProvider>
                  <ServicesProvider>
                    <ConsentsProvider>
                      <ApplicationsProvider>
                        <SearchProvider>
                          <App />
                        </SearchProvider>
                      </ApplicationsProvider>
                    </ConsentsProvider>
                  </ServicesProvider>
                </DepartmentsProvider>
              </IdentityProvider>
            </NotificationsProvider>
          </ToastProvider>
        </RoleProvider>
      </AuthProvider>
    </BrowserRouter>
  </StrictMode>,
)
