---
name: tailwind-4
description: >
  Tailwind CSS 4 patterns: semantic classes, cn() utility, dynamic styling, library exceptions.
  Trigger: When styling with Tailwind, using className, conditional styles, or dark mode.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When styling with Tailwind, using className, conditional styles, or dark mode.

Load when: styling with Tailwind CSS 4, using className, implementing dark mode, or needing conditional styles.

## Critical Patterns

### Pattern 1: Semantic classes — never var() in className

```typescript
// ✅ Use semantic classes
<div className="bg-primary text-white" />
<div className="border-border" />
<div className="text-foreground bg-background" />

// ❌ Never var() in className
<div className="bg-[var(--color-primary)]" />
<div className="text-[var(--foreground)]" />
```

### Pattern 2: Literal values over hex

```typescript
// ✅ Semantic
<p className="text-white bg-slate-900" />
<p className="text-gray-500" />

// ❌ Avoid hex in className when an equivalent exists
<p className="text-[#ffffff] bg-[#0f172a]" />
```

### Pattern 3: cn() for conditional styles

```typescript
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// ✅ Use cn() for conditionals and conflicts
<button
  className={cn(
    'px-4 py-2 rounded-md font-medium',
    variant === 'primary' && 'bg-primary text-white',
    variant === 'ghost' && 'bg-transparent hover:bg-accent',
    disabled && 'opacity-50 cursor-not-allowed',
    className // allows external override
  )}
/>

// ✅ Static classes — no cn() needed
<div className="flex items-center gap-4 p-6" />
```

## Code Examples

### Variants with cva (class-variance-authority)

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
// ✅ Dark mode with Tailwind classes
<div className="bg-white dark:bg-gray-900">
  <p className="text-gray-900 dark:text-gray-100">Content</p>
  <button className="bg-blue-600 dark:bg-blue-500 hover:bg-blue-700 dark:hover:bg-blue-400">
    Action
  </button>
</div>

// CSS config (tailwind.config.ts)
export default {
  darkMode: 'class', // or 'media'
  // ...
}
```

### Responsive Design

```typescript
// Mobile-first with breakpoints
<div className="
  flex flex-col          // mobile: column
  md:flex-row            // tablet: row
  lg:grid lg:grid-cols-3 // desktop: 3-col grid
  gap-4
">
  <Card />
  <Card />
  <Card />
</div>
```

### Exception for Libraries (Recharts, etc.)

```typescript
// ✅ For libraries that don't support className, use CSS var constants
const CHART_COLORS = {
  primary: 'var(--color-primary)',
  secondary: 'var(--color-secondary)',
  muted: 'var(--color-muted)',
} as const;

<LineChart>
  <Line stroke={CHART_COLORS.primary} />
</LineChart>
```

### Dynamic values at runtime

```typescript
// ✅ style prop for runtime calculations
<div style={{ width: `${percentage}%` }} className="bg-primary h-2 rounded" />

// ✅ CSS custom properties for theming
<div
  style={{ '--card-cols': columns } as React.CSSProperties}
  className="grid grid-cols-[repeat(var(--card-cols),1fr)]"
/>
```

## Anti-Patterns

### ❌ var() in className

```typescript
// ❌ Breaks Tailwind's optimizer
<div className="bg-[var(--primary)] text-[var(--fg)]" />

// ✅
<div className="bg-primary text-foreground" />
```

### ❌ String concatenation for conditionals

```typescript
// ❌ Can generate invalid classes
<div className={'text-sm ' + (active ? 'text-blue-600' : 'text-gray-500')} />

// ✅
<div className={cn('text-sm', active ? 'text-blue-600' : 'text-gray-500')} />
```

### ❌ cn() for purely static classes

```typescript
// ❌ Unnecessary
<div className={cn('flex items-center gap-4')} />

// ✅
<div className="flex items-center gap-4" />
```

## Quick Reference

| Task | Pattern |
|------|---------|
| Semantic color | `bg-primary`, `text-foreground` |
| Conditional | `cn('base', condition && 'variant')` |
| Variants | `cva('base', { variants: ... })` |
| Dark mode | `dark:bg-slate-900` |
| Responsive | `sm:` `md:` `lg:` `xl:` |
| Runtime value | `style={{ width: \`${val}%\` }}` |
| External override | Accept and apply `className` prop with `cn()` |

## Rules

- Use the `cn()` utility (clsx + tailwind-merge) for all conditional class composition; string concatenation for dynamic classes causes class conflicts that tailwind-merge resolves
- Tailwind 4 uses CSS-first configuration (`@theme` in CSS) — never use `tailwind.config.js` theme extensions for new Tailwind 4 projects
- Avoid `@apply` in component CSS files; Tailwind utility classes belong in the markup, not extracted into CSS rules
- Component library classes (shadcn/ui, Radix) must not be overridden with Tailwind classes on the same element — extend via variants or wrapper elements
- Dynamic class names must be complete strings (e.g., `'text-red-500'`), never constructed by string interpolation (e.g., `` `text-${color}-500` ``) — PurgeCSS/Tailwind cannot detect partial class names
