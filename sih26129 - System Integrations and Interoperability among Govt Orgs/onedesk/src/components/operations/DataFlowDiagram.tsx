import { useTranslation } from 'react-i18next'

export function DataFlowDiagram() {
  const { t } = useTranslation()
  const layerLabels = [
    t('dataFlowDiagram.layerIdentity'),
    t('dataFlowDiagram.layerConsent'),
    t('dataFlowDiagram.layerDataMapping'),
    t('dataFlowDiagram.layerWorkflow'),
    t('dataFlowDiagram.layerValidation'),
    t('dataFlowDiagram.layerEvents'),
    t('dataFlowDiagram.layerAudit'),
  ]
  const departments = [
    t('dataFlowDiagram.deptEducation'),
    t('dataFlowDiagram.deptRevenue'),
    t('dataFlowDiagram.deptMunicipal'),
    t('dataFlowDiagram.deptHealth'),
  ]

  return (
    <div className="flex flex-col items-center py-4">
      <FlowBox label={t('dataFlowDiagram.citizen')} />
      <Connector />
      <FlowBox label={t('dataFlowDiagram.unifiedPortal')} />
      <Connector />

      <div className="w-full max-w-2xl rounded-lg border-2 border-navy-800/20 bg-navy-800/[0.03] p-4">
        <p className="mb-3 text-center text-xs font-semibold uppercase tracking-wide text-navy-800">
          {t('dataFlowDiagram.interoperabilityLayer')}
        </p>
        <div className="flex flex-wrap justify-center gap-2">
          {layerLabels.map((label) => (
            <span
              key={label}
              className="rounded-md border border-navy-800/15 bg-white px-2.5 py-1 text-[11px] font-medium text-navy-800"
            >
              {label}
            </span>
          ))}
        </div>
      </div>

      <Connector />

      <div className="grid w-full max-w-3xl grid-cols-2 gap-3 sm:grid-cols-4">
        {departments.map((dept) => (
          <div
            key={dept}
            className="whitespace-pre-line rounded-md border border-gray-200 bg-white px-3 py-3 text-center text-xs font-medium text-gray-700"
          >
            {dept}
          </div>
        ))}
      </div>
    </div>
  )
}

function FlowBox({ label }: { label: string }) {
  return (
    <div className="rounded-md border border-gray-300 bg-white px-6 py-2.5 text-sm font-medium text-gray-800 shadow-xs">
      {label}
    </div>
  )
}

function Connector() {
  return <div className="my-1.5 h-6 w-px bg-gray-300" />
}
