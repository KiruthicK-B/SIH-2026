import { Select } from '@/components/ui/Select'
import { type Role, useRole } from '@/context/RoleContext'

const roleOptions: { value: Role; label: string }[] = [
  { value: 'Citizen', label: 'Citizen' },
  { value: 'Department Officer', label: 'Department Officer' },
  { value: 'Platform Administrator', label: 'Platform Administrator' },
]

export function RoleSwitcher() {
  const { role, setRole } = useRole()

  return (
    <div className="hidden items-center gap-2 md:flex">
      <span className="text-xs font-medium text-gray-400">Role</span>
      <Select
        value={role}
        onValueChange={(v) => setRole(v as Role)}
        options={roleOptions}
        className="w-52"
      />
    </div>
  )
}
