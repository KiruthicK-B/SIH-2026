import * as DropdownMenu from '@radix-ui/react-dropdown-menu'
import { Check, Languages } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { SUPPORTED_LANGUAGES } from '@/i18n/config'
import { cn } from '@/lib/utils'

// Placed at the top of every page (public pages and the signed-in app shell alike)
// — a citizen picks a language once and it's remembered (i18next-browser-languagedetector
// persists to localStorage), not re-asked on every page.
export function LanguageSwitcher({ variant = 'light' }: { variant?: 'light' | 'dark' }) {
  const { i18n } = useTranslation()
  const current = SUPPORTED_LANGUAGES.find((l) => l.code === i18n.language) ?? SUPPORTED_LANGUAGES[0]

  return (
    <DropdownMenu.Root>
      <DropdownMenu.Trigger asChild>
        <button
          type="button"
          className={cn(
            'flex items-center gap-1.5 rounded-sm px-1.5 py-0.5 text-xs font-medium transition-colors',
            variant === 'dark'
              ? 'text-slate-300 hover:text-white'
              : 'text-gray-500 hover:bg-gray-100 hover:text-gray-700',
          )}
          aria-label="Change language"
        >
          <Languages className="h-3.5 w-3.5" />
          {current.nativeName}
        </button>
      </DropdownMenu.Trigger>
      <DropdownMenu.Portal>
        <DropdownMenu.Content
          align="end"
          sideOffset={8}
          className="z-50 max-h-80 w-48 overflow-y-auto rounded-md border border-gray-200 bg-white p-1 shadow-md"
        >
          {SUPPORTED_LANGUAGES.map((lang) => (
            <DropdownMenu.Item
              key={lang.code}
              onSelect={() => i18n.changeLanguage(lang.code)}
              className="flex cursor-pointer items-center justify-between gap-2 rounded-sm px-2.5 py-2 text-sm text-gray-700 outline-none data-[highlighted]:bg-gray-100"
            >
              <span>
                {lang.nativeName}
                {lang.code !== 'en' && <span className="ml-1.5 text-xs text-gray-400">{lang.englishName}</span>}
              </span>
              {current.code === lang.code && <Check className="h-3.5 w-3.5 text-brand-600" />}
            </DropdownMenu.Item>
          ))}
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  )
}
