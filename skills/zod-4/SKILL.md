---
name: zod-4
description: >
  Zod 4 schema validation patterns. Breaking changes from v3, modern validators, form integration.
  Trigger: When validating data, defining schemas, working with forms, or using Zod for type safety.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: validating user input, defining data schemas, working with React Hook Form + Zod, or migrating from Zod 3.

## Critical Patterns — Breaking Changes desde v3

```typescript
// ✅ Zod 4 — top-level validators
const emailSchema = z.email();
const urlSchema = z.url();
const uuidSchema = z.uuid();

// ❌ Zod 3 (ya no funciona igual)
const emailSchema = z.string().email();

// ✅ Zod 4 — min(1) en lugar de nonempty()
const nameSchema = z.string().min(1);

// ❌ Zod 3
const nameSchema = z.string().nonempty();

// ✅ Zod 4 — error unificado
const schema = z.object({
  name: z.string({ error: 'Name is required' }),
});

// ❌ Zod 3
const schema = z.object({
  name: z.string({ required_error: 'Name is required' }),
});
```

## Code Examples

### Schemas básicos

```typescript
import { z } from 'zod';

// Primitivos
const nameSchema = z.string().min(1).max(100);
const ageSchema = z.number().int().min(0).max(150);
const activeSchema = z.boolean();
const dateSchema = z.date();

// Especiales Zod 4
const emailSchema = z.email();
const urlSchema = z.url();
const uuidSchema = z.uuid();

// Object con inferencia de tipo
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
// parse() — lanza ZodError si falla
try {
  const user = UserSchema.parse(data);
  // user está tipado como User
} catch (error) {
  if (error instanceof z.ZodError) {
    console.log(error.errors);
  }
}

// safeParse() — devuelve result sin lanzar
const result = UserSchema.safeParse(data);
if (result.success) {
  const user = result.data; // tipado como User
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

### Transformaciones y Refinements

```typescript
// Transform — parsear y transformar
const DateStringSchema = z.string().transform((val) => new Date(val));

// Refine — validación custom
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

// superRefine — validación cross-field
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

### Integración con React Hook Form

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
    console.log(data); // Tipado y validado
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

### Schemas para API (input/output)

```typescript
// Schema para validar request body
const CreateUserInput = z.object({
  name: z.string().min(1).max(100),
  email: z.email(),
  role: z.enum(['admin', 'user']).default('user'),
});

// Schema para respuesta (omite campos sensibles)
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

### ❌ Parse sin manejo de errores

```typescript
// ❌ Crash si falla
const user = UserSchema.parse(untrustedData);

// ✅ Safe parse o try/catch
const result = UserSchema.safeParse(untrustedData);
if (!result.success) handleErrors(result.error);
```

### ❌ Usar any en vez de inferir

```typescript
// ❌
function createUser(data: any) { ... }

// ✅
type CreateUserInput = z.infer<typeof CreateUserSchema>;
function createUser(data: CreateUserInput) { ... }
```

## Quick Reference

| Task | Patrón Zod 4 |
|------|-------------|
| Email | `z.email()` |
| URL | `z.url()` |
| UUID | `z.uuid()` |
| String no vacía | `z.string().min(1)` |
| Error custom | `z.string({ error: 'msg' })` |
| Inferir tipo | `z.infer<typeof Schema>` |
| Parse seguro | `Schema.safeParse(data)` |
| Validación cross-field | `.superRefine()` |
| Con RHF | `zodResolver(Schema)` |
