import { ArrowLeft, ArrowRight, Award, Building2, Calendar, FileText, Network, ShieldCheck } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, Navigate, useParams } from 'react-router-dom'
import { ApplicationTimeline } from '@/components/applications/ApplicationTimeline'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { useToast } from '@/components/ui/Toast'
import { useApplications } from '@/context/ApplicationsContext'
import { useAuth } from '@/context/AuthContext'
import { useConsents } from '@/context/ConsentsContext'
import { useNotifications } from '@/context/NotificationsContext'
import { useRole } from '@/context/RoleContext'
import type { CitizenDocument } from '@/data/documents'
import { api, ApiError } from '@/lib/api'
import { formatDate } from '@/lib/utils'

export default function ApplicationDetails() {
  const { t } = useTranslation()
  const { id } = useParams<{ id: string }>()
  const { getApplicationById, advanceApplication, approveMunicipalReview } = useApplications()
  const { pendingRequests, allowRequest, refresh: refreshConsents } = useConsents()
  const { refresh: refreshNotifications } = useNotifications()
  const { showToast } = useToast()
  const { role, department, isPlatformRole } = useRole()
  const { masterId } = useAuth()
  const [grantingId, setGrantingId] = useState<string | null>(null)
  const [certificate, setCertificate] = useState<CitizenDocument | null>(null)
  const application = id ? getApplicationById(id) : undefined
  const roleLabel = t(`roles.${role}`, { defaultValue: role })

  // ConsentsProvider only fetches pending requests once at login — a step that
  // blocks on consent *after* that (as this one does, mid-workflow) never shows up
  // until something re-fetches. Do that here so the inline grant button isn't stuck
  // showing "loading" forever.
  const isConsentBlocked = application?.timeline.some((s) => s.status === 'blocked' && s.blockedReasonCode === 'consent_revoked') ?? false
  useEffect(() => {
    if (isConsentBlocked) void refreshConsents()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isConsentBlocked, application?.id])

  // The certificate a Completed application actually produced — issued server-side
  // by DocumentsService.issueDocument once the last step finishes, not a prop.
  const isCompleted = application?.status === 'Completed'
  useEffect(() => {
    if (!isCompleted || !application) return
    api.get<CitizenDocument[]>('/documents').then((docs) => {
      setCertificate(docs.find((d) => d.applicationId === application.id) ?? null)
    })
  }, [isCompleted, application])

  if (!application) {
    return <Navigate to="/applications" replace />
  }

  const hasNextStep = application.timeline.some((s) => s.status === 'active' || s.status === 'blocked')
  const activeStep = application.timeline.find((s) => s.status === 'active')
  const municipalReviewPending = application.flagship && activeStep?.department === 'Municipal Corporation'
  // Flagship steps other than Municipal Review are driven automatically by
  // WorkflowService — no manual "advance" for those; the generic action below is
  // only for non-flagship services that have no real connector behind them.
  const canManuallyAdvance = !application.flagship && hasNextStep
  const officerDepartmentMatches = role === 'Platform Administrator' || department === 'Municipal Corporation'

  // Inline consent grant right on the blocked step — no detour through My Consents.
  // Matched by department against this citizen's own pending requests (the backend
  // auto-creates one the moment a step blocks on a missing/revoked consent).
  const consentBlockedStep = application.timeline.find((s) => s.status === 'blocked' && s.blockedReasonCode === 'consent_revoked')
  const matchingRequest = consentBlockedStep
    ? pendingRequests.find((r) => r.department === consentBlockedStep.department)
    : undefined

  const handleAdvance = async () => {
    if (!id) return
    const event = await advanceApplication(id)
    if (!event) return
    showToast(event.title, event.description)
    void refreshNotifications()
  }

  const handleGrantConsent = async () => {
    if (!matchingRequest) return
    setGrantingId(matchingRequest.id)
    try {
      await allowRequest(matchingRequest.id)
      showToast(
        t('consents.grantedToastTitle'),
        t('consents.grantedToastDescription', { department: matchingRequest.department, data: matchingRequest.dataRequested.join(', ') }),
      )
      void refreshNotifications()
    } catch (err) {
      showToast(t('consents.grantFailedTitle'), err instanceof ApiError ? err.message : t('consents.genericError'))
    } finally {
      setGrantingId(null)
    }
  }

  const handleApproveMunicipalReview = async () => {
    if (!id) return
    try {
      const event = await approveMunicipalReview(id)
      showToast(event.title, event.description)
      void refreshNotifications()
    } catch {
      showToast(t('applicationDetails.approvalFailedTitle'), t('applicationDetails.approvalFailedDescription'))
    }
  }

  return (
    <div>
      <Link to="/applications" className="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-700">
        <ArrowLeft className="h-4 w-4" /> {t('applicationDetails.backToApplications')}
      </Link>

      {application.flagship && (
        <div className="mb-4 flex items-center gap-2 rounded-md border border-brand-500/20 bg-brand-50 px-3 py-2 text-xs font-medium text-brand-700">
          <Network className="h-3.5 w-3.5" /> {t('applicationDetails.flagshipBanner')}
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
              <CardTitle>{t('applicationDetails.timelineTitle')}</CardTitle>
            </CardHeader>
            <CardContent>
              <ApplicationTimeline steps={application.timeline} />
            </CardContent>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>{t('applicationDetails.detailsTitle')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <DetailRow icon={FileText} label={t('applicationDetails.applicationId')} value={application.id} />
              <DetailRow icon={Building2} label={t('applicationDetails.department')} value={application.department} />
              <DetailRow icon={Calendar} label={t('applicationDetails.submittedOn')} value={formatDate(application.submittedOn)} />
              <DetailRow icon={Calendar} label={t('applicationDetails.lastUpdated')} value={formatDate(application.lastUpdated)} />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>{t('applicationDetails.applicantTitle')}</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm font-medium text-gray-900">{application.citizenName}</p>
              <p className="text-xs text-gray-500">{t('applicationDetails.oneDeskId', { id: masterId ?? '—' })}</p>
            </CardContent>
          </Card>

          {isCompleted && certificate && (
            <Card className="border-success-600/30 bg-success-50/40">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Award className="h-4 w-4 text-success-600" /> {t('applicationDetails.certificateIssuedTitle')}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="mb-3 flex items-start justify-between gap-2">
                  <p className="text-sm font-medium text-gray-900">{certificate.name}</p>
                  <StatusBadge status={certificate.status} />
                </div>
                <p className="mb-3 text-xs text-gray-500">
                  {t('applicationDetails.certificateIssuedHint', { date: formatDate(certificate.issuedOn) })}
                </p>
                <Link
                  to="/documents"
                  className="flex w-full items-center justify-center gap-1.5 rounded-md border border-success-600/30 bg-white px-3 py-2 text-sm font-medium text-success-700 hover:bg-success-50"
                >
                  {t('applicationDetails.viewInDocuments')} <ArrowRight className="h-4 w-4" />
                </Link>
              </CardContent>
            </Card>
          )}

          {consentBlockedStep && (
            <Card className="border-consent-600/30 bg-consent-50/40">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <ShieldCheck className="h-4 w-4 text-consent-600" /> {t('applicationDetails.consentRequiredTitle')}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <p className="mb-3 text-xs text-gray-500">
                  {matchingRequest
                    ? t('applicationDetails.consentRequiredHint', {
                        department: consentBlockedStep.department,
                        data: matchingRequest.dataRequested.join(', '),
                      })
                    : t('applicationDetails.consentRequiredWaiting', { department: consentBlockedStep.department })}
                </p>
                <Button
                  onClick={handleGrantConsent}
                  disabled={!matchingRequest || grantingId === matchingRequest?.id}
                  className="w-full"
                >
                  {t('applicationDetails.grantConsentResume')} <ArrowRight className="h-4 w-4" />
                </Button>
              </CardContent>
            </Card>
          )}

          {isPlatformRole && municipalReviewPending && (
            <Card className="border-teal-600/20 bg-teal-50/40">
              <CardHeader>
                <CardTitle>{t('applicationDetails.officerActions')}</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="mb-3 text-xs text-gray-500">
                  {officerDepartmentMatches
                    ? t('applicationDetails.municipalReviewOwn', { role: roleLabel })
                    : t('applicationDetails.municipalReviewOther', {
                        role: roleLabel,
                        department: department ?? t('applicationDetails.unassigned'),
                      })}
                </p>
                <Button onClick={handleApproveMunicipalReview} disabled={!officerDepartmentMatches} className="w-full">
                  {t('applicationDetails.approveMunicipalReview')} <ArrowRight className="h-4 w-4" />
                </Button>
              </CardContent>
            </Card>
          )}

          {isPlatformRole && canManuallyAdvance && (
            <Card className="border-teal-600/20 bg-teal-50/40">
              <CardHeader>
                <CardTitle>{t('applicationDetails.officerActions')}</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="mb-3 text-xs text-gray-500">{t('applicationDetails.advanceHint', { role: roleLabel })}</p>
                <Button onClick={handleAdvance} className="w-full">
                  {t('applicationDetails.processNextStep')} <ArrowRight className="h-4 w-4" />
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
