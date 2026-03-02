---
name: nextjs-15
description: >
  Next.js 15 App Router patterns: Server Components, Server Actions, data fetching, middleware.
  Trigger: When building Next.js apps, working with app router, server/client components, or API routes.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When building Next.js apps, working with app router, server/client components, or API routes.

Load when: building Next.js 15 apps, using app router, implementing server actions, fetching data, or setting up middleware.

## Critical Patterns

### Pattern 1: Server Components by default

```typescript
// ✅ Server Component — async by default, no directive needed
async function UserProfile({ userId }: { userId: string }) {
  const user = await db.users.findById(userId); // Direct DB access
  return <ProfileCard user={user} />;
}

// ✅ Client Component — only when you need interactivity
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

// Direct usage in form
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

### Pattern 3: Prevent client-side access with server-only

```typescript
// lib/db.ts
import 'server-only'; // Build error if imported in client

export async function getSecretData() {
  return db.secrets.findAll();
}
```

## Code Examples

### Data Fetching — Parallel and Streaming

```typescript
// ✅ Parallel fetching in Server Component
async function Dashboard() {
  const [user, posts, stats] = await Promise.all([
    getUser(),
    getPosts(),
    getStats(),
  ]);
  return <DashboardView user={user} posts={posts} stats={stats} />;
}

// ✅ Streaming with Suspense
import { Suspense } from 'react';

export default function Page() {
  return (
    <div>
      <Header /> {/* Immediate */}
      <Suspense fallback={<PostsSkeleton />}>
        <Posts /> {/* Streams when ready */}
      </Suspense>
    </div>
  );
}

async function Posts() {
  const posts = await getPosts(); // Waits here
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

### Metadata — Static and Dynamic

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

### Route Groups and Layouts

```
app/
├── (auth)/              # Group with no URL impact
│   ├── layout.tsx       # Layout only for auth pages
│   ├── login/page.tsx   # /login
│   └── register/page.tsx # /register
├── (dashboard)/
│   ├── layout.tsx       # Dashboard layout
│   └── overview/page.tsx # /overview
├── _components/         # Private folder (not a route)
├── layout.tsx           # Root layout (required)
└── page.tsx             # /
```

## Anti-Patterns

### ❌ Fetch in Client Component when it could be Server

```typescript
// ❌ Unnecessary
'use client';
function UserList() {
  const [users, setUsers] = useState([]);
  useEffect(() => {
    fetch('/api/users').then(r => r.json()).then(setUsers);
  }, []);
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}

// ✅ Direct Server Component
async function UserList() {
  const users = await db.users.findMany();
  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

### ❌ 'use client' in layout or page

```typescript
// ❌ Makes the entire tree client-side
'use client';
export default function Layout({ children }) { /* ... */ }

// ✅ Isolate the client component
export default function Layout({ children }) {
  return <div><NavBar />{children}</div>; // NavBar can be 'use client'
}
```

## Quick Reference

| Task | Pattern |
|------|---------|
| DB in component | Server Component + async/await |
| Form | `<form action={serverAction}>` |
| Invalidate cache | `revalidatePath('/path')` |
| Redirect | `redirect('/path')` (server-only import) |
| URL params | `{ params }: { params: { id: string } }` |
| Search params | `searchParams.get('key')` in Server Component |
| Protect routes | `middleware.ts` at root |
| Prevent client bundle | `import 'server-only'` |

## Rules

- Server Components are the default; add `'use client'` only when the component requires browser APIs, event handlers, or React state
- Never add `'use client'` to layout or page files — this forces the entire subtree client-side and defeats Server Component benefits
- Server Actions (`'use server'`) must be the mechanism for mutations from forms; avoid client-side fetch for form submissions
- `revalidatePath` or `revalidateTag` must be called after mutations that change cached data; stale caches are a correctness bug
- `import 'server-only'` must be added to any module that accesses secrets, databases, or server-only APIs to prevent accidental client bundling
