import { NavLink } from 'react-router-dom'

export function DetailTabs({ id }: { id: string }) {
  const tabs = [
    { label: 'Result', to: `/app/screening/${id}/result` },
    { label: 'Lesions', to: `/app/screening/${id}/lesions` },
    { label: 'Vessels', to: `/app/screening/${id}/vessels` },
    { label: 'Anatomy', to: `/app/screening/${id}/anatomy` },
    { label: 'Grad-CAM', to: `/app/screening/${id}/gradcam` },
    { label: 'Full Report', to: `/app/screening/${id}/report` },
  ]

  return (
    <div className="mb-5 flex flex-wrap gap-1.5">
      {tabs.map((t) => (
        <NavLink
          key={t.to}
          to={t.to}
          className={({ isActive }) =>
            `rounded-full px-3 py-1.5 text-xs font-medium transition-colors ${
              isActive ? 'bg-brand-600 text-white' : 'bg-white text-gray-600 border border-gray-200 hover:bg-gray-50'
            }`
          }
        >
          {t.label}
        </NavLink>
      ))}
    </div>
  )
}
