/** ORCA's whale-tail brand mark, matching public/favicon.svg. Used anywhere the emoji placeholder
 *  previously stood in (sidebar, chat avatar). */
export function OrcaMark({ className = 'h-4.5 w-4.5' }: { className?: string }) {
  return (
    <svg viewBox="0 0 200 200" className={className}>
      <defs>
        <linearGradient id="orcaMarkGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#67e8f9" />
          <stop offset="100%" stopColor="#0891b2" />
        </linearGradient>
      </defs>
      <path
        d="M100,168 C102,138 70,95 22,66 C42,98 72,120 100,134 C128,120 158,98 178,66 C130,95 98,138 100,168 Z"
        fill="url(#orcaMarkGrad)"
        stroke="#0e7490"
        strokeWidth="4"
        strokeLinejoin="round"
      />
    </svg>
  )
}
