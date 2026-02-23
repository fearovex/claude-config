---
name: ai-sdk-5
description: >
  Vercel AI SDK 5 patterns: useChat, streaming, tool integration, Server Actions.
  Trigger: When building AI chat interfaces, using Vercel AI SDK, streaming LLM responses, or integrating tools.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: building AI chat with Vercel AI SDK 5, streaming responses, integrating tools/function calling, or migrating from AI SDK 4.

## Critical Breaking Changes desde v4

```typescript
// ✅ v5 — import desde @ai-sdk/react
import { useChat } from '@ai-sdk/react';

// ❌ v4 (ya no válido como antes)
import { useChat } from 'ai/react';

// ✅ v5 — Transport-based architecture
import { DefaultChatTransport } from '@ai-sdk/react';

// ✅ v5 — message.parts (array) en vez de message.content (string)
message.parts // array de partes: text, image, tool interactions

// ✅ v5 — sendMessage() en vez de handleSubmit()
const { sendMessage } = useChat(...);
```

## Code Examples

### Chat básico con useChat

```typescript
'use client';
import { useChat } from '@ai-sdk/react';
import { DefaultChatTransport } from '@ai-sdk/react';
import { useState } from 'react';

export function ChatInterface() {
  const [input, setInput] = useState('');

  const { messages, sendMessage, status } = useChat({
    transport: new DefaultChatTransport({ api: '/api/chat' }),
  });

  const handleSend = () => {
    if (!input.trim()) return;
    sendMessage({ text: input });
    setInput('');
  };

  return (
    <div>
      <div>
        {messages.map((message) => (
          <div key={message.id} data-role={message.role}>
            {message.parts.map((part, i) => {
              if (part.type === 'text') return <p key={i}>{part.text}</p>;
              return null;
            })}
          </div>
        ))}
      </div>
      <input
        value={input}
        onChange={(e) => setInput(e.target.value)}
        onKeyDown={(e) => e.key === 'Enter' && handleSend()}
      />
      <button onClick={handleSend} disabled={status === 'streaming'}>
        {status === 'streaming' ? 'Thinking...' : 'Send'}
      </button>
    </div>
  );
}
```

### Server Route con streaming

```typescript
// app/api/chat/route.ts
import { streamText } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';

export async function POST(request: Request) {
  const { messages } = await request.json();

  const result = streamText({
    model: anthropic('claude-sonnet-4-6'),
    system: 'You are a helpful assistant.',
    messages,
  });

  return result.toDataStreamResponse();
}
```

### Tool Integration con Zod

```typescript
import { streamText, tool } from 'ai';
import { z } from 'zod';
import { anthropic } from '@ai-sdk/anthropic';

export async function POST(request: Request) {
  const { messages } = await request.json();

  const result = streamText({
    model: anthropic('claude-sonnet-4-6'),
    messages,
    tools: {
      getWeather: tool({
        description: 'Get the current weather for a location',
        parameters: z.object({
          location: z.string().describe('City name'),
          unit: z.enum(['celsius', 'fahrenheit']).default('celsius'),
        }),
        execute: async ({ location, unit }) => {
          // Llamada real a API de weather
          const weather = await fetchWeather(location, unit);
          return { temperature: weather.temp, condition: weather.condition };
        },
      }),
    },
  });

  return result.toDataStreamResponse();
}
```

### Renderizar partes del mensaje (texto + tools)

```typescript
function MessageRenderer({ message }: { message: Message }) {
  return (
    <div>
      {message.parts.map((part, i) => {
        switch (part.type) {
          case 'text':
            return <p key={i}>{part.text}</p>;

          case 'tool-invocation':
            return (
              <div key={i} className="tool-call">
                <span>Calling: {part.toolName}</span>
                {part.state === 'result' && (
                  <pre>{JSON.stringify(part.result, null, 2)}</pre>
                )}
              </div>
            );

          default:
            return null;
        }
      })}
    </div>
  );
}
```

### useCompletion para texto simple

```typescript
'use client';
import { useCompletion } from '@ai-sdk/react';

export function SummarizeButton({ text }: { text: string }) {
  const { completion, complete, isLoading } = useCompletion({
    api: '/api/summarize',
  });

  return (
    <div>
      <button
        onClick={() => complete(text)}
        disabled={isLoading}
      >
        {isLoading ? 'Summarizing...' : 'Summarize'}
      </button>
      {completion && <p>{completion}</p>}
    </div>
  );
}
```

### Error handling

```typescript
const { messages, sendMessage, error } = useChat({
  transport: new DefaultChatTransport({ api: '/api/chat' }),
  onError: (error) => {
    console.error('Chat error:', error);
    toast.error('Failed to send message');
  },
});

// En el render
{error && <div className="error">{error.message}</div>}
```

## Anti-Patterns

### ❌ Acceder a message.content (v4 pattern)

```typescript
// ❌ v4 — ya no es string directo
<p>{message.content}</p>

// ✅ v5 — iterar sobre parts
{message.parts.map((part, i) => (
  part.type === 'text' ? <p key={i}>{part.text}</p> : null
))}
```

### ❌ handleSubmit sin sendMessage

```typescript
// ❌ v4 pattern
<form onSubmit={handleSubmit}>

// ✅ v5 pattern
<button onClick={() => sendMessage({ text: input })}>
```

## Quick Reference

| Task | Patrón v5 |
|------|-----------|
| Import useChat | `from '@ai-sdk/react'` |
| Configurar transport | `new DefaultChatTransport({ api: '/api/chat' })` |
| Enviar mensaje | `sendMessage({ text: input })` |
| Leer texto | `message.parts.filter(p => p.type === 'text')` |
| Estado streaming | `status === 'streaming'` |
| Tool calling | `tool({ description, parameters: z.object(...), execute })` |
| Texto simple | `useCompletion({ api: '/api/...' })` |
| Server route | `streamText(...).toDataStreamResponse()` |
