import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import { Mic, Send, Trash2, Map as MapIcon } from 'lucide-react'
import { useOrcaChatContext } from '@/context/OrcaChatContext'
import { AlertsBanner } from './AlertsBanner'
import { ReasoningPanel } from './ReasoningPanel'
import { PFZBandBadge, SafetyBadge } from './ui/Badge'
import { formatTime, cn } from '@/lib/utils'

const SUGGESTIONS = [
  'Where is the nearest PFZ today from Chennai? Is it safe tomorrow morning?',
  'Are there any lightning or cyclone alerts near Visakhapatnam today?',
  'Which regions show high chlorophyll and favorable SST today?',
]

export function ChatInterface({ compact = false }: { compact?: boolean }) {
  const { messages, sendMessage, clearChat, thinking } = useOrcaChatContext()
  const [input, setInput] = useState('')
  const scrollRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: 'smooth' })
  }, [messages, thinking])

  function handleSend() {
    if (!input.trim()) return
    sendMessage(input)
    setInput('')
  }

  return (
    <div className="flex h-full flex-col">
      <div className="flex items-center justify-between border-b border-navy-600 px-4 py-3">
        <div className="flex items-center gap-2">
          <div className="flex h-7 w-7 items-center justify-center rounded-full bg-cyan-500/15 text-cyan-400">🐋</div>
          <p className="text-xs font-bold uppercase tracking-wide text-slate-300">Chat with ORCA</p>
        </div>
        <button onClick={clearChat} className="flex items-center gap-1 text-[11px] text-slate-400 hover:text-slate-200">
          <Trash2 className="h-3.5 w-3.5" /> Clear Chat
        </button>
      </div>

      <div ref={scrollRef} className="flex-1 space-y-4 overflow-y-auto px-4 py-4">
        {messages.map((m) => (
          <div key={m.id} className={cn('flex', m.role === 'user' ? 'justify-end' : 'justify-start')}>
            <div className={cn('max-w-[85%] rounded-xl px-3.5 py-2.5', m.role === 'user' ? 'bg-cyan-600 text-white' : 'bg-navy-700/70 text-slate-100')}>
              <p className="whitespace-pre-line text-sm leading-relaxed">{m.text}</p>

              {m.attachment && (
                <div className="mt-3 space-y-2.5">
                  {(m.attachment.pfzResult || m.attachment.safety) && (
                    <div className="flex flex-wrap items-center gap-2">
                      {m.attachment.pfzResult && <PFZBandBadge band={m.attachment.pfzResult.band} />}
                      {m.attachment.safety && <SafetyBadge category={m.attachment.safety.category} />}
                      {!compact && (
                        <Link to="/marine-map" className="flex items-center gap-1 text-[11px] font-medium text-cyan-300 hover:text-cyan-200">
                          <MapIcon className="h-3 w-3" /> View on map
                        </Link>
                      )}
                    </div>
                  )}

                  {m.attachment.alerts && m.attachment.alerts.length > 0 && <AlertsBanner alerts={m.attachment.alerts} compact />}

                  {m.attachment.explanation && <ReasoningPanel explanation={m.attachment.explanation} />}
                </div>
              )}

              <p className={cn('mt-1.5 text-[10px]', m.role === 'user' ? 'text-cyan-100/70' : 'text-slate-500')}>{formatTime(m.timestamp)}</p>
            </div>
          </div>
        ))}

        {thinking && (
          <div className="flex justify-start">
            <div className="flex items-center gap-1.5 rounded-xl bg-navy-700/70 px-3.5 py-2.5">
              <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-cyan-400" style={{ animationDelay: '0ms' }} />
              <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-cyan-400" style={{ animationDelay: '150ms' }} />
              <span className="h-1.5 w-1.5 animate-pulse-dot rounded-full bg-cyan-400" style={{ animationDelay: '300ms' }} />
            </div>
          </div>
        )}

        {messages.length <= 1 && (
          <div className="space-y-1.5 pt-2">
            {SUGGESTIONS.map((s) => (
              <button
                key={s}
                onClick={() => sendMessage(s)}
                className="block w-full rounded-lg border border-navy-600 bg-navy-800/40 px-3 py-2 text-left text-xs text-slate-300 hover:border-cyan-500/40 hover:text-cyan-200"
              >
                {s}
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="flex items-center gap-2 border-t border-navy-600 p-3">
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleSend()}
          placeholder="Type your message..."
          className="flex-1 rounded-lg border border-navy-600 bg-navy-900 px-3 py-2 text-sm text-slate-100 placeholder:text-slate-500 outline-none focus:border-cyan-500"
        />
        <button
          disabled
          title="Voice input is not available in this demo"
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg border border-navy-600 text-slate-500"
        >
          <Mic className="h-4 w-4" />
        </button>
        <button
          onClick={handleSend}
          className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-cyan-600 text-white hover:bg-cyan-500"
        >
          <Send className="h-4 w-4" />
        </button>
      </div>
    </div>
  )
}
