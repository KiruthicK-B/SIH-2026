export interface SlaEntry {
  label: string
  targetLabel: string
  targetHours: number
  currentLabel: string
  currentHours: number
  withinSla: boolean
}
