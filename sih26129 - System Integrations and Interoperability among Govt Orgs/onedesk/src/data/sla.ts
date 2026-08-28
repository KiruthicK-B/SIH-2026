export interface SlaEntry {
  label: string
  targetLabel: string
  targetHours: number
  currentLabel: string
  currentHours: number
  withinSla: boolean
}

export const slaEntries: SlaEntry[] = [
  {
    label: 'Business License (end-to-end)',
    targetLabel: '5 working days',
    targetHours: 120,
    currentLabel: '3.2 days',
    currentHours: 76.8,
    withinSla: true,
  },
  {
    label: 'Identity Verification',
    targetLabel: '1 hour',
    targetHours: 1,
    currentLabel: '4 minutes',
    currentHours: 0.07,
    withinSla: true,
  },
  {
    label: 'Tax Verification',
    targetLabel: '24 hours',
    targetHours: 24,
    currentLabel: '6 hours',
    currentHours: 6,
    withinSla: true,
  },
  {
    label: 'Municipal Verification',
    targetLabel: '48 hours',
    targetHours: 48,
    currentLabel: '51 hours',
    currentHours: 51,
    withinSla: false,
  },
]

export const overallSlaCompliance = 97.8
