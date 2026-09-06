import LanguageDetector from 'i18next-browser-languagedetector'
import i18n from 'i18next'
import { initReactI18next } from 'react-i18next'
import bn from './locales/bn.json'
import en from './locales/en.json'
import gu from './locales/gu.json'
import hi from './locales/hi.json'
import ml from './locales/ml.json'
import mr from './locales/mr.json'
import ta from './locales/ta.json'
import te from './locales/te.json'

export interface SupportedLanguage {
  code: string
  englishName: string
  nativeName: string
}

// Order matches the switcher dropdown — English first, then the 8 scheduled
// languages by speaker count.
export const SUPPORTED_LANGUAGES: SupportedLanguage[] = [
  { code: 'en', englishName: 'English', nativeName: 'English' },
  { code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी' },
  { code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা' },
  { code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు' },
  { code: 'mr', englishName: 'Marathi', nativeName: 'मराठी' },
  { code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்' },
  { code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી' },
  { code: 'ml', englishName: 'Malayalam', nativeName: 'മലയാളം' },
]

export const LANGUAGE_STORAGE_KEY = 'onedesk_language'

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      en: { translation: en },
      hi: { translation: hi },
      bn: { translation: bn },
      te: { translation: te },
      mr: { translation: mr },
      ta: { translation: ta },
      gu: { translation: gu },
      ml: { translation: ml },
    },
    fallbackLng: 'en',
    interpolation: { escapeValue: false },
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
      lookupLocalStorage: LANGUAGE_STORAGE_KEY,
    },
  })

export default i18n
