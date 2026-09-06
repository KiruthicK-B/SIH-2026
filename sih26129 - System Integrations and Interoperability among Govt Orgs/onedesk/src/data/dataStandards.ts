export interface FieldMapping {
  sourceField: string
  sourceValue: string
  commonField: string
  commonValue: string
}

export const transformationChecks = ['Schema validated', 'Fields mapped', 'Identifier resolved']

export const sourceSystemLabel = 'Business Registry — Legacy Registry Export'
export const commonModelLabel = 'OneDesk Common Government Data Model'
