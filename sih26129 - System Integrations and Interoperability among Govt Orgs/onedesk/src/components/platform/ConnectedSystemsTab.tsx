import { Card, CardContent } from '@/components/ui/Card'
import { TBody, TD, TH, THead, TR, Table } from '@/components/ui/Table'
import { departments } from '@/data/departments'
import { formatDateTime } from '@/lib/utils'

export function ConnectedSystemsTab() {
  return (
    <Card>
      <CardContent className="px-0 pb-0 pt-0">
        <Table>
          <THead>
            <TR>
              <TH>System / Department</TH>
              <TH>Technology</TH>
              <TH>Status</TH>
              <TH>Last Synchronization</TH>
            </TR>
          </THead>
          <TBody>
            {departments.map((d) => (
              <TR key={d.id}>
                <TD className="font-medium text-gray-900">{d.name}</TD>
                <TD>{d.interfaceType}</TD>
                <TD>
                  <span className="flex items-center gap-1.5 text-xs font-medium text-success-600">
                    <span className="h-1.5 w-1.5 rounded-full bg-success-600" /> Healthy
                  </span>
                </TD>
                <TD className="text-gray-500">{formatDateTime(d.lastSyncedAt)}</TD>
              </TR>
            ))}
          </TBody>
        </Table>
      </CardContent>
    </Card>
  )
}
