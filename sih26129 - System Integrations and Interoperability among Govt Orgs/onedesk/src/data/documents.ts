export interface CitizenDocument {
  id: string
  name: string
  issuedBy: string
  status: 'Verified' | 'Pending Verification'
  issuedOn: string
}

export const citizenDocuments: CitizenDocument[] = [
  { id: 'doc-1', name: 'Aadhaar Card', issuedBy: 'UIDAI', status: 'Verified', issuedOn: '2021-02-14' },
  { id: 'doc-2', name: 'Income Certificate', issuedBy: 'Revenue Department', status: 'Verified', issuedOn: '2026-01-10' },
  { id: 'doc-3', name: 'Residence Certificate', issuedBy: 'Revenue Department', status: 'Verified', issuedOn: '2025-11-02' },
  { id: 'doc-4', name: 'Academic Marksheet', issuedBy: 'Education Department', status: 'Verified', issuedOn: '2024-06-20' },
  { id: 'doc-5', name: 'Ration Card', issuedBy: 'Food & Civil Supplies', status: 'Verified', issuedOn: '2026-08-05' },
  { id: 'doc-6', name: 'Bank Passbook', issuedBy: 'Self-uploaded', status: 'Pending Verification', issuedOn: '2026-08-22' },
]
