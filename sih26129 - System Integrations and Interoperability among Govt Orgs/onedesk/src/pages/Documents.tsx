import { FileText } from 'lucide-react'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Card, CardContent } from '@/components/ui/Card'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { citizenDocuments } from '@/data/documents'
import { formatDate } from '@/lib/utils'

export default function Documents() {
  return (
    <div>
      <PageHeader
        title="My Documents"
        subtitle="Documents linked to your profile from connected departments — reused automatically across applications."
      />

      <Card>
        <CardContent className="px-0 pb-0">
          <Table>
            <THead>
              <TR>
                <TH>Document</TH>
                <TH>Issued By</TH>
                <TH>Status</TH>
                <TH>Issued On</TH>
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
                </TR>
              ))}
            </TBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
