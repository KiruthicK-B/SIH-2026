import type { ChatAttachment, ChatMessage, LatLng } from '@/data/types'
import type { PlannerContext } from './PlannerAgent'

export interface ChatSession {
  messages: ChatMessage[]
  context: PlannerContext
}

let messageCounter = 0
function nextId() {
  messageCounter += 1
  return `msg-${Date.now()}-${messageCounter}`
}

export function createSession(): ChatSession {
  return {
    messages: [],
    context: { lastLocation: null, lastLocationName: null, lastDate: null },
  }
}

/** Manages multi-turn conversation state as pure, immutable transitions over a ChatSession —
 *  the React layer holds the session in state and calls these functions on each turn. */
export const ChatAgent = {
  appendUserMessage(session: ChatSession, text: string): ChatSession {
    const message: ChatMessage = { id: nextId(), role: 'user', text, timestamp: new Date().toISOString() }
    return { ...session, messages: [...session.messages, message] }
  },

  appendAssistantMessage(session: ChatSession, text: string, attachment?: ChatAttachment, needsClarification?: boolean): ChatSession {
    const message: ChatMessage = {
      id: nextId(),
      role: 'assistant',
      text,
      timestamp: new Date().toISOString(),
      attachment,
      needsClarification,
    }
    return { ...session, messages: [...session.messages, message] }
  },

  updateContext(session: ChatSession, location: LatLng | null, locationName: string | null, date: string): ChatSession {
    return { ...session, context: { lastLocation: location, lastLocationName: locationName, lastDate: date } }
  },

  getContext(session: ChatSession): PlannerContext {
    return session.context
  },
}
