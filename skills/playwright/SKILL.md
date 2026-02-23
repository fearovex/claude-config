---
name: playwright
description: >
  Playwright E2E testing patterns with Page Object Model, MCP tools, and accessibility selectors.
  Trigger: When writing E2E tests, using Playwright, implementing page objects, or testing UI flows.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When to Use

Load when: writing Playwright E2E tests, implementing Page Object Model, using Playwright MCP tools, or defining test strategies.

## Critical Patterns

### Pattern 1: MCP Workflow PRIMERO

**Antes de escribir cualquier test**, usa Playwright MCP tools para:
1. Navegar a la página
2. Tomar snapshot del DOM
3. Interactuar con elementos
4. Verificar los selectores reales

```
# MCP flow antes de codificar:
1. playwright_navigate → ir a la página
2. playwright_snapshot → ver estructura real del DOM
3. playwright_click / playwright_fill → probar interacciones
4. Luego escribir el test con selectores verificados
```

### Pattern 2: Jerarquía de Selectores

```typescript
// ✅ Prioridad (de mayor a menor)
page.getByRole('button', { name: 'Submit' })   // 1. Accesibilidad
page.getByLabel('Email address')                // 2. Label
page.getByText('Welcome back')                  // 3. Texto visible
page.getByPlaceholder('Enter email')            // 4. Placeholder
page.getByTestId('submit-button')               // 5. Último recurso

// ❌ Evitar selectores frágiles
page.locator('#submit-btn')
page.locator('.btn-primary > span')
page.locator('div:nth-child(3)')
```

### Pattern 3: Page Object Model

```typescript
// base-page.ts
export abstract class BasePage {
  constructor(protected page: Page) {}

  async navigate(path: string) {
    await this.page.goto(path);
  }

  async waitForLoad() {
    await this.page.waitForLoadState('networkidle');
  }

  async getNotification() {
    return this.page.getByRole('alert');
  }
}

// login-page.ts
export class LoginPage extends BasePage {
  readonly emailInput = this.page.getByLabel('Email');
  readonly passwordInput = this.page.getByLabel('Password');
  readonly submitButton = this.page.getByRole('button', { name: 'Sign in' });
  readonly errorMessage = this.page.getByRole('alert');

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async isLoginSuccessful() {
    await this.page.waitForURL('/dashboard');
    return true;
  }
}
```

## Code Examples

### Test básico con Page Object

```typescript
import { test, expect } from '@playwright/test';
import { LoginPage } from './pages/login-page';
import { DashboardPage } from './pages/dashboard-page';

test.describe('Authentication', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    await loginPage.navigate('/login');
  });

  test('should login with valid credentials', async () => {
    await loginPage.login('user@example.com', 'password123');
    await expect(dashboardPage.welcomeMessage).toBeVisible();
  });

  test('should show error with invalid credentials', async () => {
    await loginPage.login('user@example.com', 'wrong');
    await expect(loginPage.errorMessage).toContainText('Invalid credentials');
  });
});
```

### Estructura de carpetas

```
tests/
├── base-page.ts                    # Base class para todos los page objects
├── helpers.ts                      # Test data, API helpers
├── auth/
│   ├── login-page.ts               # Page Object
│   ├── login.spec.ts               # Tests
│   └── login.md                    # Documentación de casos
├── dashboard/
│   ├── dashboard-page.ts
│   ├── dashboard.spec.ts
│   └── dashboard.md
└── fixtures/
    └── auth.fixture.ts             # Fixtures compartidos
```

### Fixtures reutilizables

```typescript
// fixtures/auth.fixture.ts
import { test as base } from '@playwright/test';
import { LoginPage } from '../auth/login-page';

type AuthFixtures = {
  loginPage: LoginPage;
  authenticatedPage: Page;
};

export const test = base.extend<AuthFixtures>({
  loginPage: async ({ page }, use) => {
    await use(new LoginPage(page));
  },

  authenticatedPage: async ({ page }, use) => {
    const loginPage = new LoginPage(page);
    await loginPage.navigate('/login');
    await loginPage.login(process.env.TEST_EMAIL!, process.env.TEST_PASSWORD!);
    await page.waitForURL('/dashboard');
    await use(page);
  },
});
```

### Documentación de test (formato)

```markdown
<!-- tests/auth/login.md -->
# Login Tests

## TC-001: Login exitoso
- **Priority**: High
- **Precondition**: Usuario registrado con email válido
- **Steps**: Navegar a /login → ingresar credenciales → submit
- **Assertions**: Redirige a /dashboard, muestra mensaje de bienvenida

## TC-002: Login fallido — contraseña incorrecta
- **Priority**: High
- **Precondition**: Usuario registrado
- **Steps**: Navegar a /login → ingresar contraseña incorrecta → submit
- **Assertions**: Muestra error "Invalid credentials", permanece en /login
```

## Anti-Patterns

### ❌ Selectores CSS frágiles

```typescript
// ❌ Se rompe si cambia el CSS
await page.click('.auth-form .btn.btn-primary')
await page.fill('input[type="email"]:nth-of-type(1)', email)

// ✅
await page.getByRole('button', { name: 'Sign in' }).click()
await page.getByLabel('Email').fill(email)
```

### ❌ Duplicar Page Objects

```typescript
// ❌ Definir el mismo locator en múltiples tests
const submitBtn = page.locator('#submit'); // en test1.spec.ts
const submitBtn = page.locator('#submit'); // en test2.spec.ts

// ✅ Un solo Page Object, todos los tests lo importan
import { LoginPage } from './login-page';
```

### ❌ Escribir tests sin explorar primero con MCP

```typescript
// ❌ Asumes la estructura sin verificar
await page.getByRole('button', { name: 'Login' }).click();

// ✅ Primero usa playwright_snapshot para ver el DOM real,
// luego escribe con los selectores correctos
```

## Quick Reference

| Task | Comando |
|------|---------|
| Correr todos | `npx playwright test` |
| Por nombre | `npx playwright test --grep "login"` |
| UI mode | `npx playwright test --ui` |
| Debug mode | `npx playwright test --debug` |
| Un archivo | `npx playwright test auth/login.spec.ts` |
| Generar report | `npx playwright show-report` |
| Codegen | `npx playwright codegen http://localhost:3000` |
