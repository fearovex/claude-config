---
name: react-native
description: >
  React Native patterns for mobile app development with Expo and bare workflow.
  Trigger: When building mobile apps, working with React Native components, using Expo, React Navigation, or NativeWind.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

Load this skill when:
- Building mobile applications with React Native
- Working with Expo managed or bare workflow
- Implementing navigation with React Navigation
- Styling with NativeWind (Tailwind for RN)
- Handling platform-specific code (iOS/Android)
- Managing native modules and linking

## Critical Patterns

### Pattern 1: Project Structure

```
src/
├── app/                    # Expo Router screens
│   ├── (tabs)/            # Tab navigator group
│   ├── (auth)/            # Auth flow group
│   └── _layout.tsx        # Root layout
├── components/
│   ├── ui/                # Reusable UI components
│   └── features/          # Feature-specific components
├── hooks/                 # Custom hooks
├── services/              # API and external services
├── stores/                # State management (Zustand)
├── utils/                 # Utility functions
├── constants/             # App constants, themes
└── types/                 # TypeScript types
```

### Pattern 2: Functional Components with TypeScript

```typescript
import { View, Text, Pressable } from 'react-native';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary';
  disabled?: boolean;
}

export function Button({
  title,
  onPress,
  variant = 'primary',
  disabled = false
}: ButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      disabled={disabled}
      style={({ pressed }) => [
        styles.button,
        variant === 'secondary' && styles.buttonSecondary,
        pressed && styles.buttonPressed,
        disabled && styles.buttonDisabled,
      ]}
    >
      <Text style={styles.buttonText}>{title}</Text>
    </Pressable>
  );
}
```

### Pattern 3: Platform-Specific Code

```typescript
import { Platform, StyleSheet } from 'react-native';

const styles = StyleSheet.create({
  container: {
    paddingTop: Platform.select({ ios: 44, android: 0 }),
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: { elevation: 4 },
    }),
  },
});

// Or use file extensions:
// Component.ios.tsx
// Component.android.tsx
```

## Code Examples

### Example 1: Expo Router Layout

```typescript
// app/_layout.tsx
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';

export default function RootLayout() {
  return (
    <>
      <StatusBar style="auto" />
      <Stack screenOptions={{ headerShown: false, animation: 'slide_from_right' }}>
        <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
        <Stack.Screen
          name="modal"
          options={{ presentation: 'modal', animation: 'slide_from_bottom' }}
        />
      </Stack>
    </>
  );
}
```

### Example 2: Custom Hook with React Query

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { userService } from '@/services/user';

export function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => userService.getById(userId),
    staleTime: 5 * 60 * 1000,
  });
}

export function useUpdateUser() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateUserInput) => userService.update(data),
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: ['user', variables.id] });
    },
  });
}
```

### Example 3: Safe Area + Keyboard Handling

```typescript
import { KeyboardAvoidingView, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

export function ScreenWrapper({ children }: { children: React.ReactNode }) {
  return (
    <SafeAreaView style={{ flex: 1 }} edges={['top', 'left', 'right']}>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}
      >
        {children}
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}
```

### Example 4: Zustand Store with AsyncStorage

```typescript
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface AuthState {
  token: string | null;
  user: User | null;
  isAuthenticated: boolean;
  login: (token: string, user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      isAuthenticated: false,
      login: (token, user) => set({ token, user, isAuthenticated: true }),
      logout: () => set({ token: null, user: null, isAuthenticated: false }),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
```

## Anti-Patterns

### Don't: Inline Styles Everywhere

```typescript
// ❌ Bad
<View style={{ flex: 1, padding: 16, backgroundColor: '#fff' }}>

// ✅ Good - StyleSheet or NativeWind
const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
});
```

### Don't: Use TouchableOpacity (legacy)

```typescript
// ❌ Bad
import { TouchableOpacity } from 'react-native';

// ✅ Good
import { Pressable } from 'react-native';
<Pressable
  onPress={onPress}
  style={({ pressed }) => [styles.button, pressed && { opacity: 0.7 }]}
>
```

### Don't: Forget Loading/Error States

```typescript
// ❌ Bad
const { data } = useUser(userId);
return <Text>{data.name}</Text>; // crash if undefined

// ✅ Good
const { data, isLoading, error } = useUser(userId);
if (isLoading) return <LoadingSpinner />;
if (error) return <ErrorMessage error={error} />;
if (!data) return null;
return <Text>{data.name}</Text>;
```

## Quick Reference

| Task | Pattern |
|------|---------|
| New Expo project | `npx create-expo-app@latest --template tabs` |
| Add NativeWind | `npx expo install nativewind tailwindcss` |
| Platform check | `Platform.OS === 'ios'` |
| Safe insets | `useSafeAreaInsets()` |
| Navigation | `router.push('/screen')` (Expo Router) |
| Icons | `@expo/vector-icons` |
| Animations | `react-native-reanimated` |
| Gestures | `react-native-gesture-handler` |
