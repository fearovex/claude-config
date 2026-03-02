---
name: ai-sdk-5
description: >
  Vercel AI SDK 5 patterns: useChat, streaming, tool integration, Server Actions.
  Trigger: When building AI chat interfaces, using Vercel AI SDK, streaming LLM responses, or integrating tools.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When building AI chat interfaces, using Vercel AI SDK, streaming LLM responses, or integrating tools.

Load when: building AI chat with Vercel AI SDK 5, streaming responses, integrating tools/function calling, or migrating from AI SDK 4.

## Critical Breaking Changes from v4

```typescript
// ✅ v5 — import from @ai-sdk/react
import { useChat } from '@ai-sdk/react';

// ❌ v4 (no longer valid as before)
import { useChat } from 'ai/react';

// ✅ v5 — Transport-based architecture
import { DefaultChatTransport } from '@ai-sdk/react';

// ✅ v5 — message.parts (array) instead of message.content (string)
message.parts // array of parts: text, image, tool interactions

// ✅ v5 — sendMessage() instead of handleSubmit()
const { sendMessage } = useChat(...);
```

## Code Examples

### Basic chat with useChat

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

### Server Route with streaming

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

### Tool Integration with Zod

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
          // Actual call to weather API
          const weather = await fetchWeather(location, unit);
          return { temperature: weather.temp, condition: weather.condition };
        },
      }),
    },
  });

  return result.toDataStreamResponse();
}
```

### Render message parts (text + tools)

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

### useCompletion for simple text

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

// In the render
{error && <div className="error">{error.message}</div>}
```

## Anti-Patterns

### ❌ Access message.content (v4 pattern)

```typescript
// ❌ v4 — no longer a direct string
<p>{message.content}</p>

// ✅ v5 — iterate over parts
{message.parts.map((part, i) => (
  part.type === 'text' ? <p key={i}>{part.text}</p> : null
))}
```

### ❌ handleSubmit without sendMessage

```typescript
// ❌ v4 pattern
<form onSubmit={handleSubmit}>

// ✅ v5 pattern
<button onClick={() => sendMessage({ text: input })}>
```

## Quick Reference

| Task | v5 Pattern |
|------|-----------|
| Import useChat | `from '@ai-sdk/react'` |
| Configure transport | `new DefaultChatTransport({ api: '/api/chat' })` |
| Send message | `sendMessage({ text: input })` |
| Read text | `message.parts.filter(p => p.type === 'text')` |
| Streaming state | `status === 'streaming'` |
| Tool calling | `tool({ description, parameters: z.object(...), execute })` |
| Simple text | `useCompletion({ api: '/api/...' })` |
| Server route | `streamText(...).toDataStreamResponse()` |

## Rules

- This skill targets AI SDK v5 only — patterns are breaking changes from v4 (`useChat` import path, `message.parts`, `sendMessage`); do NOT mix v4 syntax
- Always use `message.parts` array iteration to render message content; never access `message.content` as a string
- Tool definitions require a Zod schema for `parameters`; untyped tool calls are not supported in v5
- Server routes must return `result.toDataStreamResponse()` for streaming to work with `useChat` transport
- Handle `error` state from `useChat` explicitly in the UI; never silently swallow streaming errors
