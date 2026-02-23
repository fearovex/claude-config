---
name: nextjs-15
description: >
  Next.js 15 App Router patterns: Server Components, Server Actions, data fetching, middleware.
  Trigger: When building Next.js apps, working with app router, server/client components, or API routes.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: building Next.js 15 apps, using app router, implementing server actions, fetching data, or setting up middleware.

## Critical Patterns

### Pattern 1: Server Components por defecto

```typescript
// ✅ Server Component — async por defecto, sin directiva
async function UserProfile({ userId }: { userId: string }) {
  const user = await db.users.findById(userId); // DB directo
  return <ProfileCard user={user} />;
}

// ✅ Client Component — solo cuando necesitas interactividad
'use client';
function LikeButton({ postId }: { postId: string }) {
  const [liked, setLiked] = useState(false);
  return <button onClick={() => setLiked(!liked)}>{liked ? '❤️' : '🤍'}</button>;
}
```

### Pattern 2: Server Actions

```typescript
'use server';
import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

async function createUser(formData: FormData) {
  const name = formData.get('name') as string;
  const email = formData.get('email') as string;

  await db.users.create({ name, email });
  revalidatePath('/users');
  redirect('/users');
}

// Uso directo en form
export default function CreateUserPage() {
  return (
    <form action={createUser}>
      <input name="name" required />
      <input name="email" type="email" required />
      <button type="submit">Create</button>
    </form>
  );
}
```

### Pattern 3: Prevenir acceso client-side con server-only

```typescript
// lib/db.ts
import 'server-only'; // Error en build si se importa en client

export async function getSecretData() {
  return db.secrets.findAll();
}
```

## Code Examples

### Data Fetching — Parallel y Streaming

```typescript
// ✅ Fetching paralelo en Server Component
async function Dashboard() {
  const [user, posts, stats] = await Promise.all([
    getUser(),
    getPosts(),
    getStats(),
  ]);
  return <DashboardView user={user} posts={posts} stats={stats} />;
}

// ✅ Streaming con Suspense
import { Suspense } from 'react';

export default function Page() {
  return (
    <div>
      <Header /> {/* Inmediato */}
      <Suspense fallback={<PostsSkeleton />}>
        <Posts /> {/* Streaming cuando esté listo */}
      </Suspense>
    </div>
  );
}

async function Posts() {
  const posts = await getPosts(); // Se espera aquí
  return <PostList posts={posts} />;
}
```

### API Route Handler

```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const page = searchParams.get('page') ?? '1';

  const users = await db.users.findMany({ page: parseInt(page) });
  return NextResponse.json(users);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const user = await db.users.create(body);
  return NextResponse.json(user, { status: 201 });
}
```

### Middleware — Route Protection

```typescript
// middleware.ts
import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('token')?.value;
  const isProtected = request.nextUrl.pathname.startsWith('/dashboard');

  if (isProtected && !token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/admin/:path*'],
};
```

### Metadata — Static y Dynamic

```typescript
// Static
export const metadata = {
  title: 'My App',
  description: 'App description',
};

// Dynamic
export async function generateMetadata({ params }: { params: { id: string } }) {
  const post = await getPost(params.id);
  return {
    title: post.title,
    description: post.excerpt,
    openGraph: { images: [post.coverImage] },
  };
}
```

### Route Groups y Layouts

```
app/
├── (auth)/              # Group sin impacto en URL
│   ├── layout.tsx       # Layout solo para auth pages
│   ├── login/page.tsx   # /login
│   └── register/page.tsx # /register
├── (dashboard)/
│   ├── layout.tsx       # Layout del dashboard
│   └── overview/page.tsx # /overview
├── _components/         # Carpeta privada (no es ruta)
├── layout.tsx           # Root layout (requerido)
└── page.tsx             # /
```

## Anti-Patterns

### ❌ Fetch en Client Component cuando podría ser Server

```typescript
// ❌ Innecesario
'use client';
function UserList() {
  const [users, setUsers] = useState([]);
  useEffect(() => {
    fetch('/api/users').then(r => r.json()).then(setUsers);
  }, []);
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}

// ✅ Server Component directo
async function UserList() {
  const users = await db.users.findMany();
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

### ❌ 'use client' en layout o page

```typescript
// ❌ Hace todo el árbol client-side
'use client';
export default function Layout({ children }) { /* ... */ }

// ✅ Aisla el client component
export default function Layout({ children }) {
  return <div><NavBar />{children}</div>; // NavBar puede ser 'use client'
}
```

## Quick Reference

| Task | Patrón |
|------|--------|
| DB en componente | Server Component + async/await |
| Formulario | `<form action={serverAction}>` |
| Invalidar caché | `revalidatePath('/ruta')` |
| Redirigir | `redirect('/ruta')` (server-only import) |
| Params de URL | `{ params }: { params: { id: string } }` |
| Search params | `searchParams.get('key')` en Server Component |
| Proteger rutas | `middleware.ts` en raíz |
| Evitar bundle client | `import 'server-only'` |
