import { useCallback, useState } from 'react'
import { createSession, ChatAgent, type ChatSession } from '@/agents/ChatAgent'
import { runOrcaPipeline } from '@/agents/orcaPipeline'

const GREETING =
  "Hi, I'm ORCA. Ask me about potential fishing zones, safety conditions, or hazard alerts anywhere along the coast — for example, \"Where is the nearest PFZ today from Chennai? Is it safe tomorrow morning?\""

function withGreeting(session: ChatSession): ChatSession {
  return ChatAgent.appendAssistantMessage(session, GREETING)
}

export function useOrcaChat() {
  const [session, setSession] = useState<ChatSession>(() => withGreeting(createSession()))
  const [thinking, setThinking] = useState(false)

  const sendMessage = useCallback((text: string) => {
    const trimmed = text.trim()
    if (!trimmed) return
    setThinking(true)
    // Simulated latency so the "thinking" state is perceptible in the demo.
    setTimeout(() => {
      setSession((prev) => runOrcaPipeline(prev, trimmed))
      setThinking(false)
    }, 450)
  }, [])

  const clearChat = useCallback(() => {
    setSession(withGreeting(createSession()))
  }, [])

  return { messages: session.messages, sendMessage, clearChat, thinking }
}
