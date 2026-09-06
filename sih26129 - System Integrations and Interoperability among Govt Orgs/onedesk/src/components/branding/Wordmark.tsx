import { cn } from '@/lib/utils'

interface WordmarkProps {
  size?: 'sm' | 'md' | 'lg' | 'xl'
  /** Use on dark (navy) backgrounds — Sidebar, BrandBanner — where plain navy-900
   * text would be invisible. */
  dark?: boolean
  className?: string
}

const sizeClasses = {
  sm: 'text-lg',
  md: 'text-2xl',
  lg: 'text-3xl',
  xl: 'text-5xl',
}

export function Wordmark({ size = 'md', dark = false, className }: WordmarkProps) {
  return (
    <span className={cn('font-extrabold leading-none tracking-tight', sizeClasses[size], className)}>
      <span className={dark ? 'text-white' : 'text-navy-900'}>One</span>
      <span className={dark ? 'text-brand-100' : 'text-brand-600'}>Desk</span>
    </span>
  )
}
