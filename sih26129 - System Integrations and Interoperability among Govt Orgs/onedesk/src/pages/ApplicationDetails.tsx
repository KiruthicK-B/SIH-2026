import { ArrowLeft, ArrowRight, Building2, Calendar, FileText, Network } from 'lucide-react'
import { Link, Navigate, useParams } from 'react-router-dom'
import { ApplicationTimeline } from '@/components/applications/ApplicationTimeline'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { useToast } from '@/components/ui/Toast'
import { useApplications } from '@/context/ApplicationsContext'
import { useNotifications } from '@/context/NotificationsContext'
import { useRole } from '@/context/RoleContext'
import { masterIdentity } from '@/data/identity'
import { formatDate } from '@/lib/utils'

export default function ApplicationDetails() {
  const { id } = useParams<{ id: string }>()
  const { getApplicationById, advanceApplication } = useApplications()
  const { addNotification } = useNotifications()
  const { showToast } = useToast()
  const { role, isPlatformRole } = useRole()
  const application = id ? getApplicationById(id) : undefined

  if (!application) {
    return <Navigate to="/applications" replace />
  }

  const hasNextStep = application.timeline.some((s) => s.status === 'active' || s.status === 'blocked')

  const handleAdvance = () => {
    if (!id) return
    const event = advanceApplication(id)
    if (!event) return
    showToast(event.title, event.description)
    addNotification({ type: 'application', title: event.title, description: event.description })
  }

  return (
    <div>
      <Link to="/applications" className="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-700">
        <ArrowLeft className="h-4 w-4" /> Back to applications
      </Link>

      {application.flagship && (
        <div className="mb-4 flex items-center gap-2 rounded-md border border-brand-500/20 bg-brand-50 px-3 py-2 text-xs font-medium text-brand-700">
          <Network className="h-3.5 w-3.5" /> One application. Multiple departments working behind the scenes. One
          status.
        </div>
      )}

      <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-xl font-semibold text-gray-900">{application.service}</h1>
          <p className="mt-1 text-sm text-gray-500">{application.description}</p>
        </div>
        <StatusBadge status={application.status} />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle>Application Timeline</CardTitle>
            </CardHeader>
            <CardContent>
              <ApplicationTimeline steps={application.timeline} />
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Application Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <DetailRow icon={FileText} label="Application ID" value={application.id} />
              <DetailRow icon={Building2} label="Department" value={application.department} />
              <DetailRow icon={Calendar} label="Submitted On" value={formatDate(application.submittedOn)} />
              <DetailRow icon={Calendar} label="Last Updated" value={formatDate(application.lastUpdated)} />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Applicant</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm font-medium text-gray-900">{application.citizenName}</p>
              <p className="text-xs text-gray-500">OneDesk ID: {masterIdentity.masterId}</p>
            </CardContent>
          </Card>

          {isPlatformRole && (
            <Card className="border-teal-600/20 bg-teal-50/40">
              <CardHeader>
                <CardTitle>Officer Actions</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="mb-3 text-xs text-gray-500">
                  Signed in as {role}. Process the next step in this cross-department workflow.
                </p>
                <Button onClick={handleAdvance} disabled={!hasNextStep} className="w-full">
                  {hasNextStep ? (
                    <>
                      Process Next Step <ArrowRight className="h-4 w-4" />
                    </>
                  ) : (
                    'Workflow complete'
                  )}
                </Button>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}

function DetailRow({ icon: Icon, label, value }: { icon: typeof FileText; label: string; value: string }) {
  return (
    <div className="flex items-start gap-3">
      <div className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-gray-100 text-gray-500">
        <Icon className="h-4 w-4" />
      </div>
      <div>
        <p className="text-xs text-gray-500">{label}</p>
        <p className="text-sm font-medium text-gray-900">{value}</p>
      </div>
    </div>
  )
}
