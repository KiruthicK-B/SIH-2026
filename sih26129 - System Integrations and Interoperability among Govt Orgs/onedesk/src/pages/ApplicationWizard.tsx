import { ArrowLeft, ArrowRight, Check, FileText, Link2, Loader2, ShieldCheck, Upload } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Navigate, useNavigate, useParams } from 'react-router-dom'
import { Button } from '@/components/ui/Button'
import { Card, CardContent } from '@/components/ui/Card'
import { Input, Label, Textarea } from '@/components/ui/Input'
import { useToast } from '@/components/ui/Toast'
import { useApplications } from '@/context/ApplicationsContext'
import { useAuth } from '@/context/AuthContext'
import { useIdentity } from '@/context/IdentityContext'
import { useServices } from '@/context/ServicesContext'
import { api } from '@/lib/api'
import { cn } from '@/lib/utils'

interface UploadedDoc {
  documentId: string
  fileName: string
}

interface FormState {
  fullName: string
  dob: string
  mobile: string
  address: string
  annualIncome: string
  educationDetails: string
}

export default function ApplicationWizard() {
  const { t } = useTranslation()
  const steps = [t('wizard.stepPersonalInfo'), t('wizard.stepEligibility'), t('wizard.stepDocuments'), t('wizard.stepConsent'), t('wizard.stepReview')]
  const { id } = useParams<{ id: string }>()
  const { getServiceById } = useServices()
  const service = id ? getServiceById(id) : undefined
  const navigate = useNavigate()
  const { submitApplication } = useApplications()
  const { showToast } = useToast()
  const { name } = useAuth()
  const { identity } = useIdentity()

  const [step, setStep] = useState(0)
  const [consentGiven, setConsentGiven] = useState(false)
  const [uploads, setUploads] = useState<Record<string, UploadedDoc>>({})
  const [uploadingDoc, setUploadingDoc] = useState<string | null>(null)
  const [form, setForm] = useState<FormState>({
    fullName: name ?? '',
    dob: '',
    mobile: '',
    address: '',
    annualIncome: '',
    educationDetails: '',
  })

  useEffect(() => {
    if (!identity) return
    setForm((prev) => ({
      ...prev,
      fullName: prev.fullName || identity.citizenName,
      dob: prev.dob || identity.dateOfBirth || '',
      mobile: prev.mobile || identity.phoneNumber || '',
      address: prev.address || identity.address || '',
      annualIncome: prev.annualIncome || identity.annualIncome || '',
      educationDetails: prev.educationDetails || identity.educationDetails || '',
    }))
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [identity])

  if (!service) {
    return <Navigate to="/services" replace />
  }

  const updateField = (key: keyof FormState, value: string) => {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  const handleFileSelect = async (doc: string, file: File) => {
    setUploadingDoc(doc)
    try {
      const { id } = await api.postFile<{ id: string }>('/documents/upload', file)
      setUploads((prev) => ({ ...prev, [doc]: { documentId: id, fileName: file.name } }))
    } catch {
      showToast(t('wizard.uploadFailedTitle'), t('wizard.uploadFailedDescription', { doc }))
    } finally {
      setUploadingDoc(null)
    }
  }

  const allDocsUploaded = service.requiredDocuments.every((doc) => uploads[doc])

  const canProceed = () => {
    if (step === 2) return allDocsUploaded
    if (step === 3) return consentGiven
    return true
  }

  const handleNext = () => setStep((s) => Math.min(s + 1, steps.length - 1))
  const handleBack = () => setStep((s) => Math.max(s - 1, 0))

  const handleSubmit = async () => {
    const newApp = await submitApplication({
      service: service.name,
      department: service.department,
      citizenName: form.fullName,
      description: service.description,
      documentIds: Object.values(uploads).map((u) => u.documentId),
    })
    showToast(t('wizard.submittedToastTitle'), t('wizard.submittedToastDescription', { id: newApp.id }))
    navigate(`/applications/${newApp.id}`)
  }

  return (
    <div className="mx-auto max-w-3xl">
      <button
        onClick={() => navigate(`/services/${service.id}`)}
        className="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-700"
      >
        <ArrowLeft className="h-4 w-4" /> {t('wizard.backToService')}
      </button>

      <h1 className="text-xl font-semibold text-gray-900">{t('wizard.applyForService', { service: service.name })}</h1>
      <p className="mt-1 text-sm text-gray-500">{service.department}</p>

      <ol className="my-6 flex items-center gap-2">
        {steps.map((label, idx) => (
          <li key={label} className="flex flex-1 items-center gap-2">
            <div className="flex items-center gap-2">
              <span
                className={cn(
                  'flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-semibold',
                  idx < step && 'bg-success-600 text-white',
                  idx === step && 'bg-brand-600 text-white',
                  idx > step && 'bg-gray-100 text-gray-400',
                )}
              >
                {idx < step ? <Check className="h-3.5 w-3.5" /> : idx + 1}
              </span>
              <span className={cn('hidden text-xs font-medium sm:inline', idx === step ? 'text-gray-900' : 'text-gray-400')}>
                {label}
              </span>
            </div>
            {idx < steps.length - 1 && <span className="h-px flex-1 bg-gray-200" />}
          </li>
        ))}
      </ol>

      <Card>
        <CardContent className="pt-5">
          {step === 0 && (
            <div className="space-y-4">
              <PrefillNotice text={t('wizard.prefillPersonal')} />
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <Label htmlFor="fullName">{t('wizard.fullName')}</Label>
                  <Input id="fullName" value={form.fullName} onChange={(e) => updateField('fullName', e.target.value)} />
                </div>
                <div>
                  <Label htmlFor="dob">{t('wizard.dateOfBirth')}</Label>
                  <Input id="dob" type="date" value={form.dob} onChange={(e) => updateField('dob', e.target.value)} />
                </div>
                <div>
                  <Label htmlFor="mobile">{t('wizard.mobileNumber')}</Label>
                  <Input id="mobile" value={form.mobile} onChange={(e) => updateField('mobile', e.target.value)} />
                </div>
                <div className="sm:col-span-2">
                  <Label htmlFor="address">{t('wizard.address')}</Label>
                  <Textarea id="address" rows={2} value={form.address} onChange={(e) => updateField('address', e.target.value)} />
                </div>
              </div>
            </div>
          )}

          {step === 1 && (
            <div className="space-y-4">
              <PrefillNotice text={t('wizard.prefillEligibility')} />
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <Label htmlFor="income">{t('wizard.annualIncome')}</Label>
                  <Input id="income" value={form.annualIncome} onChange={(e) => updateField('annualIncome', e.target.value)} />
                  <p className="mt-1 text-xs text-gray-400">{t('wizard.annualIncomeSource')}</p>
                </div>
                <div>
                  <Label htmlFor="education">{t('wizard.educationDetails')}</Label>
                  <Input id="education" value={form.educationDetails} onChange={(e) => updateField('educationDetails', e.target.value)} />
                  <p className="mt-1 text-xs text-gray-400">{t('wizard.educationDetailsSource')}</p>
                </div>
              </div>
              <div className="rounded-md border border-success-600/20 bg-success-50 p-3 text-sm text-success-700">
                {t('wizard.eligibilityMet')}
              </div>
            </div>
          )}

          {step === 2 && (
            <div className="space-y-3">
              <p className="text-sm text-gray-500">{t('wizard.attachEachDocument')}</p>
              {service.requiredDocuments.map((doc) => {
                const uploaded = uploads[doc]
                const uploading = uploadingDoc === doc
                const inputId = `upload-${doc.replace(/\s+/g, '-')}`
                return (
                  <label
                    key={doc}
                    htmlFor={inputId}
                    className={cn(
                      'flex w-full cursor-pointer items-center justify-between rounded-md border px-4 py-3 text-left text-sm transition-colors',
                      uploaded ? 'border-success-600/30 bg-success-50 text-success-700' : 'border-gray-200 text-gray-700 hover:bg-gray-50',
                      uploading && 'pointer-events-none opacity-70',
                    )}
                  >
                    <span className="flex min-w-0 items-center gap-2">
                      <FileText className="h-4 w-4 shrink-0" />
                      <span className="min-w-0">
                        <span className="block">{doc}</span>
                        {uploaded && <span className="block truncate text-xs text-success-700/80">{uploaded.fileName}</span>}
                      </span>
                    </span>
                    <input
                      id={inputId}
                      type="file"
                      className="hidden"
                      onChange={(e) => {
                        const file = e.target.files?.[0]
                        if (file) void handleFileSelect(doc, file)
                      }}
                    />
                    {uploading ? (
                      <Loader2 className="h-4 w-4 shrink-0 animate-spin text-gray-400" />
                    ) : uploaded ? (
                      <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full border border-success-600 bg-success-600 text-white">
                        <Check className="h-3 w-3" />
                      </span>
                    ) : (
                      <Upload className="h-4 w-4 shrink-0 text-gray-400" />
                    )}
                  </label>
                )
              })}
            </div>
          )}

          {step === 3 && (
            <div className="space-y-4">
              <div className="flex items-start gap-3 rounded-md border border-consent-600/20 bg-consent-50 p-4">
                <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0 text-consent-600" />
                <div>
                  <p className="text-sm font-semibold text-consent-700">{t('wizard.consentRequiredTitle')}</p>
                  <p className="mt-1 text-sm text-consent-700/90">
                    {t('wizard.consentRequiredDescription', { department: service.department, service: service.name })}
                  </p>
                </div>
              </div>
              <div className="flex gap-3">
                <Button variant={consentGiven ? 'primary' : 'outline'} onClick={() => setConsentGiven(true)}>
                  {t('wizard.allow')}
                </Button>
                <Button variant="outline" onClick={() => setConsentGiven(false)}>
                  {t('wizard.deny')}
                </Button>
              </div>
              {consentGiven && (
                <p className="flex items-center gap-1.5 text-sm font-medium text-success-600">
                  <Check className="h-4 w-4" /> {t('wizard.consentGranted')}
                </p>
              )}
            </div>
          )}

          {step === 4 && (
            <div className="space-y-4">
              <p className="text-sm text-gray-500">{t('wizard.reviewIntro')}</p>
              <div className="grid grid-cols-1 gap-3 rounded-md border border-gray-200 p-4 sm:grid-cols-2">
                <ReviewRow label={t('wizard.fullName')} value={form.fullName} />
                <ReviewRow label={t('wizard.dateOfBirth')} value={form.dob} />
                <ReviewRow label={t('wizard.mobileNumber')} value={form.mobile} />
                <ReviewRow label={t('wizard.annualIncome')} value={form.annualIncome} />
                <ReviewRow label={t('wizard.educationDetails')} value={form.educationDetails} />
                <ReviewRow label={t('wizard.address')} value={form.address} />
              </div>
              <div className="rounded-md border border-gray-200 p-4">
                <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">{t('wizard.documentsTitle')}</p>
                <p className="text-sm text-gray-700">
                  {t('wizard.documentsAttachedCount', { count: Object.keys(uploads).length, total: service.requiredDocuments.length })}
                </p>
                <div className="mt-1.5 space-y-0.5">
                  {Object.entries(uploads).map(([doc, u]) => (
                    <p key={doc} className="text-xs text-gray-500">
                      {doc}: <span className="text-gray-700">{u.fileName}</span>
                    </p>
                  ))}
                </div>
              </div>
              <div className="rounded-md border border-gray-200 p-4">
                <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">{t('wizard.consentTitle')}</p>
                <p className="text-sm text-success-700">{t('wizard.consentGrantedTo', { department: service.department })}</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <div className="mt-5 flex items-center justify-between">
        <Button variant="outline" onClick={handleBack} disabled={step === 0}>
          {t('wizard.back')}
        </Button>
        {step < steps.length - 1 ? (
          <Button onClick={handleNext} disabled={!canProceed()}>
            {t('wizard.next')} <ArrowRight className="h-4 w-4" />
          </Button>
        ) : (
          <Button onClick={handleSubmit}>{t('wizard.submitApplication')}</Button>
        )}
      </div>
    </div>
  )
}

function PrefillNotice({ text }: { text: string }) {
  return (
    <div className="flex items-center gap-2 rounded-md bg-brand-50 px-3 py-2 text-xs font-medium text-brand-700">
      <Link2 className="h-3.5 w-3.5" /> {text}
    </div>
  )
}

function ReviewRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-gray-400">{label}</p>
      <p className="text-sm font-medium text-gray-900">{value}</p>
    </div>
  )
}
