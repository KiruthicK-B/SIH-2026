import { Download, FileText } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent } from '@/components/ui/Card'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import type { CitizenDocument } from '@/data/documents'
import { api } from '@/lib/api'
import { formatDate } from '@/lib/utils'

export default function Documents() {
  const { t } = useTranslation()
  const [citizenDocuments, setCitizenDocuments] = useState<CitizenDocument[]>([])

  useEffect(() => {
    api.get<CitizenDocument[]>('/documents').then(setCitizenDocuments)
  }, [])

  const download = async (doc: CitizenDocument) => {
    const blob = await api.getBlob(`/documents/${doc.id}/file`)
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = doc.name
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div>
      <PageHeader title={t('documents.title')} subtitle={t('documents.subtitle')} />

      <Card>
        <CardContent className="px-0 pb-0">
          <Table>
            <THead>
              <TR>
                <TH>{t('documents.colDocument')}</TH>
                <TH>{t('documents.colIssuedBy')}</TH>
                <TH>{t('documents.colStatus')}</TH>
                <TH>{t('documents.colIssuedOn')}</TH>
                <TH></TH>
              </TR>
            </THead>
            <TBody>
              {citizenDocuments.map((doc) => (
                <TR key={doc.id}>
                  <TD className="flex items-center gap-2 font-medium text-gray-900">
                    <FileText className="h-4 w-4 text-gray-400" /> {doc.name}
                  </TD>
                  <TD>{doc.issuedBy}</TD>
                  <TD>
                    <StatusBadge status={doc.status} />
                  </TD>
                  <TD className="text-gray-500">{formatDate(doc.issuedOn)}</TD>
                  <TD>
                    {doc.hasFile && (
                      <button
                        onClick={() => void download(doc)}
                        className="flex items-center gap-1 text-xs font-medium text-brand-600 hover:text-brand-700"
                      >
                        <Download className="h-3.5 w-3.5" /> {t('documents.download')}
                      </button>
                    )}
                  </TD>
                </TR>
              ))}
            </TBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
