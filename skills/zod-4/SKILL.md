---
name: zod-4
description: >
  Zod 4 schema validation patterns. Breaking changes from v3, modern validators, form integration.
  Trigger: When validating data, defining schemas, working with forms, or using Zod for type safety.
license: Apache-2.0
metadata:
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When validating data, defining schemas, working with forms, or using Zod for type safety.

Load when: validating user input, defining data schemas, working with React Hook Form + Zod, or migrating from Zod 3.

## Critical Patterns — Breaking Changes from v3

```typescript
// ✅ Zod 4 — top-level validators
const emailSchema = z.email();
const urlSchema = z.url();
const uuidSchema = z.uuid();

// ❌ Zod 3 (no longer works the same way)
const emailSchema = z.string().email();

// ✅ Zod 4 — min(1) instead of nonempty()
const nameSchema = z.string().min(1);

// ❌ Zod 3
const nameSchema = z.string().nonempty();

// ✅ Zod 4 — unified error
const schema = z.object({
  name: z.string({ error: 'Name is required' }),
});

// ❌ Zod 3
const schema = z.object({
  name: z.string({ required_error: 'Name is required' }),
});
```

## Code Examples

### Basic schemas

```typescript
import { z } from 'zod';

// Primitives
const nameSchema = z.string().min(1).max(100);
const ageSchema = z.number().int().min(0).max(150);
const activeSchema = z.boolean();
const dateSchema = z.date();

// Zod 4 specials
const emailSchema = z.email();
const urlSchema = z.url();
const uuidSchema = z.uuid();

// Object with type inference
const UserSchema = z.object({
  id: z.uuid(),
  name: z.string().min(1),
  email: z.email(),
  age: z.number().int().min(18).optional(),
  role: z.enum(['admin', 'user', 'guest']),
  createdAt: z.date(),
});

type User = z.infer<typeof UserSchema>;
```

### Parse vs SafeParse

```typescript
// parse() — throws ZodError on failure
try {
  const user = UserSchema.parse(data);
  // user is typed as User
} catch (error) {
  if (error instanceof z.ZodError) {
    console.log(error.errors);
  }
}

// safeParse() — returns result without throwing
const result = UserSchema.safeParse(data);
if (result.success) {
  const user = result.data; // typed as User
} else {
  const errors = result.error.errors;
  errors.forEach(e => console.log(e.path, e.message));
}
```

### Arrays, Records, Tuples

```typescript
// Array
const TagsSchema = z.array(z.string()).min(1).max(10);

// Record
const MetaSchema = z.record(z.string(), z.string());

// Tuple
const CoordSchema = z.tuple([z.number(), z.number()]);

// Discriminated Union
const EventSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('click'), x: z.number(), y: z.number() }),
  z.object({ type: z.literal('keypress'), key: z.string() }),
]);
```

### Transformations and Refinements

```typescript
// Transform — parse and transform
const DateStringSchema = z.string().transform((val) => new Date(val));

// Refine — custom validation
const PasswordSchema = z.string()
  .min(8)
  .refine(
    (val) => /[A-Z]/.test(val),
    { message: 'Must contain uppercase letter' }
  )
  .refine(
    (val) => /[0-9]/.test(val),
    { message: 'Must contain a number' }
  );

// superRefine — cross-field validation
const PasswordMatchSchema = z.object({
  password: z.string().min(8),
  confirmPassword: z.string(),
}).superRefine((data, ctx) => {
  if (data.password !== data.confirmPassword) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: 'Passwords must match',
      path: ['confirmPassword'],
    });
  }
});
```

### Integration with React Hook Form

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const LoginSchema = z.object({
  email: z.email(),
  password: z.string().min(8),
});

type LoginForm = z.infer<typeof LoginSchema>;

function LoginForm() {
  const { register, handleSubmit, formState: { errors } } = useForm<LoginForm>({
    resolver: zodResolver(LoginSchema),
  });

  const onSubmit = (data: LoginForm) => {
    console.log(data); // Typed and validated
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <p>{errors.email.message}</p>}

      <input type="password" {...register('password')} />
      {errors.password && <p>{errors.password.message}</p>}

      <button type="submit">Login</button>
    </form>
  );
}
```

### Schemas for API (input/output)

```typescript
// Schema to validate request body
const CreateUserInput = z.object({
  name: z.string().min(1).max(100),
  email: z.email(),
  role: z.enum(['admin', 'user']).default('user'),
});

// Schema for response (omits sensitive fields)
const UserResponse = z.object({
  id: z.uuid(),
  name: z.string(),
  email: z.email(),
  role: z.string(),
  createdAt: z.date(),
});

type CreateUserInput = z.infer<typeof CreateUserInput>;
type UserResponse = z.infer<typeof UserResponse>;
```

## Anti-Patterns

### ❌ Parse without error handling

```typescript
// ❌ Crashes on failure
const user = UserSchema.parse(untrustedData);

// ✅ Safe parse or try/catch
const result = UserSchema.safeParse(untrustedData);
if (!result.success) handleErrors(result.error);
```

### ❌ Using any instead of inferring

```typescript
// ❌
function createUser(data: any) { ... }

// ✅
type CreateUserInput = z.infer<typeof CreateUserSchema>;
function createUser(data: CreateUserInput) { ... }
```

## Quick Reference

| Task | Zod 4 Pattern |
|------|---------------|
| Email | `z.email()` |
| URL | `z.url()` |
| UUID | `z.uuid()` |
| Non-empty string | `z.string().min(1)` |
| Custom error | `z.string({ error: 'msg' })` |
| Infer type | `z.infer<typeof Schema>` |
| Safe parse | `Schema.safeParse(data)` |
| Cross-field validation | `.superRefine()` |
| With RHF | `zodResolver(Schema)` |

## Rules

- This skill targets Zod v4 specifically — `z.string().email()` and other validators changed in v4; verify the installed version before applying patterns
- Define schemas as named constants, not inline — reusing schema definitions ensures consistency between validation and TypeScript type inference
- Use `z.infer<typeof Schema>` to derive TypeScript types from schemas; manually duplicating types alongside schemas causes drift
- `safeParse` is required for user input validation — `parse` throws by default and must only be used when an exception is the correct error handling strategy
- Zod schemas for form validation must be defined outside the component to avoid recreation on every render
