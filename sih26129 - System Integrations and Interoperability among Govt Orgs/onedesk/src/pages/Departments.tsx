import { Building2 } from 'lucide-react'
import { Link } from 'react-router-dom'
import { PageHeader } from '@/components/shared/PageHeader'
import { Card } from '@/components/ui/Card'
import { citizenFacingDepartments as departments } from '@/data/departments'

export default function Departments() {
  return (
    <div>
      <PageHeader title="Connected Departments" subtitle="Departments and agencies integrated with OneDesk." />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {departments.map((d) => (
          <Link key={d.id} to={`/departments/${d.id}`}>
            <Card className="h-full p-5 transition-shadow hover:shadow-sm">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-md bg-navy-800/5 text-navy-800">
                  <Building2 className="h-5 w-5" />
                </div>
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold text-gray-900">{d.name}</p>
                  <p className="text-xs text-gray-500">{d.serviceCount} Services</p>
                </div>
              </div>
              <p className="mt-3 line-clamp-2 text-xs text-gray-500">{d.description}</p>
              <div className="mt-4 flex items-center justify-between border-t border-gray-100 pt-3">
                <span className="text-xs text-gray-500">{d.interfaceType}</span>
                <span className="flex items-center gap-1 text-xs font-medium text-success-600">
                  <span className="h-1.5 w-1.5 rounded-full bg-success-600" /> Connected
                </span>
              </div>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  )
}
