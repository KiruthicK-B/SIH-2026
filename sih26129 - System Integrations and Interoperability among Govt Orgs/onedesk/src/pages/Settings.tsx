import { CheckCircle2 } from 'lucide-react'
import { useState } from 'react'
import { PageHeader } from '@/components/shared/PageHeader'
import { Button } from '@/components/ui/Button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { Input, Label } from '@/components/ui/Input'
import { useToast } from '@/components/ui/Toast'
import { connectedServices, masterIdentity } from '@/data/identity'

export default function Settings() {
  const { showToast } = useToast()
  const [notifyEmail, setNotifyEmail] = useState(true)
  const [notifySms, setNotifySms] = useState(true)

  return (
    <div>
      <PageHeader title="Settings" subtitle="Manage your profile, identity, and notification preferences." />

      <div className="mb-6">
        <Card>
          <CardHeader>
            <CardTitle>OneDesk Identity</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="mb-4 text-sm text-gray-500">
              One identity, federated across every connected department — you don't need separate logins for
              each service.
            </p>
            <div className="flex flex-wrap items-center gap-4">
              <div className="rounded-md border border-consent-600/30 bg-consent-50 px-4 py-3">
                <p className="text-xs font-semibold uppercase tracking-wide text-consent-700">OneDesk ID</p>
                <p className="mt-0.5 font-mono text-lg font-semibold text-consent-700">{masterIdentity.masterId}</p>
              </div>
              <div className="flex flex-1 flex-wrap gap-2">
                {connectedServices.map((s) => (
                  <span
                    key={s.department}
                    className="flex items-center gap-1.5 rounded-full border border-success-600/20 bg-success-50 px-3 py-1.5 text-xs font-medium text-success-700"
                  >
                    <CheckCircle2 className="h-3.5 w-3.5" /> {s.department}
                  </span>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Profile</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div>
              <Label htmlFor="name">Full Name</Label>
              <Input id="name" defaultValue="Kiruthick B" />
            </div>
            <div>
              <Label htmlFor="citizenId">OneDesk ID</Label>
              <Input id="citizenId" defaultValue={masterIdentity.masterId} disabled />
            </div>
            <div>
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" defaultValue="kiruthick.b@example.com" />
            </div>
            <div>
              <Label htmlFor="mobile">Mobile Number</Label>
              <Input id="mobile" defaultValue="+91 98765 43210" />
            </div>
            <Button onClick={() => showToast('Profile updated', 'Your changes have been saved.')}>Save Changes</Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Notification Preferences</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <ToggleRow
              label="Email notifications"
              description="Receive application and consent updates by email."
              checked={notifyEmail}
              onChange={setNotifyEmail}
            />
            <ToggleRow
              label="SMS notifications"
              description="Receive application status updates by SMS."
              checked={notifySms}
              onChange={setNotifySms}
            />
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

function ToggleRow({
  label,
  description,
  checked,
  onChange,
}: {
  label: string
  description: string
  checked: boolean
  onChange: (value: boolean) => void
}) {
  return (
    <div className="flex items-start justify-between gap-4">
      <div>
        <p className="text-sm font-medium text-gray-900">{label}</p>
        <p className="text-xs text-gray-500">{description}</p>
      </div>
      <button
        onClick={() => onChange(!checked)}
        className={`relative h-5 w-9 shrink-0 rounded-full transition-colors ${checked ? 'bg-brand-600' : 'bg-gray-200'}`}
      >
        <span
          className={`absolute top-0.5 h-4 w-4 rounded-full bg-white transition-transform ${checked ? 'translate-x-[18px]' : 'translate-x-0.5'}`}
        />
      </button>
    </div>
  )
}
