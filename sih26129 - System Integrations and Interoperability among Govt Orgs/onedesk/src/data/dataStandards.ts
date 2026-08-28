export interface FieldMapping {
  sourceField: string
  sourceValue: string
  commonField: string
  commonValue: string
}

export const transformationExample: FieldMapping[] = [
  { sourceField: 'full_name', sourceValue: 'Kiruthick B', commonField: 'name', commonValue: 'Kiruthick B' },
  { sourceField: 'dob', sourceValue: '27/08/2000', commonField: 'dateOfBirth', commonValue: '2000-08-27' },
  { sourceField: 'citizen_identifier', sourceValue: 'CIT-10282', commonField: 'citizenId', commonValue: 'CIT-10282' },
]

export const transformationChecks = ['Schema validated', 'Fields mapped', 'Identifier resolved']

export const sourceSystemLabel = 'Business Registry — Legacy Registry Export'
export const commonModelLabel = 'OneDesk Common Government Data Model'
