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
