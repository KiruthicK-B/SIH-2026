export const dataQualityMetrics = {
  recordsProcessed: 18492,
  validRecords: 17930,
  warnings: 421,
  validationErrors: 141,
}

export interface DataQualityIssue {
  label: string
  count: number
}

export const dataQualityIssues: DataQualityIssue[] = [
  { label: 'Missing Required Field', count: 152 },
  { label: 'Invalid Identifier', count: 98 },
  { label: 'Duplicate Entity', count: 76 },
  { label: 'Invalid Date Format', count: 41 },
  { label: 'Schema Mismatch', count: 33 },
]

export interface DepartmentDataQuality {
  department: string
  validRate: number
}

export const dataQualityByDepartment: DepartmentDataQuality[] = [
  { department: 'Education Department', validRate: 98.2 },
  { department: 'Revenue Department', validRate: 95.6 },
  { department: 'Municipal Corporation', validRate: 96.9 },
  { department: 'Health Department', validRate: 97.4 },
  { department: 'Food & Civil Supplies', validRate: 94.1 },
]
