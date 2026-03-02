---
name: playwright
description: >
  Playwright E2E testing patterns with Page Object Model, MCP tools, and accessibility selectors.
  Trigger: When writing E2E tests, using Playwright, implementing page objects, or testing UI flows.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
format: procedural
---

## When to Use

**Triggers**: When writing E2E tests, using Playwright, implementing page objects, or testing UI flows.

Load when: writing Playwright E2E tests, implementing Page Object Model, using Playwright MCP tools, or defining test strategies.

## Critical Patterns

### Pattern 1: MCP Workflow FIRST

**Before writing any test**, use Playwright MCP tools to:
1. Navigate to the page
2. Take a DOM snapshot
3. Interact with elements
4. Verify the actual selectors

```
# MCP flow before coding:
1. playwright_navigate → go to the page
2. playwright_snapshot → see the actual DOM structure
3. playwright_click / playwright_fill → test interactions
4. Then write the test with verified selectors
```

### Pattern 2: Selector Hierarchy

```typescript
// ✅ Priority (from highest to lowest)
page.getByRole('button', { name: 'Submit' })   // 1. Accesibilidad
page.getByLabel('Email address')                // 2. Label
page.getByText('Welcome back')                  // 3. Texto visible
page.getByPlaceholder('Enter email')            // 4. Placeholder
page.getByTestId('submit-button')               // 5. Last resort

// ❌ Avoid fragile selectors
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

### Basic Test with Page Object

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

### Folder Structure

```
tests/
├── base-page.ts                    # Base class for all page objects
├── helpers.ts                      # Test data, API helpers
├── auth/
│   ├── login-page.ts               # Page Object
│   ├── login.spec.ts               # Tests
│   └── login.md                    # Test case documentation
├── dashboard/
│   ├── dashboard-page.ts
│   ├── dashboard.spec.ts
│   └── dashboard.md
└── fixtures/
    └── auth.fixture.ts             # Shared fixtures
```

### Reusable Fixtures

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

### Test Documentation (format)

```markdown
<!-- tests/auth/login.md -->
# Login Tests

## TC-001: Successful login
- **Priority**: High
- **Precondition**: Registered user with valid email
- **Steps**: Navigate to /login → enter credentials → submit
- **Assertions**: Redirects to /dashboard, shows welcome message

## TC-002: Failed login — incorrect password
- **Priority**: High
- **Precondition**: Registered user
- **Steps**: Navigate to /login → enter incorrect password → submit
- **Assertions**: Shows error "Invalid credentials", stays on /login
```

## Anti-Patterns

### ❌ Fragile CSS Selectors

```typescript
// ❌ Breaks if CSS changes
await page.click('.auth-form .btn.btn-primary')
await page.fill('input[type="email"]:nth-of-type(1)', email)

// ✅
await page.getByRole('button', { name: 'Sign in' }).click()
await page.getByLabel('Email').fill(email)
```

### ❌ Duplicating Page Objects

```typescript
// ❌ Defining the same locator in multiple tests
const submitBtn = page.locator('#submit'); // in test1.spec.ts
const submitBtn = page.locator('#submit'); // in test2.spec.ts

// ✅ A single Page Object, all tests import it
import { LoginPage } from './login-page';
```

### ❌ Writing tests without exploring first with MCP

```typescript
// ❌ Assuming the structure without verifying
await page.getByRole('button', { name: 'Login' }).click();

// ✅ First use playwright_snapshot to see the actual DOM,
// then write with the correct selectors
```

## Quick Reference

| Task | Command |
|------|---------|
| Run all | `npx playwright test` |
| By name | `npx playwright test --grep "login"` |
| UI mode | `npx playwright test --ui` |
| Debug mode | `npx playwright test --debug` |
| Single file | `npx playwright test auth/login.spec.ts` |
| Generate report | `npx playwright show-report` |
| Codegen | `npx playwright codegen http://localhost:3000` |

## Rules

- All selectors must use accessibility attributes (`getByRole`, `getByLabel`, `getByText`) or `data-testid`; CSS class selectors are fragile and forbidden
- Every test must be isolated — no shared mutable state between tests; use `beforeEach`/`afterEach` for setup and teardown
- Page Object Model is required for any test suite with more than 3 pages; inline selectors across multiple test files are a maintenance liability
- Assertions must use Playwright's built-in auto-waiting matchers (`toBeVisible`, `toHaveText`); manual `waitForTimeout` calls are not acceptable
- Test files must be co-located with the feature they test or placed in a dedicated `e2e/` directory — never mixed with unit test files
