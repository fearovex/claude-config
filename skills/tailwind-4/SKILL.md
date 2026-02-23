---
name: tailwind-4
description: >
  Tailwind CSS 4 patterns: semantic classes, cn() utility, dynamic styling, library exceptions.
  Trigger: When styling with Tailwind, using className, conditional styles, or dark mode.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: styling with Tailwind CSS 4, using className, implementing dark mode, or needing conditional styles.

## Critical Patterns

### Pattern 1: Clases semánticas — nunca var() en className

```typescript
// ✅ Usa clases semánticas
<div className="bg-primary text-white" />
<div className="border-border" />
<div className="text-foreground bg-background" />

// ❌ Nunca var() en className
<div className="bg-[var(--color-primary)]" />
<div className="text-[var(--foreground)]" />
```

### Pattern 2: Valores literales sobre hex

```typescript
// ✅ Semántico
<p className="text-white bg-slate-900" />
<p className="text-gray-500" />

// ❌ Evitar hex en className cuando hay equivalente
<p className="text-[#ffffff] bg-[#0f172a]" />
```

### Pattern 3: cn() para estilos condicionales

```typescript
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// ✅ Usa cn() para condicionales y conflictos
<button
  className={cn(
    'px-4 py-2 rounded-md font-medium',
    variant === 'primary' && 'bg-primary text-white',
    variant === 'ghost' && 'bg-transparent hover:bg-accent',
    disabled && 'opacity-50 cursor-not-allowed',
    className // permite override externo
  )}
/>

// ✅ Clases estáticas — sin cn()
<div className="flex items-center gap-4 p-6" />
```

## Code Examples

### Variantes con cva (class-variance-authority)

```typescript
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const buttonVariants = cva(
  'inline-flex items-center justify-center rounded-md font-medium transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
        outline: 'border border-input bg-background hover:bg-accent',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        md: 'h-10 px-4',
        lg: 'h-12 px-6 text-lg',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'md',
    },
  }
);

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

function Button({ variant, size, className, ...props }: ButtonProps) {
  return (
    <button
      className={cn(buttonVariants({ variant, size }), className)}
      {...props}
    />
  );
}
```

### Dark Mode

```typescript
// ✅ Dark mode con clases Tailwind
<div className="bg-white dark:bg-gray-900">
  <p className="text-gray-900 dark:text-gray-100">Content</p>
  <button className="bg-blue-600 dark:bg-blue-500 hover:bg-blue-700 dark:hover:bg-blue-400">
    Action
  </button>
</div>

// CSS config (tailwind.config.ts)
export default {
  darkMode: 'class', // o 'media'
  // ...
}
```

### Responsive Design

```typescript
// Mobile-first con breakpoints
<div className="
  flex flex-col          // mobile: columna
  md:flex-row            // tablet: fila
  lg:grid lg:grid-cols-3 // desktop: grid 3 cols
  gap-4
">
  <Card />
  <Card />
  <Card />
</div>
```

### Excepción para Librerías (Recharts, etc.)

```typescript
// ✅ Para librerías que no soportan className, usa constantes CSS vars
const CHART_COLORS = {
  primary: 'var(--color-primary)',
  secondary: 'var(--color-secondary)',
  muted: 'var(--color-muted)',
} as const;

<LineChart>
  <Line stroke={CHART_COLORS.primary} />
</LineChart>
```

### Valores dinámicos en runtime

```typescript
// ✅ style prop para cálculos en runtime
<div style={{ width: `${percentage}%` }} className="bg-primary h-2 rounded" />

// ✅ CSS custom properties para theming
<div
  style={{ '--card-cols': columns } as React.CSSProperties}
  className="grid grid-cols-[repeat(var(--card-cols),1fr)]"
/>
```

## Anti-Patterns

### ❌ var() en className

```typescript
// ❌ Rompe Tailwind's optimizer
<div className="bg-[var(--primary)] text-[var(--fg)]" />

// ✅
<div className="bg-primary text-foreground" />
```

### ❌ Concatenación de strings para condicionales

```typescript
// ❌ Puede generar clases inválidas
<div className={'text-sm ' + (active ? 'text-blue-600' : 'text-gray-500')} />

// ✅
<div className={cn('text-sm', active ? 'text-blue-600' : 'text-gray-500')} />
```

### ❌ cn() para clases puramente estáticas

```typescript
// ❌ Innecesario
<div className={cn('flex items-center gap-4')} />

// ✅
<div className="flex items-center gap-4" />
```

## Quick Reference

| Task | Patrón |
|------|--------|
| Color semántico | `bg-primary`, `text-foreground` |
| Condicional | `cn('base', condition && 'variant')` |
| Variantes | `cva('base', { variants: ... })` |
| Dark mode | `dark:bg-slate-900` |
| Responsive | `sm:` `md:` `lg:` `xl:` |
| Runtime value | `style={{ width: \`${val}%\` }}` |
| Override externo | Aceptar y aplicar `className` prop con `cn()` |
