export interface DepartmentIdentifier {
  department: string
  identifier: string
}

export const masterIdentity = {
  citizenName: 'Kiruthick B',
  masterId: 'CIT-10282',
  departmentIdentifiers: [
    { department: 'Revenue', identifier: 'REV-8892' },
    { department: 'Education', identifier: 'EDU-2198' },
    { department: 'Welfare', identifier: 'WEL-7781' },
    { department: 'Business Registry', identifier: 'BR-5521' },
  ] as DepartmentIdentifier[],
}

export const connectedServices = [
  { department: 'Revenue', connected: true },
  { department: 'Business Registry', connected: true },
  { department: 'Municipal Corporation', connected: true },
  { department: 'Welfare', connected: true },
]
