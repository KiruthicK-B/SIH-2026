import { Building2, FileText, Mail, Phone, ShieldCheck } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { PageHeader } from '@/components/shared/PageHeader'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'

export default function Help() {
  const { t } = useTranslation()

  const faqs = [
    { question: t('help.faq1Question'), answer: t('help.faq1Answer') },
    { question: t('help.faq2Question'), answer: t('help.faq2Answer') },
    { question: t('help.faq3Question'), answer: t('help.faq3Answer') },
    { question: t('help.faq4Question'), answer: t('help.faq4Answer') },
  ]

  return (
    <div>
      <PageHeader title={t('help.title')} subtitle={t('help.subtitle')} />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="space-y-3 lg:col-span-2">
          {faqs.map((faq) => (
            <Card key={faq.question} className="p-5">
              <p className="text-sm font-semibold text-gray-900">{faq.question}</p>
              <p className="mt-1.5 text-sm text-gray-600">{faq.answer}</p>
            </Card>
          ))}
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>{t('help.contactSupportTitle')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="flex items-center gap-2 text-sm text-gray-700">
                <Phone className="h-4 w-4 text-gray-400" /> {t('help.tollFree')}
              </p>
              <p className="flex items-center gap-2 text-sm text-gray-700">
                <Mail className="h-4 w-4 text-gray-400" /> support@onedesk.maharashtra.gov.in
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>{t('help.resourcesTitle')}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <p className="flex items-center gap-2 text-sm text-gray-700">
                <FileText className="h-4 w-4 text-gray-400" /> {t('help.userGuide')}
              </p>
              <p className="flex items-center gap-2 text-sm text-gray-700">
                <ShieldCheck className="h-4 w-4 text-gray-400" /> {t('help.privacyPolicy')}
              </p>
              <p className="flex items-center gap-2 text-sm text-gray-700">
                <Building2 className="h-4 w-4 text-gray-400" /> {t('help.departmentDirectory')}
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
