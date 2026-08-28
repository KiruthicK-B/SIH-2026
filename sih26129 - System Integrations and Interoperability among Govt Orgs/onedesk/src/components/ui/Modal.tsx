import * as Dialog from '@radix-ui/react-dialog'
import { X } from 'lucide-react'
import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

interface ModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  description?: string
  children: ReactNode
  className?: string
}

export function Modal({ open, onOpenChange, title, description, children, className }: ModalProps) {
  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 z-50 bg-navy-950/40 transition-opacity" />
        <Dialog.Content
          className={cn(
            'fixed left-1/2 top-1/2 z-50 w-full max-w-lg -translate-x-1/2 -translate-y-1/2 rounded-lg border border-gray-200 bg-white p-6 shadow-lg transition-all',
            className,
          )}
        >
          <div className="mb-4 flex items-start justify-between">
            <div>
              <Dialog.Title className="text-base font-semibold text-gray-900">{title}</Dialog.Title>
              {description && (
                <Dialog.Description className="mt-1 text-sm text-gray-500">{description}</Dialog.Description>
              )}
            </div>
            <Dialog.Close className="rounded-md p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600">
              <X className="h-4 w-4" />
            </Dialog.Close>
          </div>
          {children}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}
