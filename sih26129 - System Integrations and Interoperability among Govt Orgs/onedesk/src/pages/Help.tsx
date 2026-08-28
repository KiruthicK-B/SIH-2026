import { Building2, FileText, Mail, Phone, ShieldCheck } from 'lucide-react'
import { PageHeader } from '@/components/shared/PageHeader'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card'

const faqs = [
  {
    question: 'Why do I only need to enter my information once?',
    answer:
      'OneDesk securely fetches verified data you have already provided to one department — like your income certificate or academic records — when another department needs it, with your consent.',
  },
  {
    question: 'Can a department access my data without my permission?',
    answer:
      'No. Every cross-department data request requires your explicit, purpose-bound consent, which you can review and revoke anytime from My Consents.',
  },
  {
    question: 'How do I track an application that involves multiple departments?',
    answer:
      'Open My Applications and select the application. The timeline shows every step across every department involved, in one place.',
  },
  {
    question: 'What happens if a department system is temporarily unavailable?',
    answer:
      'Your application continues to progress on any steps that do not depend on that department. You will be notified once the affected step resumes.',
  },
]

export default function Help() {
  return (
    <div>
      <PageHeader title="Help & Support" subtitle="Answers to common questions, and ways to reach us." />

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
              <CardTitle>Contact Support</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="flex items-center gap-2 text-sm text-gray-700">
                <Phone className="h-4 w-4 text-gray-400" /> 1800-120-4567 (Toll Free)
              </p>
              <p className="flex items-center gap-2 text-sm text-gray-700">
                <Mail className="h-4 w-4 text-gray-400" /> support@onedesk.maharashtra.gov.in
              </p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Resources</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <p className="flex items-center gap-2 text-sm text-gray-700">
                <FileText className="h-4 w-4 text-gray-400" /> Application user guide
              </p>
              <p className="flex items-center gap-2 text-sm text-gray-700">
                <ShieldCheck className="h-4 w-4 text-gray-400" /> Consent & data privacy policy
              </p>
              <p className="flex items-center gap-2 text-sm text-gray-700">
                <Building2 className="h-4 w-4 text-gray-400" /> Directory of connected departments
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
