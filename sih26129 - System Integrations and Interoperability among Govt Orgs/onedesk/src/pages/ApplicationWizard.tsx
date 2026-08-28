import { ArrowLeft, ArrowRight, Check, Link2, ShieldCheck } from 'lucide-react'
import { useState } from 'react'
import { Navigate, useNavigate, useParams } from 'react-router-dom'
import { Button } from '@/components/ui/Button'
import { Card, CardContent } from '@/components/ui/Card'
import { Input, Label, Textarea } from '@/components/ui/Input'
import { useToast } from '@/components/ui/Toast'
import { useApplications } from '@/context/ApplicationsContext'
import { getServiceById } from '@/data/services'
import { cn } from '@/lib/utils'

const steps = ['Personal Information', 'Eligibility', 'Documents', 'Consent', 'Review']

interface FormState {
  fullName: string
  dob: string
  mobile: string
  address: string
  annualIncome: string
  educationDetails: string
}

export default function ApplicationWizard() {
  const { id } = useParams<{ id: string }>()
  const service = id ? getServiceById(id) : undefined
  const navigate = useNavigate()
  const { submitApplication } = useApplications()
  const { showToast } = useToast()

  const [step, setStep] = useState(0)
  const [consentGiven, setConsentGiven] = useState(false)
  const [uploaded, setUploaded] = useState<Record<string, boolean>>({})
  const [form, setForm] = useState<FormState>({
    fullName: 'Kiruthick B',
    dob: '1999-04-12',
    mobile: '+91 98765 43210',
    address: '221, Shivaji Nagar, Pune, Maharashtra – 411005',
    annualIncome: '₹2,40,000',
    educationDetails: 'B.Sc. Computer Science, Savitribai Phule Pune University (2024)',
  })

  if (!service) {
    return <Navigate to="/services" replace />
  }

  const updateField = (key: keyof FormState, value: string) => {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  const toggleUpload = (doc: string) => {
    setUploaded((prev) => ({ ...prev, [doc]: !prev[doc] }))
  }

  const allDocsUploaded = service.requiredDocuments.every((doc) => uploaded[doc])

  const canProceed = () => {
    if (step === 2) return allDocsUploaded
    if (step === 3) return consentGiven
    return true
  }

  const handleNext = () => setStep((s) => Math.min(s + 1, steps.length - 1))
  const handleBack = () => setStep((s) => Math.max(s - 1, 0))

  const handleSubmit = () => {
    const newApp = submitApplication({
      service: service.name,
      department: service.department,
      citizenName: form.fullName,
      description: service.description,
    })
    showToast('Application submitted successfully', `Application ID: ${newApp.id}`)
    navigate(`/applications/${newApp.id}`)
  }

  return (
    <div className="mx-auto max-w-3xl">
      <button
        onClick={() => navigate(`/services/${service.id}`)}
        className="mb-4 inline-flex items-center gap-1.5 text-sm font-medium text-gray-500 hover:text-gray-700"
      >
        <ArrowLeft className="h-4 w-4" /> Back to service
      </button>

      <h1 className="text-xl font-semibold text-gray-900">Apply for {service.name}</h1>
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
              <PrefillNotice text="Personal details pre-filled from your OneDesk profile — no need to re-enter." />
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <Label htmlFor="fullName">Full Name</Label>
                  <Input id="fullName" value={form.fullName} onChange={(e) => updateField('fullName', e.target.value)} />
                </div>
                <div>
                  <Label htmlFor="dob">Date of Birth</Label>
                  <Input id="dob" type="date" value={form.dob} onChange={(e) => updateField('dob', e.target.value)} />
                </div>
                <div>
                  <Label htmlFor="mobile">Mobile Number</Label>
                  <Input id="mobile" value={form.mobile} onChange={(e) => updateField('mobile', e.target.value)} />
                </div>
                <div className="sm:col-span-2">
                  <Label htmlFor="address">Address</Label>
                  <Textarea id="address" rows={2} value={form.address} onChange={(e) => updateField('address', e.target.value)} />
                </div>
              </div>
            </div>
          )}

          {step === 1 && (
            <div className="space-y-4">
              <PrefillNotice text="Income and education details fetched from Revenue and Education Department records." />
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <div>
                  <Label htmlFor="income">Annual Income</Label>
                  <Input id="income" value={form.annualIncome} onChange={(e) => updateField('annualIncome', e.target.value)} />
                  <p className="mt-1 text-xs text-gray-400">Source: Revenue Department — Income Certificate</p>
                </div>
                <div>
                  <Label htmlFor="education">Education Details</Label>
                  <Input id="education" value={form.educationDetails} onChange={(e) => updateField('educationDetails', e.target.value)} />
                  <p className="mt-1 text-xs text-gray-400">Source: Education Department — Academic Records</p>
                </div>
              </div>
              <div className="rounded-md border border-success-600/20 bg-success-50 p-3 text-sm text-success-700">
                Eligibility criteria met based on available records.
              </div>
            </div>
          )}

          {step === 2 && (
            <div className="space-y-3">
              <p className="text-sm text-gray-500">Mark each required document as attached to continue.</p>
              {service.requiredDocuments.map((doc) => (
                <button
                  key={doc}
                  onClick={() => toggleUpload(doc)}
                  className={cn(
                    'flex w-full items-center justify-between rounded-md border px-4 py-3 text-left text-sm transition-colors',
                    uploaded[doc] ? 'border-success-600/30 bg-success-50 text-success-700' : 'border-gray-200 text-gray-700 hover:bg-gray-50',
                  )}
                >
                  {doc}
                  <span
                    className={cn(
                      'flex h-5 w-5 items-center justify-center rounded-full border text-[10px] font-semibold',
                      uploaded[doc] ? 'border-success-600 bg-success-600 text-white' : 'border-gray-300 text-transparent',
                    )}
                  >
                    <Check className="h-3 w-3" />
                  </span>
                </button>
              ))}
            </div>
          )}

          {step === 3 && (
            <div className="space-y-4">
              <div className="flex items-start gap-3 rounded-md border border-consent-600/20 bg-consent-50 p-4">
                <ShieldCheck className="mt-0.5 h-5 w-5 shrink-0 text-consent-600" />
                <div>
                  <p className="text-sm font-semibold text-consent-700">Data sharing consent required</p>
                  <p className="mt-1 text-sm text-consent-700/90">
                    {service.department} is requesting access to records already verified by other connected
                    departments to process {service.name} — instead of asking you to submit them again. This
                    access is purpose-bound and time-limited.
                  </p>
                </div>
              </div>
              <div className="flex gap-3">
                <Button variant={consentGiven ? 'primary' : 'outline'} onClick={() => setConsentGiven(true)}>
                  Allow
                </Button>
                <Button variant="outline" onClick={() => setConsentGiven(false)}>
                  Deny
                </Button>
              </div>
              {consentGiven && (
                <p className="flex items-center gap-1.5 text-sm font-medium text-success-600">
                  <Check className="h-4 w-4" /> Consent granted — you may proceed.
                </p>
              )}
            </div>
          )}

          {step === 4 && (
            <div className="space-y-4">
              <p className="text-sm text-gray-500">Review your application before submitting.</p>
              <div className="grid grid-cols-1 gap-3 rounded-md border border-gray-200 p-4 sm:grid-cols-2">
                <ReviewRow label="Full Name" value={form.fullName} />
                <ReviewRow label="Date of Birth" value={form.dob} />
                <ReviewRow label="Mobile Number" value={form.mobile} />
                <ReviewRow label="Annual Income" value={form.annualIncome} />
                <ReviewRow label="Education Details" value={form.educationDetails} />
                <ReviewRow label="Address" value={form.address} />
              </div>
              <div className="rounded-md border border-gray-200 p-4">
                <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">Documents</p>
                <p className="text-sm text-gray-700">{service.requiredDocuments.length} of {service.requiredDocuments.length} attached</p>
              </div>
              <div className="rounded-md border border-gray-200 p-4">
                <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">Consent</p>
                <p className="text-sm text-success-700">Granted to {service.department}</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <div className="mt-5 flex items-center justify-between">
        <Button variant="outline" onClick={handleBack} disabled={step === 0}>
          Back
        </Button>
        {step < steps.length - 1 ? (
          <Button onClick={handleNext} disabled={!canProceed()}>
            Next <ArrowRight className="h-4 w-4" />
          </Button>
        ) : (
          <Button onClick={handleSubmit}>Submit Application</Button>
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
