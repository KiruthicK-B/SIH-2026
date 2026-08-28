import * as ToastPrimitive from '@radix-ui/react-toast'
import { CheckCircle2 } from 'lucide-react'
import { createContext, type ReactNode, useCallback, useContext, useState } from 'react'

interface ToastItem {
  id: number
  title: string
  description?: string
}

interface ToastContextValue {
  showToast: (title: string, description?: string) => void
}

const ToastContext = createContext<ToastContextValue | null>(null)

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastItem[]>([])

  const showToast = useCallback((title: string, description?: string) => {
    const id = Date.now()
    setToasts((prev) => [...prev, { id, title, description }])
  }, [])

  const dismiss = useCallback((id: number) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  return (
    <ToastContext.Provider value={{ showToast }}>
      <ToastPrimitive.Provider swipeDirection="right" duration={4000}>
        {children}
        {toasts.map((t) => (
          <ToastPrimitive.Root
            key={t.id}
            onOpenChange={(open) => !open && dismiss(t.id)}
            className="flex items-start gap-3 rounded-lg border border-gray-200 bg-white p-4 shadow-lg"
          >
            <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-success-600" />
            <div>
              <ToastPrimitive.Title className="text-sm font-semibold text-gray-900">
                {t.title}
              </ToastPrimitive.Title>
              {t.description && (
                <ToastPrimitive.Description className="mt-0.5 text-sm text-gray-500">
                  {t.description}
                </ToastPrimitive.Description>
              )}
            </div>
          </ToastPrimitive.Root>
        ))}
        <ToastPrimitive.Viewport className="fixed bottom-0 right-0 z-[100] m-0 flex w-96 max-w-[100vw] flex-col gap-2 p-6 outline-none" />
      </ToastPrimitive.Provider>
    </ToastContext.Provider>
  )
}

export function useToast() {
  const ctx = useContext(ToastContext)
  if (!ctx) throw new Error('useToast must be used within ToastProvider')
  return ctx
}
