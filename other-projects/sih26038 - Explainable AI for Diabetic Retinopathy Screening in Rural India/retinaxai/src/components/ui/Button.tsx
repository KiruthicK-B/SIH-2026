import { forwardRef, type ButtonHTMLAttributes } from 'react'
import { cn } from '@/lib/utils'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'outline' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
}

const variants = {
  primary: 'bg-brand-600 text-white hover:bg-brand-700 shadow-sm',
  outline: 'border border-gray-300 text-gray-700 bg-white hover:bg-gray-50',
  ghost: 'text-gray-600 hover:bg-gray-100',
  danger: 'bg-danger-600 text-white hover:bg-danger-700',
}

const sizes = {
  sm: 'text-xs px-2.5 py-1.5 rounded-md',
  md: 'text-sm px-4 py-2 rounded-lg',
  lg: 'text-base px-5 py-2.5 rounded-lg',
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(
          'inline-flex items-center justify-center gap-2 font-medium transition-colors disabled:opacity-50 disabled:pointer-events-none',
          variants[variant],
          sizes[size],
          className,
        )}
        {...props}
      />
    )
  },
)
Button.displayName = 'Button'
