export interface CitizenDocument {
  id: string
  name: string
  issuedBy: string
  status: 'Verified' | 'Pending Verification'
  issuedOn: string
  applicationId?: string
  hasFile: boolean
}
