import { AppShell } from '@/components/AppShell'
import { ChatInterface } from '@/components/ChatInterface'
import { Card } from '@/components/ui/Card'

export default function ChatPage() {
  return (
    <AppShell>
      <div className="mb-4">
        <h1 className="text-lg font-bold text-white">Chat with ORCA</h1>
        <p className="text-xs text-slate-400">
          Ask about potential fishing zones, safety conditions, hazards, or ocean data — ORCA remembers context across
          follow-up questions.
        </p>
      </div>
      <Card className="h-[calc(100vh-160px)] overflow-hidden">
        <ChatInterface />
      </Card>
    </AppShell>
  )
}
