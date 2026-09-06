import type { TFunction } from 'i18next'

// Scope catalog entries (key, label, sourceAuthority) come from core-api's
// scope-catalog.ts at runtime via /auth/register/scopes and /identity/scopes — never
// hardcoded on the frontend, so a new scope the backend adds shows up automatically.
// Translation only covers the *known* keys as of this build; an unrecognized key
// (future scope added server-side before the frontend catches up) still renders
// correctly using the raw label/sourceAuthority the API actually sent, in whatever
// language that happens to be (English) — never blank, never crashes.
export function translateScopeLabel(t: TFunction, key: string, fallbackLabel: string): string {
  const translated = t(`scopes.${key}.label`, { defaultValue: '' })
  return translated || fallbackLabel
}

export function translateScopeSource(t: TFunction, key: string, fallbackSource: string): string {
  const translated = t(`scopes.${key}.source`, { defaultValue: '' })
  return translated || fallbackSource
}
