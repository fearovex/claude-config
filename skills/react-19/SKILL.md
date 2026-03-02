---
name: react-19
description: >
  React 19 patterns with React Compiler. Automatic optimization, Server Components, use() hook.
  Trigger: When building React components, using hooks, working with forms, or server/client components.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When building React components, using hooks, working with forms, or server/client components.

Load when: writing React components, using hooks, handling forms, working with Server/Client components, or migrating from React 18.

## Critical Patterns

### Pattern 1: React Compiler — No manual memoization

```typescript
// ✅ React Compiler optimizes this automatically
function ExpensiveComponent({ data }: { data: number[] }) {
  const result = data.reduce((acc, n) => acc + n, 0); // Compiler memoizes it
  return <div>{result}</div>;
}

// ❌ Unnecessary in React 19 with Compiler enabled
function ExpensiveComponent({ data }: { data: number[] }) {
  const result = useMemo(() => data.reduce((acc, n) => acc + n, 0), [data]);
  return <div>{result}</div>;
}
```

### Pattern 2: Named Imports

```typescript
// ✅ Always named imports
import { useState, useEffect, use, useActionState } from 'react';
import { Suspense } from 'react';

// ❌ Never default or namespace imports
import React from 'react';
import * as React from 'react';
```

### Pattern 3: Server Components by default

```typescript
// ✅ Server Component (default — no directive needed)
async function UserProfile({ userId }: { userId: string }) {
  const user = await db.users.findById(userId); // Direct DB access
  return <div>{user.name}</div>;
}

// ✅ Client Component — only when you need interactivity
'use client';
function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

## Code Examples

### use() hook — Promises and conditional Context

```typescript
'use client';
import { use, Suspense } from 'react';

// Read promise in render
function UserData({ promise }: { promise: Promise<User> }) {
  const user = use(promise); // Suspends until resolved
  return <div>{user.name}</div>;
}

// Usage with Suspense
function App() {
  const userPromise = fetchUser(userId);
  return (
    <Suspense fallback={<Skeleton />}>
      <UserData promise={userPromise} />
    </Suspense>
  );
}

// Conditional context (impossible with useContext)
function ConditionalTheme({ show }: { show: boolean }) {
  if (!show) return null;
  const theme = use(ThemeContext); // ✅ conditional usage OK
  return <div style={{ color: theme.primary }}>themed</div>;
}
```

### Server Actions with useActionState

```typescript
'use server';
async function createUser(prevState: State, formData: FormData) {
  const name = formData.get('name') as string;
  if (!name) return { error: 'Name required' };
  await db.users.create({ name });
  revalidatePath('/users');
  return { success: true };
}

// Client Component
'use client';
import { useActionState } from 'react';

function CreateUserForm() {
  const [state, action, isPending] = useActionState(createUser, null);
  return (
    <form action={action}>
      <input name="name" />
      <button disabled={isPending}>
        {isPending ? 'Creating...' : 'Create'}
      </button>
      {state?.error && <p>{state.error}</p>}
    </form>
  );
}
```

### ref as prop (without forwardRef)

```typescript
// ✅ React 19 — ref is a standard prop
function Input({ ref, ...props }: React.InputHTMLAttributes<HTMLInputElement> & {
  ref?: React.Ref<HTMLInputElement>
}) {
  return <input ref={ref} {...props} />;
}

// ❌ No longer needed
const Input = forwardRef<HTMLInputElement, Props>((props, ref) => (
  <input ref={ref} {...props} />
));
```

### Parallel Data Fetching

```typescript
// ✅ Server Component with parallel fetching
async function Dashboard() {
  const [user, posts, stats] = await Promise.all([
    fetchUser(),
    fetchPosts(),
    fetchStats(),
  ]);

  return (
    <div>
      <UserCard user={user} />
      <PostList posts={posts} />
      <StatsPanel stats={stats} />
    </div>
  );
}
```

## Anti-Patterns

### ❌ Unnecessary useMemo/useCallback (with Compiler)

```typescript
// ❌ Redundant with React Compiler
const value = useMemo(() => compute(data), [data]);
const handler = useCallback(() => doThing(id), [id]);

// ✅ Simple and direct
const value = compute(data);
const handler = () => doThing(id);
```

### ❌ Excessive 'use client'

```typescript
// ❌ Makes the entire tree client-side
'use client';
export default function Page() { /* ... */ }

// ✅ Only the interactive component
// page.tsx (Server Component)
export default function Page() {
  return (
    <div>
      <StaticContent />
      <InteractiveWidget /> {/* 'use client' only here */}
    </div>
  );
}
```

## Quick Reference

| Feature | React 18 | React 19 |
|---------|----------|----------|
| Memoization | Manual useMemo/useCallback | Automatic (Compiler) |
| Promises | useEffect + useState | use() hook |
| Forms | onSubmit handler | Server Actions + useActionState |
| Refs in components | forwardRef | ref as prop |
| Conditional context | ❌ Not possible | ✅ use() |

## Rules

- Do not add `useMemo` or `useCallback` when React Compiler is active — the compiler handles memoization automatically and manual wrapping is redundant
- `'use client'` must be applied at the lowest possible component in the tree; never mark a page or layout as a Client Component
- `forwardRef` is no longer needed — pass `ref` as a regular prop; using `forwardRef` in new React 19 code is unnecessary legacy syntax
- The `use()` hook can be called conditionally (unlike all other hooks); this is intentional and must be used instead of conditional `useContext` workarounds
- Server Actions must use `useActionState` for form state management; managing form submission state manually with `useState` + `useEffect` is the old pattern
