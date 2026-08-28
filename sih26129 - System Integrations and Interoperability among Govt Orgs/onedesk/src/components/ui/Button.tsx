import { Slot } from '@radix-ui/react-slot'
import { type ButtonHTMLAttributes, forwardRef } from 'react'
import { cn } from '@/lib/utils'

type Variant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger'
type Size = 'sm' | 'md' | 'lg' | 'icon'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant
  size?: Size
  asChild?: boolean
}

const variantClasses: Record<Variant, string> = {
  primary: 'bg-navy-800 text-white hover:bg-navy-700 focus-visible:ring-navy-700',
  secondary: 'bg-brand-50 text-brand-700 hover:bg-brand-100 focus-visible:ring-brand-500',
  outline: 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus-visible:ring-gray-400',
  ghost: 'text-gray-600 hover:bg-gray-100 focus-visible:ring-gray-400',
  danger: 'bg-danger-600 text-white hover:bg-danger-700 focus-visible:ring-danger-600',
}

const sizeClasses: Record<Size, string> = {
  sm: 'h-8 px-3 text-xs gap-1.5',
  md: 'h-9 px-4 text-sm gap-2',
  lg: 'h-10 px-5 text-sm gap-2',
  icon: 'h-9 w-9',
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button'
    return (
      <Comp
        ref={ref}
        className={cn(
          'inline-flex items-center justify-center whitespace-nowrap rounded-md font-medium transition-colors',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-1',
          'disabled:pointer-events-none disabled:opacity-50',
          variantClasses[variant],
          sizeClasses[size],
          className,
        )}
        {...props}
      />
    )
  },
)
Button.displayName = 'Button'
