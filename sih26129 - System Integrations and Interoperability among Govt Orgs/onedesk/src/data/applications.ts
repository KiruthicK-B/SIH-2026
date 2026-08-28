export type ApplicationStatus = 'In Progress' | 'Under Review' | 'Approved' | 'Completed' | 'Rejected'

export type TimelineStepStatus = 'done' | 'active' | 'blocked' | 'pending'

export interface TimelineStep {
  label: string
  department: string
  status: TimelineStepStatus
  date?: string
  systemType?: string
  note?: string
}

export interface Application {
  id: string
  service: string
  department: string
  status: ApplicationStatus
  lastUpdated: string
  submittedOn: string
  citizenName: string
  description: string
  timeline: TimelineStep[]
  flagship?: boolean
}

export const applications: Application[] = [
  {
    id: 'BL-2026-00128',
    service: 'Business License',
    department: 'Business Registry',
    status: 'In Progress',
    lastUpdated: '2026-08-27',
    submittedOn: '2026-08-27',
    citizenName: 'Kiruthick B',
    description:
      'One application, submitted once — verified across identity, business registry, tax, and municipal systems before a license is issued.',
    flagship: true,
    timeline: [
      { label: 'Application Submitted', department: 'OneDesk', status: 'done', date: '2026-08-27', systemType: 'Unified Portal' },
      { label: 'Identity Verified', department: 'Identity Service', status: 'done', date: '2026-08-27', systemType: 'OAuth / Federation' },
      { label: 'Business Details Verified', department: 'Business Registry', status: 'done', date: '2026-08-27', systemType: 'Legacy SOAP' },
      { label: 'Tax Verification', department: 'Revenue Department', status: 'active', systemType: 'REST API' },
      { label: 'Municipal Review', department: 'Municipal Corporation', status: 'pending', systemType: 'Legacy Database Adapter' },
      { label: 'Final Approval', department: 'License Authority', status: 'pending', systemType: 'REST API' },
    ],
  },
  {
    id: 'APP-2026-1001',
    service: 'Scholarship Scheme',
    department: 'Education Department',
    status: 'In Progress',
    lastUpdated: '2026-08-26',
    submittedOn: '2026-08-20',
    citizenName: 'Kiruthick B',
    description: 'Merit-cum-means scholarship for undergraduate students, cross-verified with income records from the Revenue Department.',
    timeline: [
      { label: 'Application Submitted', department: 'Unified Portal', status: 'done', date: '2026-08-20' },
      { label: 'Documents Verified', department: 'Education Department', status: 'done', date: '2026-08-21' },
      { label: 'Eligibility Verification', department: 'Revenue Department', status: 'active', date: '2026-08-26' },
      { label: 'Department Approval', department: 'Education Department', status: 'pending' },
      { label: 'Application Completed', department: 'Education Department', status: 'pending' },
    ],
  },
  {
    id: 'APP-2026-1002',
    service: 'Income Certificate',
    department: 'Revenue Department',
    status: 'Under Review',
    lastUpdated: '2026-08-25',
    submittedOn: '2026-08-19',
    citizenName: 'Kiruthick B',
    description: 'Annual income certificate required for scholarship and welfare scheme eligibility verification.',
    timeline: [
      { label: 'Application Submitted', department: 'Unified Portal', status: 'done', date: '2026-08-19' },
      { label: 'Document Check', department: 'Revenue Department', status: 'done', date: '2026-08-20' },
      { label: 'Field Verification', department: 'Local Govt Office', status: 'active', date: '2026-08-25' },
      { label: 'Committee Review', department: 'Revenue Department', status: 'pending' },
      { label: 'Certificate Issued', department: 'Revenue Department', status: 'pending' },
    ],
  },
  {
    id: 'APP-2026-1003',
    service: 'Business Registration',
    department: 'Business Registry',
    status: 'Approved',
    lastUpdated: '2026-08-24',
    submittedOn: '2026-08-10',
    citizenName: 'Kiruthick B',
    description: 'New micro-enterprise registration under the state industries promotion scheme.',
    timeline: [
      { label: 'Application Submitted', department: 'Unified Portal', status: 'done', date: '2026-08-10' },
      { label: 'Documents Verified', department: 'Business Registry', status: 'done', date: '2026-08-13' },
      { label: 'Site Verification', department: 'Municipal Corporation', status: 'done', date: '2026-08-18' },
      { label: 'Department Approval', department: 'Business Registry', status: 'done', date: '2026-08-24' },
      { label: 'Registration Completed', department: 'Business Registry', status: 'pending' },
    ],
  },
  {
    id: 'APP-2026-1004',
    service: 'Utility Connection',
    department: 'Municipal Corporation',
    status: 'In Progress',
    lastUpdated: '2026-08-23',
    submittedOn: '2026-08-15',
    citizenName: 'Kiruthick B',
    description: 'New water and electricity connection request for a registered residential property.',
    timeline: [
      { label: 'Application Submitted', department: 'Unified Portal', status: 'done', date: '2026-08-15' },
      { label: 'Property Verification', department: 'Municipal Corporation', status: 'done', date: '2026-08-19' },
      { label: 'Technical Survey', department: 'Municipal Corporation', status: 'active', date: '2026-08-23' },
      { label: 'Connection Approval', department: 'Municipal Corporation', status: 'pending' },
      { label: 'Connection Activated', department: 'Municipal Corporation', status: 'pending' },
    ],
  },
  {
    id: 'APP-2026-1005',
    service: 'Ration Card',
    department: 'Food & Civil Supplies',
    status: 'Completed',
    lastUpdated: '2026-08-05',
    submittedOn: '2026-07-22',
    citizenName: 'Kiruthick B',
    description: 'New household ration card issuance linked to verified residence and identity records.',
    timeline: [
      { label: 'Application Submitted', department: 'Unified Portal', status: 'done', date: '2026-07-22' },
      { label: 'Documents Verified', department: 'Food & Civil Supplies', status: 'done', date: '2026-07-25' },
      { label: 'Field Verification', department: 'Local Govt Office', status: 'done', date: '2026-07-30' },
      { label: 'Department Approval', department: 'Food & Civil Supplies', status: 'done', date: '2026-08-02' },
      { label: 'Application Completed', department: 'Food & Civil Supplies', status: 'done', date: '2026-08-05' },
    ],
  },
  {
    id: 'APP-2026-1006',
    service: 'Health Insurance Enrollment',
    department: 'Health Department',
    status: 'Rejected',
    lastUpdated: '2026-08-12',
    submittedOn: '2026-08-01',
    citizenName: 'Kiruthick B',
    description: 'Enrollment under the state health benefit scheme; rejected due to duplicate beneficiary record.',
    timeline: [
      { label: 'Application Submitted', department: 'Unified Portal', status: 'done', date: '2026-08-01' },
      { label: 'Eligibility Check', department: 'Health Department', status: 'done', date: '2026-08-05' },
      { label: 'Duplicate Record Flagged', department: 'Health Department', status: 'done', date: '2026-08-12' },
      { label: 'Department Approval', department: 'Health Department', status: 'pending' },
      { label: 'Enrollment Completed', department: 'Health Department', status: 'pending' },
    ],
  },
]

export function getApplicationById(id: string) {
  return applications.find((a) => a.id === id)
}
