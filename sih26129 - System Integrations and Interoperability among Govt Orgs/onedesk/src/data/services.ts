export interface Service {
  id: string
  name: string
  department: string
  category: string
  processingTime: string
  requiredDocuments: string[]
  description: string
}

export const serviceCategories = ['Business', 'Education', 'Revenue', 'Municipal', 'Health', 'Social Welfare'] as const

export const services: Service[] = [
  {
    id: 'svc-business-license',
    name: 'Business License',
    department: 'Business Registry',
    category: 'Business',
    processingTime: '5 working days',
    requiredDocuments: ['Identity Proof', 'Business Registration Draft', 'Address Proof', 'Income Declaration'],
    description:
      'A single application that is verified across identity, business registry, tax, and municipal records before a license is issued — you submit your details once.',
  },
  {
    id: 'svc-scholarship',
    name: 'Scholarship Scheme',
    department: 'Education Department',
    category: 'Education',
    processingTime: '10–15 working days',
    requiredDocuments: ['Academic Records', 'Income Certificate', 'Aadhaar Card', 'Bank Passbook'],
    description: 'Merit-cum-means scholarship support for undergraduate and postgraduate students enrolled in recognized institutions.',
  },
  {
    id: 'svc-student-certificate',
    name: 'Student Certificates',
    department: 'Education Department',
    category: 'Education',
    processingTime: '5–7 working days',
    requiredDocuments: ['School/College ID', 'Previous Marksheet'],
    description: 'Issuance of bonafide, transfer, and migration certificates for enrolled students.',
  },
  {
    id: 'svc-academic-verification',
    name: 'Academic Verification',
    department: 'Education Department',
    category: 'Education',
    processingTime: '3–5 working days',
    requiredDocuments: ['Degree Certificate', 'Marksheet'],
    description: 'Verification of academic credentials for employment or higher education purposes.',
  },
  {
    id: 'svc-income-certificate',
    name: 'Income Certificate',
    department: 'Revenue Department',
    category: 'Revenue',
    processingTime: '7–10 working days',
    requiredDocuments: ['Salary Slip / Income Proof', 'Aadhaar Card', 'Residence Proof'],
    description: 'Official certification of annual household income for scheme eligibility purposes.',
  },
  {
    id: 'svc-residence-certificate',
    name: 'Residence Certificate',
    department: 'Revenue Department',
    category: 'Revenue',
    processingTime: '5–7 working days',
    requiredDocuments: ['Aadhaar Card', 'Utility Bill', 'Ration Card'],
    description: 'Proof of domicile issued for education, employment, and welfare scheme applications.',
  },
  {
    id: 'svc-tax-services',
    name: 'Tax Services',
    department: 'Revenue Department',
    category: 'Revenue',
    processingTime: '3–5 working days',
    requiredDocuments: ['Property Documents', 'Previous Tax Receipt'],
    description: 'Property tax assessment, payment, and dispute resolution services.',
  },
  {
    id: 'svc-utility-connection',
    name: 'Utility Connection',
    department: 'Municipal Corporation',
    category: 'Municipal',
    processingTime: '12–15 working days',
    requiredDocuments: ['Property Ownership Proof', 'Identity Proof'],
    description: 'New water and electricity connection requests for residential and commercial properties.',
  },
  {
    id: 'svc-property-services',
    name: 'Property Services',
    department: 'Municipal Corporation',
    category: 'Municipal',
    processingTime: '10–12 working days',
    requiredDocuments: ['Sale Deed', 'Property Tax Receipt'],
    description: 'Property mutation, ownership transfer, and building plan approval services.',
  },
  {
    id: 'svc-birth-certificate',
    name: 'Birth Certificate',
    department: 'Municipal Corporation',
    category: 'Municipal',
    processingTime: '3–5 working days',
    requiredDocuments: ['Hospital Discharge Record', "Parents' Identity Proof"],
    description: 'Registration and certified copy issuance for birth records.',
  },
  {
    id: 'svc-health-benefits',
    name: 'Health Benefits',
    department: 'Health Department',
    category: 'Health',
    processingTime: '7–10 working days',
    requiredDocuments: ['Aadhaar Card', 'Income Certificate'],
    description: 'Enrollment into state-sponsored health benefit and treatment assistance schemes.',
  },
  {
    id: 'svc-insurance-services',
    name: 'Insurance Services',
    department: 'Health Department',
    category: 'Health',
    processingTime: '10–14 working days',
    requiredDocuments: ['Aadhaar Card', 'Family Details Form'],
    description: 'Enrollment and claims support for state health insurance coverage.',
  },
  {
    id: 'svc-pension',
    name: 'Pension',
    department: 'Social Welfare Department',
    category: 'Social Welfare',
    processingTime: '15–20 working days',
    requiredDocuments: ['Age Proof', 'Income Certificate', 'Bank Passbook'],
    description: 'Old-age, widow, and disability pension scheme enrollment and disbursement tracking.',
  },
  {
    id: 'svc-welfare-schemes',
    name: 'Welfare Schemes',
    department: 'Social Welfare Department',
    category: 'Social Welfare',
    processingTime: '10–15 working days',
    requiredDocuments: ['Aadhaar Card', 'Caste Certificate (if applicable)'],
    description: 'Access to state and central welfare scheme benefits for eligible households.',
  },
  {
    id: 'svc-benefits',
    name: 'Benefits Disbursement',
    department: 'Social Welfare Department',
    category: 'Social Welfare',
    processingTime: '5–7 working days',
    requiredDocuments: ['Scheme Enrollment ID', 'Bank Passbook'],
    description: 'Tracking and direct benefit transfer status for enrolled welfare schemes.',
  },
]

export function getServiceById(id: string) {
  return services.find((s) => s.id === id)
}

export function getServicesByCategory(category: string) {
  return services.filter((s) => s.category === category)
}
