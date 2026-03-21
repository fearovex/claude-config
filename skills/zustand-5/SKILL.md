---
name: zustand-5
description: >
  Zustand 5 state management patterns for React: stores, persistence, selectors, slices.
  Trigger: When managing global state in React, using Zustand, or implementing state slices.
license: Apache-2.0
metadata:
  version: "1.0"
format: reference
---

## When to Use

**Triggers**: When managing global state in React, using Zustand, or implementing state slices.

Load when: managing global or shared state in React, implementing persistence, using Zustand stores, or needing out-of-component state access.

## Critical Patterns

### Pattern 1: Basic typed store

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

### Pattern 2: Selectors to avoid unnecessary re-renders

```typescript
// ❌ Selects the entire store — re-renders on ANY change
const store = useCounterStore();

// ✅ Select only what you need
const count = useCounterStore((state) => state.count);
const increment = useCounterStore((state) => state.increment);

// ✅ Multiple values with useShallow
import { useShallow } from 'zustand/react/shallow';

const { count, increment } = useCounterStore(
  useShallow((state) => ({ count: state.count, increment: state.increment }))
);
```

### Pattern 3: Persistence

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

### Store with async and loading/error states

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

// store.ts — combine slices
export const useStore = create<UserSlice & CartSlice>()((...args) => ({
  ...createUserSlice(...args),
  ...createCartSlice(...args),
}));
```

### Immer for direct mutations

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
      if (todo) todo.done = !todo.done; // Direct mutation OK with Immer
    }),
  }))
);
```

### DevTools + external access

```typescript
import { create } from 'zustand';
import { devtools } from 'zustand/middleware';

export const useAppStore = create<AppState>()(
  devtools(
    (set) => ({ /* ... */ }),
    { name: 'AppStore' } // Name in Redux DevTools
  )
);

// Access outside of components
const state = useAppStore.getState();
const unsubscribe = useAppStore.subscribe(
  (state) => state.user,
  (user) => console.log('User changed:', user)
);
```

## Anti-Patterns

### ❌ Selecting the entire store

```typescript
// ❌ Re-renders on any store change
const { count, user, settings, items } = useStore();

// ✅ Select only what you need
const count = useStore((s) => s.count);
```

### ❌ Async logic directly in set

```typescript
// ❌ Don't put async inside set
set(async (state) => { /* ... */ });

// ✅ Use get() or define the async in the action
fetchData: async () => {
  const data = await api.get();
  set({ data });
}
```

## Quick Reference

| Task | Pattern |
|------|---------|
| Basic store | `create<State>()((set) => ...)` |
| Simple selector | `useStore((s) => s.field)` |
| Multiple fields | `useStore(useShallow((s) => ({a: s.a, b: s.b})))` |
| Persistence | `create()(persist(..., { name: 'key' }))` |
| Mutations | `create()(immer(...))` |
| DevTools | `create()(devtools(..., { name: 'Name' }))` |
| External access | `useStore.getState()` |
| Subscription | `useStore.subscribe(selector, callback)` |

## Rules

- Stores must be split by domain concern (auth store, cart store, UI store) — a single global store that grows without bound is a maintenance anti-pattern
- Always use selectors to subscribe to specific state slices (`useStore(s => s.count)`) — subscribing to the full store object causes unnecessary re-renders on any state change
- Persist middleware (`zustand/middleware`) must be applied only to stores that genuinely need persistence; over-persisting creates stale-state bugs after schema changes
- Store actions must be defined inside the `create` callback, not as external functions that receive the store as a parameter
- Zustand 5 uses `useShallow` for object selectors to prevent re-renders when returned object references change — wrap object selectors with `useShallow`
