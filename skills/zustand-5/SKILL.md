---
name: zustand-5
description: >
  Zustand 5 state management patterns for React: stores, persistence, selectors, slices.
  Trigger: When managing global state in React, using Zustand, or implementing state slices.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load when: managing global or shared state in React, implementing persistence, using Zustand stores, or needing out-of-component state access.

## Critical Patterns

### Pattern 1: Store básico tipado

```typescript
import { create } from 'zustand';

interface CounterState {
  count: number;
  increment: () => void;
  decrement: () => void;
  reset: () => void;
}

export const useCounterStore = create<CounterState>()((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 }),
}));
```

### Pattern 2: Selectores para evitar re-renders innecesarios

```typescript
// ❌ Selecciona todo el store — re-render en CUALQUIER cambio
const store = useCounterStore();

// ✅ Selecciona solo lo necesario
const count = useCounterStore((state) => state.count);
const increment = useCounterStore((state) => state.increment);

// ✅ Múltiples valores con useShallow
import { useShallow } from 'zustand/react/shallow';

const { count, increment } = useCounterStore(
  useShallow((state) => ({ count: state.count, increment: state.increment }))
);
```

### Pattern 3: Persistencia

```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface SettingsState {
  theme: 'light' | 'dark';
  language: string;
  setTheme: (theme: 'light' | 'dark') => void;
  setLanguage: (lang: string) => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      theme: 'light',
      language: 'es',
      setTheme: (theme) => set({ theme }),
      setLanguage: (language) => set({ language }),
    }),
    { name: 'settings-storage' } // localStorage key
  )
);
```

## Code Examples

### Store con async y loading/error states

```typescript
interface UserState {
  users: User[];
  isLoading: boolean;
  error: string | null;
  fetchUsers: () => Promise<void>;
  createUser: (data: CreateUserInput) => Promise<void>;
}

export const useUserStore = create<UserState>()((set) => ({
  users: [],
  isLoading: false,
  error: null,

  fetchUsers: async () => {
    set({ isLoading: true, error: null });
    try {
      const users = await api.getUsers();
      set({ users, isLoading: false });
    } catch (error) {
      set({ error: String(error), isLoading: false });
    }
  },

  createUser: async (data) => {
    set({ isLoading: true });
    try {
      const user = await api.createUser(data);
      set((state) => ({ users: [...state.users, user], isLoading: false }));
    } catch (error) {
      set({ error: String(error), isLoading: false });
    }
  },
}));
```

### Slices pattern (modular)

```typescript
// userSlice.ts
interface UserSlice {
  user: User | null;
  setUser: (user: User) => void;
  clearUser: () => void;
}

const createUserSlice = (set: any): UserSlice => ({
  user: null,
  setUser: (user) => set({ user }),
  clearUser: () => set({ user: null }),
});

// cartSlice.ts
interface CartSlice {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  removeItem: (id: string) => void;
}

const createCartSlice = (set: any): CartSlice => ({
  items: [],
  addItem: (item) => set((state: any) => ({ items: [...state.items, item] })),
  removeItem: (id) => set((state: any) => ({
    items: state.items.filter((i: CartItem) => i.id !== id)
  })),
});

// store.ts — combina slices
export const useStore = create<UserSlice & CartSlice>()((...args) => ({
  ...createUserSlice(...args),
  ...createCartSlice(...args),
}));
```

### Immer para mutaciones directas

```typescript
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

interface TodoState {
  todos: { id: string; text: string; done: boolean }[];
  toggleTodo: (id: string) => void;
}

export const useTodoStore = create<TodoState>()(
  immer((set) => ({
    todos: [],
    toggleTodo: (id) => set((state) => {
      const todo = state.todos.find((t) => t.id === id);
      if (todo) todo.done = !todo.done; // Mutación directa OK con Immer
    }),
  }))
);
```

### DevTools + acceso externo

```typescript
import { create } from 'zustand';
import { devtools } from 'zustand/middleware';

export const useAppStore = create<AppState>()(
  devtools(
    (set) => ({ /* ... */ }),
    { name: 'AppStore' } // Nombre en Redux DevTools
  )
);

// Acceso fuera de componentes
const state = useAppStore.getState();
const unsubscribe = useAppStore.subscribe(
  (state) => state.user,
  (user) => console.log('User changed:', user)
);
```

## Anti-Patterns

### ❌ Seleccionar el store completo

```typescript
// ❌ Re-render en cualquier cambio del store
const { count, user, settings, items } = useStore();

// ✅ Selecciona solo lo que necesitas
const count = useStore((s) => s.count);
```

### ❌ Lógica async directa en set

```typescript
// ❌ No pongas async dentro de set
set(async (state) => { /* ... */ });

// ✅ Usa get() o define el async en el action
fetchData: async () => {
  const data = await api.get();
  set({ data });
}
```

## Quick Reference

| Task | Patrón |
|------|--------|
| Store básico | `create<State>()((set) => ...)` |
| Selector simple | `useStore((s) => s.field)` |
| Múltiples campos | `useStore(useShallow((s) => ({a: s.a, b: s.b})))` |
| Persistencia | `create()(persist(..., { name: 'key' }))` |
| Mutaciones | `create()(immer(...))` |
| DevTools | `create()(devtools(..., { name: 'Name' }))` |
| Acceso externo | `useStore.getState()` |
| Suscripción | `useStore.subscribe(selector, callback)` |
