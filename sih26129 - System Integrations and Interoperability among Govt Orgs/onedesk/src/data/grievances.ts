export type GrievanceStatus = 'Open' | 'In Progress' | 'Resolved'

export interface Grievance {
  id: string
  subject: string
  department: string
  relatedApplication?: string
  status: GrievanceStatus
  filedOn: string
  description: string
}

export const grievances: Grievance[] = [
  {
    id: 'GRV-2026-501',
    subject: 'Delay in income certificate verification',
    department: 'Revenue Department',
    relatedApplication: 'APP-2026-1002',
    status: 'In Progress',
    filedOn: '2026-08-24',
    description: 'Field verification for income certificate has been pending for more than 5 working days.',
  },
  {
    id: 'GRV-2026-498',
    subject: 'Duplicate beneficiary record blocking enrollment',
    department: 'Health Department',
    relatedApplication: 'APP-2026-1006',
    status: 'Open',
    filedOn: '2026-08-13',
    description: 'Health insurance enrollment was rejected citing a duplicate record that does not belong to the applicant.',
  },
  {
    id: 'GRV-2026-475',
    subject: 'Incorrect address on ration card',
    department: 'Food & Civil Supplies',
    relatedApplication: 'APP-2026-1005',
    status: 'Resolved',
    filedOn: '2026-08-06',
    description: 'Address printed on the issued ration card did not match the submitted residence proof.',
  },
]
