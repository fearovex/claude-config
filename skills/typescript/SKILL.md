---
name: typescript
description: >
  TypeScript strict patterns and best practices.
  Trigger: When writing TypeScript, defining types/interfaces, or using utility types.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: writing TypeScript code, defining data structures, working with generics, or needing type safety patterns.

## Critical Patterns

### Pattern 1: Const Types (single source of truth)

```typescript
// ✅ Create const object first, then extract type
const USER_ROLES = {
  ADMIN: 'admin',
  USER: 'user',
  GUEST: 'guest',
} as const;

type UserRole = typeof USER_ROLES[keyof typeof USER_ROLES];
// UserRole = 'admin' | 'user' | 'guest'

// ❌ Avoid: direct union types lose runtime values
type UserRole = 'admin' | 'user' | 'guest';
```

### Pattern 2: Flat Interfaces (one-level depth)

```typescript
// ✅ Flat, composable interfaces
interface Address {
  street: string;
  city: string;
  country: string;
}

interface User {
  id: string;
  name: string;
  address: Address; // Reference, not inline
}

interface Admin extends User {
  permissions: string[];
}

// ❌ Avoid: deeply nested inline types
interface User {
  address: {
    street: string;
    location: {
      city: string;
      coords: { lat: number; lng: number };
    };
  };
}
```

### Pattern 3: Avoid `any` — Use `unknown` or generics

```typescript
// ✅ Use unknown with type guard
function processData(data: unknown): string {
  if (typeof data === 'string') return data;
  if (typeof data === 'number') return data.toString();
  throw new Error('Unsupported type');
}

// ✅ Use generics for flexible typing
function getFirst<T>(arr: T[]): T | undefined {
  return arr[0];
}

// ❌ Avoid
function processData(data: any): any {
  return data.toString(); // No type safety
}
```

## Code Examples

### Utility Types

```typescript
interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  createdAt: Date;
}

// Pick specific fields
type UserPublic = Pick<User, 'id' | 'name' | 'email'>;

// Omit sensitive fields
type UserWithoutPassword = Omit<User, 'password'>;

// All fields optional (for updates)
type UserUpdate = Partial<User>;

// All fields required
type UserRequired = Required<User>;

// All fields readonly
type UserReadonly = Readonly<User>;

// Map of users
type UsersMap = Record<string, User>;

// Extract subset of union
type AdminOrUser = Extract<UserRole, 'admin' | 'user'>;

// Return type of function
type LoginResult = ReturnType<typeof loginUser>;

// Parameters of function
type LoginParams = Parameters<typeof loginUser>;
```

### Type Guards

```typescript
// ✅ Type guard with `is` syntax
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'name' in value
  );
}

// Discriminated union
type ApiResponse<T> =
  | { status: 'success'; data: T }
  | { status: 'error'; message: string };

function handleResponse<T>(response: ApiResponse<T>) {
  if (response.status === 'success') {
    console.log(response.data); // TypeScript knows data exists
  } else {
    console.error(response.message); // TypeScript knows message exists
  }
}
```

### Import Types

```typescript
// ✅ Use import type for type-only imports
import type { User, UserRole } from './types';
import type { FC, ReactNode } from 'react';

// Runtime imports
import { useState } from 'react';
import { createUser } from './services/user';
```

### Readonly and Immutability

```typescript
// ✅ Immutable data structures
const config: Readonly<{
  apiUrl: string;
  timeout: number;
}> = {
  apiUrl: 'https://api.example.com',
  timeout: 5000,
};

// Deep readonly
type DeepReadonly<T> = {
  readonly [K in keyof T]: T[K] extends object ? DeepReadonly<T[K]> : T[K];
};
```

## Anti-Patterns

### ❌ Using `any`

```typescript
// ❌ Bad
function parse(data: any) {
  return data.value; // No type safety
}

// ✅ Good
function parse(data: unknown): string {
  if (typeof data === 'object' && data !== null && 'value' in data) {
    return String((data as { value: unknown }).value);
  }
  throw new Error('Invalid data shape');
}
```

### ❌ Non-null assertion without guard

```typescript
// ❌ Bad - runtime crash if null
const user = getUser()!;
console.log(user.name);

// ✅ Good
const user = getUser();
if (!user) throw new Error('User not found');
console.log(user.name);
```

## Quick Reference

| Task | Pattern |
|------|---------|
| Union from object | `typeof OBJ[keyof typeof OBJ]` |
| Optional fields | `Partial<T>` |
| Pick fields | `Pick<T, 'a' \| 'b'>` |
| Exclude fields | `Omit<T, 'password'>` |
| Type guard | `value is Type` |
| Type-only import | `import type { T }` |
| Readonly | `Readonly<T>` or `as const` |
| Generic constraint | `<T extends object>` |
