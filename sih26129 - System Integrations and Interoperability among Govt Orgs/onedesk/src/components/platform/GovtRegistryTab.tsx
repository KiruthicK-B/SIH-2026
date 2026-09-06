import { Camera, Plus, ShieldCheck, UserCircle2, Users } from 'lucide-react'
import { motion } from 'motion/react'
import { type FormEvent, useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { StatCard } from '@/components/shared/StatCard'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Button } from '@/components/ui/Button'
import { Input, Label } from '@/components/ui/Input'
import { Modal } from '@/components/ui/Modal'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { useToast } from '@/components/ui/Toast'
import { api, ApiError } from '@/lib/api'
import { useAuthenticatedImage } from '@/lib/useAuthenticatedImage'

interface GovtRecord {
  aadhaarNumber: string
  name: string
  dateOfBirth: string
  gender: string
  address: string
  panNumber: string | null
  phoneNumber: string | null
  employmentStatus: string | null
  employerName: string | null
  designation: string | null
  highestQualification: string | null
  institutionName: string | null
  fatherName: string | null
  motherName: string | null
  parentPhoneNumber: string | null
  siblings: string | null
  occupation: string | null
  hasPhoto: boolean
  identityStatus: 'ACTIVE' | 'DECEASED'
}

const emptyForm = {
  aadhaarNumber: '',
  name: '',
  dateOfBirth: '',
  gender: 'Male',
  address: '',
  panNumber: '',
  phoneNumber: '',
  employmentStatus: '',
  employerName: '',
  designation: '',
  occupation: '',
  highestQualification: '',
  institutionName: '',
  fatherName: '',
  motherName: '',
  parentPhoneNumber: '',
  siblings: '',
}

export function GovtRegistryTab() {
  const { t } = useTranslation()
  const { showToast } = useToast()
  const [records, setRecords] = useState<GovtRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [addOpen, setAddOpen] = useState(false)
  const [viewRecord, setViewRecord] = useState<GovtRecord | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [submitting, setSubmitting] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)

  const refresh = () => {
    setLoading(true)
    api
      .get<GovtRecord[]>('/admin/govt-registry')
      .then(setRecords)
      .catch(() => setRecords([]))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    refresh()
  }, [])

  const withPhoto = records.filter((r) => r.hasPhoto).length

  const setField = (key: keyof typeof emptyForm) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
    setForm((f) => ({ ...f, [key]: e.target.value }))

  const handleAddPerson = async (e: FormEvent) => {
    e.preventDefault()
    setFormError(null)
    setSubmitting(true)
    try {
      await api.post('/admin/govt-registry', {
        ...form,
        panNumber: form.panNumber || null,
        phoneNumber: form.phoneNumber || null,
        employmentStatus: form.employmentStatus || null,
        employerName: form.employerName || null,
        designation: form.designation || null,
        occupation: form.occupation || null,
        highestQualification: form.highestQualification || null,
        institutionName: form.institutionName || null,
        fatherName: form.fatherName || null,
        motherName: form.motherName || null,
        parentPhoneNumber: form.parentPhoneNumber || null,
        siblings: form.siblings || null,
      })
      showToast(t('govtRegistryTab.recordAddedTitle'), t('govtRegistryTab.recordAddedDescription', { name: form.name }))
      setAddOpen(false)
      setForm(emptyForm)
      refresh()
    } catch (err) {
      setFormError(err instanceof ApiError ? err.message : t('govtRegistryTab.createFailed'))
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <p className="text-sm text-gray-500">{t('govtRegistryTab.intro')}</p>
        <Button size="sm" onClick={() => setAddOpen(true)}>
          <Plus className="h-3.5 w-3.5" /> {t('govtRegistryTab.addPerson')}
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard icon={Users} label={t('govtRegistryTab.statRecords')} value={records.length} tone="brand" />
        <StatCard icon={Camera} label={t('govtRegistryTab.statWithPhoto')} value={withPhoto} tone="success" />
        <StatCard icon={ShieldCheck} label={t('govtRegistryTab.statSource')} value={t('govtRegistryTab.sourceValue')} tone="consent" />
      </div>

      <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }}>
        <Table>
          <THead>
            <TR>
              <TH>{t('govtRegistryTab.colPhoto')}</TH>
              <TH>{t('govtRegistryTab.colName')}</TH>
              <TH>{t('govtRegistryTab.colAadhaar')}</TH>
              <TH>{t('govtRegistryTab.colDobGender')}</TH>
              <TH>{t('govtRegistryTab.colPan')}</TH>
              <TH>{t('govtRegistryTab.colEmployment')}</TH>
              <TH>{t('govtRegistryTab.colEducation')}</TH>
              <TH>{t('govtRegistryTab.colIdentityStatus')}</TH>
              <TH></TH>
            </TR>
          </THead>
          <TBody>
            {!loading &&
              records.map((r) => (
                <RegistryRow key={r.aadhaarNumber} record={r} onPhotoUploaded={refresh} onView={() => setViewRecord(r)} showToast={showToast} />
              ))}
          </TBody>
        </Table>
        {!loading && records.length === 0 && (
          <p className="py-8 text-center text-sm text-gray-400">{t('govtRegistryTab.noRecords')}</p>
        )}
      </motion.div>

      <Modal
        open={addOpen}
        onOpenChange={(open) => {
          setAddOpen(open)
          if (!open) setFormError(null)
        }}
        title={t('govtRegistryTab.modalAddTitle')}
        description={t('govtRegistryTab.modalAddDescription')}
        className="max-w-2xl"
      >
        <form onSubmit={handleAddPerson} className="max-h-[70vh] space-y-5 overflow-y-auto pr-1">
          <FormSection title={t('govtRegistryTab.sectionIdentity')}>
            <FormField
              label={t('govtRegistryTab.fieldAadhaarNumber')}
              value={form.aadhaarNumber}
              onChange={setField('aadhaarNumber')}
              placeholder={t('govtRegistryTab.fieldAadhaarPlaceholder')}
              required
              maxLength={12}
            />
            <FormField label={t('govtRegistryTab.fieldFullName')} value={form.name} onChange={setField('name')} required />
            <FormField label={t('govtRegistryTab.fieldDateOfBirth')} type="date" value={form.dateOfBirth} onChange={setField('dateOfBirth')} required />
            <div>
              <Label>{t('govtRegistryTab.fieldGender')}</Label>
              <select
                value={form.gender}
                onChange={setField('gender')}
                className="h-9 w-full rounded-md border border-gray-300 bg-white px-3 text-sm text-gray-900 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
              >
                <option value="Male">{t('govtRegistryTab.genderMale')}</option>
                <option value="Female">{t('govtRegistryTab.genderFemale')}</option>
                <option value="Other">{t('govtRegistryTab.genderOther')}</option>
              </select>
            </div>
            <FormField
              label={t('govtRegistryTab.fieldAddress')}
              value={form.address}
              onChange={setField('address')}
              required
              className="sm:col-span-2"
            />
          </FormSection>

          <FormSection title={t('govtRegistryTab.sectionContact')}>
            <FormField label={t('govtRegistryTab.fieldPanNumber')} value={form.panNumber} onChange={setField('panNumber')} placeholder="e.g. ABCDE1234F" />
            <FormField
              label={t('govtRegistryTab.fieldPhoneNumber')}
              value={form.phoneNumber}
              onChange={setField('phoneNumber')}
              placeholder={t('govtRegistryTab.fieldPhonePlaceholder')}
            />
          </FormSection>

          <FormSection title={t('govtRegistryTab.sectionEmployment')}>
            <FormField
              label={t('govtRegistryTab.fieldEmploymentStatus')}
              value={form.employmentStatus}
              onChange={setField('employmentStatus')}
              placeholder={t('govtRegistryTab.fieldEmploymentStatusPlaceholder')}
            />
            <FormField
              label={t('govtRegistryTab.fieldOccupation')}
              value={form.occupation}
              onChange={setField('occupation')}
              placeholder={t('govtRegistryTab.fieldOccupationPlaceholder')}
            />
            <FormField label={t('govtRegistryTab.fieldEmployer')} value={form.employerName} onChange={setField('employerName')} />
            <FormField label={t('govtRegistryTab.fieldDesignation')} value={form.designation} onChange={setField('designation')} />
            <FormField label={t('govtRegistryTab.fieldQualification')} value={form.highestQualification} onChange={setField('highestQualification')} />
            <FormField label={t('govtRegistryTab.fieldInstitution')} value={form.institutionName} onChange={setField('institutionName')} />
          </FormSection>

          <FormSection title={t('govtRegistryTab.sectionFamily')}>
            <FormField label={t('govtRegistryTab.fieldFatherName')} value={form.fatherName} onChange={setField('fatherName')} />
            <FormField label={t('govtRegistryTab.fieldMotherName')} value={form.motherName} onChange={setField('motherName')} />
            <FormField label={t('govtRegistryTab.fieldParentPhone')} value={form.parentPhoneNumber} onChange={setField('parentPhoneNumber')} />
            <FormField
              label={t('govtRegistryTab.fieldSiblings')}
              value={form.siblings}
              onChange={setField('siblings')}
              placeholder={t('govtRegistryTab.fieldSiblingsPlaceholder')}
            />
          </FormSection>

          {formError && <p className="rounded-md bg-danger-50 px-3 py-2 text-xs font-medium text-danger-700">{formError}</p>}

          <div className="flex gap-2 border-t border-gray-100 pt-4">
            <Button type="button" variant="outline" className="flex-1" onClick={() => setAddOpen(false)} disabled={submitting}>
              {t('govtRegistryTab.cancel')}
            </Button>
            <Button type="submit" className="flex-1" disabled={submitting}>
              {submitting ? t('govtRegistryTab.adding') : t('govtRegistryTab.addPerson')}
            </Button>
          </div>
        </form>
      </Modal>

      {viewRecord && (
        <Modal
          open
          onOpenChange={(open) => !open && setViewRecord(null)}
          title={viewRecord.name}
          description={t('govtRegistryTab.aadhaarPrefix', { number: viewRecord.aadhaarNumber })}
        >
          <div className="space-y-1.5 text-sm">
            <DetailRow label={t('govtRegistryTab.detailDob')} value={viewRecord.dateOfBirth} />
            <DetailRow label={t('govtRegistryTab.detailGender')} value={viewRecord.gender} />
            <DetailRow label={t('govtRegistryTab.detailAddress')} value={viewRecord.address} />
            <DetailRow label={t('govtRegistryTab.detailPan')} value={viewRecord.panNumber} />
            <DetailRow label={t('govtRegistryTab.detailPhone')} value={viewRecord.phoneNumber} />
            <DetailRow label={t('govtRegistryTab.detailEmploymentStatus')} value={viewRecord.employmentStatus} />
            <DetailRow label={t('govtRegistryTab.detailOccupation')} value={viewRecord.occupation} />
            <DetailRow label={t('govtRegistryTab.detailEmployer')} value={viewRecord.employerName} />
            <DetailRow label={t('govtRegistryTab.detailDesignation')} value={viewRecord.designation} />
            <DetailRow label={t('govtRegistryTab.detailQualification')} value={viewRecord.highestQualification} />
            <DetailRow label={t('govtRegistryTab.detailInstitution')} value={viewRecord.institutionName} />
            <DetailRow label={t('govtRegistryTab.detailFatherName')} value={viewRecord.fatherName} />
            <DetailRow label={t('govtRegistryTab.detailMotherName')} value={viewRecord.motherName} />
            <DetailRow label={t('govtRegistryTab.detailParentPhone')} value={viewRecord.parentPhoneNumber} />
            <DetailRow label={t('govtRegistryTab.detailSiblings')} value={viewRecord.siblings} />
          </div>
          <IdentityStatusControl
            record={viewRecord}
            onChanged={(status) => {
              setViewRecord((r) => (r ? { ...r, identityStatus: status } : r))
              refresh()
            }}
            showToast={showToast}
          />
        </Modal>
      )}
    </div>
  )
}

function FormSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">{title}</p>
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">{children}</div>
    </div>
  )
}

function FormField({
  label,
  value,
  onChange,
  placeholder,
  required,
  type = 'text',
  maxLength,
  className,
}: {
  label: string
  value: string
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void
  placeholder?: string
  required?: boolean
  type?: string
  maxLength?: number
  className?: string
}) {
  return (
    <div className={className}>
      <Label>
        {label}
        {required && <span className="text-danger-600"> *</span>}
      </Label>
      <Input type={type} value={value} onChange={onChange} placeholder={placeholder} maxLength={maxLength} required={required} />
    </div>
  )
}

// DEMO / MOCK GOVERNMENT DATA — mutates the simulated registry's identity_status,
// not a real UIDAI record. platform-admin only (enforced server-side); this control
// exists to demonstrate how OneDesk reacts when the authoritative source changes
// mid-workflow, not to imply a real government registry is writable this way.
function IdentityStatusControl({
  record,
  onChanged,
  showToast,
}: {
  record: GovtRecord
  onChanged: (status: 'ACTIVE' | 'DECEASED') => void
  showToast: (title: string, description?: string) => void
}) {
  const { t } = useTranslation()
  const [updating, setUpdating] = useState(false)
  const target = record.identityStatus === 'ACTIVE' ? 'DECEASED' : 'ACTIVE'
  const targetLabel = t(`status.${target}`, { defaultValue: target })

  const handleToggle = async () => {
    setUpdating(true)
    try {
      await api.post(`/admin/govt-registry/${record.aadhaarNumber}/identity-status`, { status: target })
      showToast(t('govtRegistryTab.statusUpdatedTitle'), t('govtRegistryTab.statusUpdatedDescription', { name: record.name, status: targetLabel }))
      onChanged(target)
    } catch (err) {
      showToast(t('govtRegistryTab.updateFailed'), err instanceof ApiError ? err.message : t('govtRegistryTab.genericError'))
    } finally {
      setUpdating(false)
    }
  }

  return (
    <div className="mt-4 flex items-center justify-between rounded-md border border-gray-100 bg-gray-50 px-3 py-2.5">
      <div>
        <p className="text-xs font-semibold uppercase tracking-wide text-gray-400">{t('govtRegistryTab.identityStatusDemo')}</p>
        <p className="mt-0.5 text-sm font-medium text-gray-900">
          {t('govtRegistryTab.currently')} <StatusBadge status={record.identityStatus} />
        </p>
      </div>
      <Button size="sm" variant="outline" onClick={handleToggle} disabled={updating}>
        {updating ? t('govtRegistryTab.updating') : t('govtRegistryTab.markStatus', { status: targetLabel })}
      </Button>
    </div>
  )
}

function DetailRow({ label, value }: { label: string; value: string | null }) {
  return (
    <div className="flex items-start justify-between gap-4 border-b border-gray-50 py-1">
      <span className="shrink-0 text-gray-400">{label}</span>
      <span className="text-right font-medium text-gray-900">{value ?? '—'}</span>
    </div>
  )
}

function RegistryRow({
  record,
  onPhotoUploaded,
  onView,
  showToast,
}: {
  record: GovtRecord
  onPhotoUploaded: () => void
  onView: () => void
  showToast: (title: string, description?: string) => void
}) {
  const { t } = useTranslation()
  const [uploading, setUploading] = useState(false)
  const fileInput = useRef<HTMLInputElement>(null)
  const photoUrl = useAuthenticatedImage(record.hasPhoto ? `/admin/govt-registry/${record.aadhaarNumber}/photo` : null)

  const handleFile = async (file: File) => {
    setUploading(true)
    try {
      await api.postFile(`/admin/govt-registry/${record.aadhaarNumber}/photo`, file)
      showToast(t('govtRegistryTab.photoUploadedTitle'), t('govtRegistryTab.photoUploadedDescription', { name: record.name }))
      onPhotoUploaded()
    } catch (err) {
      showToast(t('govtRegistryTab.uploadFailed'), err instanceof ApiError ? err.message : t('govtRegistryTab.genericError'))
    } finally {
      setUploading(false)
    }
  }

  return (
    <TR>
      <TD>
        <button
          onClick={() => fileInput.current?.click()}
          disabled={uploading}
          className="flex h-10 w-10 items-center justify-center overflow-hidden rounded-full border border-gray-200 bg-gray-50 text-gray-400 hover:border-brand-300 disabled:opacity-50"
          title={t('govtRegistryTab.uploadPhoto')}
        >
          {photoUrl ? <img src={photoUrl} alt="" className="h-full w-full object-cover" /> : <UserCircle2 className="h-6 w-6" />}
        </button>
        <input
          ref={fileInput}
          type="file"
          accept="image/*"
          className="hidden"
          onChange={(e) => {
            const file = e.target.files?.[0]
            if (file) handleFile(file)
            e.target.value = ''
          }}
        />
      </TD>
      <TD className="font-medium text-gray-900">{record.name}</TD>
      <TD className="font-mono text-xs text-gray-500">{record.aadhaarNumber}</TD>
      <TD className="text-gray-500">
        {record.dateOfBirth} · {record.gender}
      </TD>
      <TD className="font-mono text-xs text-gray-500">{record.panNumber ?? '—'}</TD>
      <TD className="text-gray-500">{record.employmentStatus ?? '—'}</TD>
      <TD className="text-gray-500">{record.highestQualification ?? '—'}</TD>
      <TD>
        <StatusBadge status={record.identityStatus} />
      </TD>
      <TD>
        <button type="button" onClick={onView} className="text-xs font-medium text-brand-600 hover:text-brand-700">
          {t('govtRegistryTab.view')}
        </button>
      </TD>
    </TR>
  )
}
