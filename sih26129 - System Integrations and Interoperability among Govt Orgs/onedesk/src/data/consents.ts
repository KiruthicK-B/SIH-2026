export type ConsentStatus = 'Active' | 'Revoked' | 'Expired'

export interface Consent {
  id: string
  dataCategory: string
  department: string
  purpose: string
  status: ConsentStatus
  grantedOn: string
  validUntil: string
}

export const initialConsents: Consent[] = [
  {
    id: 'con-1001',
    dataCategory: 'Business Income Details',
    department: 'Revenue Department',
    purpose: 'Tax Verification for Business License Processing',
    status: 'Active',
    grantedOn: '2026-08-27',
    validUntil: '2026-09-26',
  },
  {
    id: 'con-1002',
    dataCategory: 'Academic Details',
    department: 'Education Department',
    purpose: 'Scholarship Application',
    status: 'Active',
    grantedOn: '2026-08-20',
    validUntil: '2026-12-15',
  },
  {
    id: 'con-1003',
    dataCategory: 'Aadhaar Verification',
    department: 'All Departments',
    purpose: 'Identity Verification Across Services',
    status: 'Active',
    grantedOn: '2026-06-10',
    validUntil: '2026-12-10',
  },
  {
    id: 'con-1004',
    dataCategory: 'Property Records',
    department: 'Municipal Corporation',
    purpose: 'Utility Connection Verification',
    status: 'Expired',
    grantedOn: '2026-05-01',
    validUntil: '2026-08-01',
  },
  {
    id: 'con-1005',
    dataCategory: 'Health Records',
    department: 'Health Department',
    purpose: 'Insurance Enrollment Assessment',
    status: 'Revoked',
    grantedOn: '2026-04-12',
    validUntil: '2026-10-12',
  },
]

export interface PendingConsentRequest {
  id: string
  department: string
  purpose: string
  dataRequested: string[]
  requestedOn: string
}

export const pendingConsentRequests: PendingConsentRequest[] = [
  {
    id: 'req-2001',
    department: 'Municipal Corporation',
    purpose: 'Municipal Verification for Business License',
    dataRequested: ['Business Address', 'Property Records'],
    requestedOn: '2026-08-27',
  },
]
