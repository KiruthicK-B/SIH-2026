import { useMemo, useState } from 'react'
import { ArrowRight, Users, Cpu, Timer, Gauge } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'
import { StatCard } from '@/components/shared/StatCard'

const FLOW_STEPS = [
  'Patient Arrival',
  'Fundus Imaging',
  'Image Upload',
  'Network Transfer',
  'AI Screening',
  'Referable Queue',
  'Ophthalmologist Review',
]

const REFERABLE_RATE = 0.3 // fraction of screened patients flagged referable, aligned with mock pipeline stats

export default function SimulinkSimulation() {
  const [patientsPerDay, setPatientsPerDay] = useState(280)
  const [aiCapacityPerDay, setAiCapacityPerDay] = useState(350)
  const [ophthalmologists, setOphthalmologists] = useState(3)
  const [reviewsPerDoctor, setReviewsPerDoctor] = useState(35)

  const derived = useMemo(() => {
    const utilization = Math.min(1.5, patientsPerDay / aiCapacityPerDay)
    const referableLoad = patientsPerDay * REFERABLE_RATE
    const reviewCapacity = ophthalmologists * reviewsPerDoctor
    const queueRatio = referableLoad / Math.max(1, reviewCapacity)
    const avgQueueTimeMins = Math.max(4, Math.round(18 * queueRatio + (utilization > 1 ? (utilization - 1) * 40 : 0)))
    const backlogPerDay = Math.max(0, Math.round(referableLoad - reviewCapacity))

    return {
      utilizationPct: Math.round(utilization * 100),
      avgQueueTimeMins,
      backlogPerDay,
      referableLoad: Math.round(referableLoad),
      reviewCapacity,
    }
  }, [patientsPerDay, aiCapacityPerDay, ophthalmologists, reviewsPerDoctor])

  return (
    <AppShell area="operator">
      <h1 className="mb-1 text-lg font-bold text-gray-900">Workflow Simulation</h1>
      <p className="mb-5 text-xs text-gray-500">
        Simulink-style telemedicine deployment model — patient arrival, AI processing capacity, and
        ophthalmologist review queue. Simulation runs downstream of the DR detection pipeline.
      </p>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Telemedicine Screening Workflow</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap items-center gap-2">
            {FLOW_STEPS.map((step, i) => (
              <div key={step} className="flex items-center gap-2">
                <div className="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-center text-[11px] font-medium text-gray-700">
                  {step}
                </div>
                {i < FLOW_STEPS.length - 1 && <ArrowRight className="h-3.5 w-3.5 shrink-0 text-gray-300" />}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Simulation Inputs</CardTitle>
          </CardHeader>
          <CardContent className="space-y-5">
            <SliderField
              label="Patients / Day"
              value={patientsPerDay}
              min={50}
              max={600}
              step={10}
              onChange={setPatientsPerDay}
            />
            <SliderField
              label="AI Processing Capacity / Day"
              value={aiCapacityPerDay}
              min={100}
              max={600}
              step={10}
              onChange={setAiCapacityPerDay}
            />
            <SliderField
              label="Ophthalmologists Available"
              value={ophthalmologists}
              min={1}
              max={10}
              step={1}
              onChange={setOphthalmologists}
            />
            <SliderField
              label="Reviews / Ophthalmologist / Day"
              value={reviewsPerDoctor}
              min={10}
              max={80}
              step={5}
              onChange={setReviewsPerDoctor}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Simulation Summary</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4">
              <StatCard icon={Users} label="Patients / Day" value={patientsPerDay} tone="brand" />
              <StatCard icon={Cpu} label="AI Capacity / Day" value={aiCapacityPerDay} tone="info" />
              <StatCard icon={Timer} label="Avg. Queue Time" value={`${derived.avgQueueTimeMins} mins`} tone="warning" />
              <StatCard icon={Gauge} label="AI Utilization" value={`${derived.utilizationPct}%`} tone={derived.utilizationPct > 100 ? 'danger' : 'success'} />
            </div>

            <div className="mt-4 space-y-2 border-t border-gray-100 pt-4 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-500">Referable cases / day (est.)</span>
                <span className="font-semibold text-gray-800">{derived.referableLoad}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Ophthalmologist review capacity / day</span>
                <span className="font-semibold text-gray-800">{derived.reviewCapacity}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Unreviewed backlog / day</span>
                <span className={`font-semibold ${derived.backlogPerDay > 0 ? 'text-danger-600' : 'text-success-600'}`}>
                  {derived.backlogPerDay}
                </span>
              </div>
            </div>

            {derived.utilizationPct > 100 && (
              <p className="mt-3 rounded-lg bg-danger-50 px-3 py-2 text-xs text-danger-700">
                AI processing demand exceeds configured capacity — consider scaling inference resources.
              </p>
            )}
            {derived.backlogPerDay > 0 && (
              <p className="mt-2 rounded-lg bg-warning-50 px-3 py-2 text-xs text-warning-700">
                Ophthalmologist review capacity is insufficient for the referable case load — backlog will
                accumulate over consecutive days.
              </p>
            )}
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}

function SliderField({
  label,
  value,
  min,
  max,
  step,
  onChange,
}: {
  label: string
  value: number
  min: number
  max: number
  step: number
  onChange: (v: number) => void
}) {
  return (
    <div>
      <div className="mb-1.5 flex items-center justify-between">
        <label className="text-xs font-medium text-gray-600">{label}</label>
        <span className="text-xs font-bold text-brand-700">{value}</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
        className="w-full accent-brand-600"
      />
    </div>
  )
}
