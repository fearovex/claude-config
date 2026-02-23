---
name: react-19
description: >
  React 19 patterns with React Compiler. Optimización automática, Server Components, use() hook.
  Trigger: When building React components, using hooks, working with forms, or server/client components.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: writing React components, using hooks, handling forms, working with Server/Client components, or migrating from React 18.

## Critical Patterns

### Pattern 1: React Compiler — Sin memoización manual

```typescript
// ✅ React Compiler lo optimiza automáticamente
function ExpensiveComponent({ data }: { data: number[] }) {
  const result = data.reduce((acc, n) => acc + n, 0); // Compiler lo memoiza
  return <div>{result}</div>;
}

// ❌ Innecesario en React 19 con Compiler activado
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

### Pattern 3: Server Components por defecto

```typescript
// ✅ Server Component (default — no directive needed)
async function UserProfile({ userId }: { userId: string }) {
  const user = await db.users.findById(userId); // Direct DB access
  return <div>{user.name}</div>;
}

// ✅ Client Component — solo cuando necesitas interactividad
'use client';
function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

## Code Examples

### use() hook — Promises y Context condicional

```typescript
'use client';
import { use, Suspense } from 'react';

// Leer promise en render
function UserData({ promise }: { promise: Promise<User> }) {
  const user = use(promise); // Suspende hasta que se resuelve
  return <div>{user.name}</div>;
}

// Uso con Suspense
function App() {
  const userPromise = fetchUser(userId);
  return (
    <Suspense fallback={<Skeleton />}>
      <UserData promise={userPromise} />
    </Suspense>
  );
}

// Context condicional (imposible con useContext)
function ConditionalTheme({ show }: { show: boolean }) {
  if (!show) return null;
  const theme = use(ThemeContext); // ✅ uso condicional OK
  return <div style={{ color: theme.primary }}>themed</div>;
}
```

### Server Actions con useActionState

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

### ref como prop (sin forwardRef)

```typescript
// ✅ React 19 — ref es prop estándar
function Input({ ref, ...props }: React.InputHTMLAttributes<HTMLInputElement> & {
  ref?: React.Ref<HTMLInputElement>
}) {
  return <input ref={ref} {...props} />;
}

// ❌ Ya no necesario
const Input = forwardRef<HTMLInputElement, Props>((props, ref) => (
  <input ref={ref} {...props} />
));
```

### Data Fetching paralelo

```typescript
// ✅ Server Component con fetching paralelo
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

### ❌ useMemo/useCallback innecesario (con Compiler)

```typescript
// ❌ Redundante con React Compiler
const value = useMemo(() => compute(data), [data]);
const handler = useCallback(() => doThing(id), [id]);

// ✅ Simple y directo
const value = compute(data);
const handler = () => doThing(id);
```

### ❌ 'use client' en exceso

```typescript
// ❌ Hace todo el árbol client-side
'use client';
export default function Page() { /* ... */ }

// ✅ Solo el componente interactivo
// page.tsx (Server Component)
export default function Page() {
  return (
    <div>
      <StaticContent />
      <InteractiveWidget /> {/* 'use client' solo aquí */}
    </div>
  );
}
```

## Quick Reference

| Feature | React 18 | React 19 |
|---------|----------|----------|
| Memoización | Manual useMemo/useCallback | Automática (Compiler) |
| Promesas | useEffect + useState | use() hook |
| Formularios | onSubmit handler | Server Actions + useActionState |
| Refs en componentes | forwardRef | ref como prop |
| Context condicional | ❌ No posible | ✅ use() |
