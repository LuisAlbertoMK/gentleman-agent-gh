# e2e-testing — Reference Materials

> **Externalized from** .agents/skills/e2e-testing/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples (4-5)

### Example 1: Full Login Flow with Assertions
```javascript
// tests/e2e/auth/login.spec.js
const { test, expect } = require('@playwright/test');

test.describe('Authentication Flow', () => {
  test('successful login redirects to dashboard', async ({ page }) => {
    await page.goto('/login');
    await page.fill('[data-testid="email"]', 'user@example.com');
    await page.fill('[data-testid="pwd"]', 'securePass123');
    await page.click('[data-testid="submit"]');
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('[data-testid="welcome"]')).toContainText('Welcome');
  });

  test('failed login shows error message', async ({ page }) => {
    await page.goto('/login');
    await page.fill('[data-testid="email"]', 'wrong@example.com');
    await page.fill('[data-testid="pwd"]', 'wrong');
    await page.click('[data-testid="submit"]');
    await expect(page.locator('[data-testid="error"]')).toBeVisible();
    await expect(page.locator('[data-testid="error"]')).toContainText('Invalid credentials');
  });
});
```

### Example 2: Visual Regression with Screenshot Comparison
```javascript
// tests/e2e/visual/dashboard.spec.js
const { test, expect } = require('@playwright/test');

test.describe('Dashboard Visual Regression', () => {
  test('dashboard matches baseline', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveScreenshot('dashboard-baseline.png', {
      maxDiffPixels: 100,
      threshold: 0.2
    });
  });

  test('dark mode variant', async ({ page }) => {
    await page.goto('/dashboard');
    await page.click('[data-testid="theme-toggle"]');
    await page.waitForTimeout(300);
    await expect(page).toHaveScreenshot('dashboard-dark.png', {
      maxDiffPixels: 50
    });
  });
});
```

### Example 3: Quick Mode CLI for Smoke Testing
```powershell
# Smoke check: verify homepage loads and key elements exist
e2t http://localhost:3000 --actions "wait:#hero,wait:#cta,screenshot:homepage.png"

# Form flow: login with headed mode for debugging
e2t http://localhost:3000/login \
  --actions "fill:#email=test@test.com,fill:#pass=secret,click:#login,wait:#dashboard" \
  --headed --screenshot:login-success.png

# Quick visual check with Ollama AI analysis
e2t http://localhost:3000/pricing --actions "wait:#pricing-table" --analyze --model moondream:latest
```

### Example 4: Multi-Step Checkout Flow
```javascript
// tests/e2e/checkout/complete-flow.spec.js
const { test, expect } = require('@playwright/test');

test('complete checkout flow', async ({ page }) => {
  // Add to cart
  await page.goto('/products/123');
  await page.click('[data-testid="add-to-cart"]');
  await expect(page.locator('[data-testid="cart-count"]')).toContainText('1');

  // Proceed to checkout
  await page.click('[data-testid="cart-icon"]');
  await page.click('[data-testid="checkout"]');

  // Fill shipping
  await page.fill('[data-testid="shipping-name"]', 'John Doe');
  await page.fill('[data-testid="shipping-address"]', '123 Main St');
  await page.fill('[data-testid="shipping-city"]', 'NYC');
  await page.selectOption('[data-testid="shipping-state"]', 'NY');
  await page.fill('[data-testid="shipping-zip"]', '10001');
  await page.click('[data-testid="continue-payment"]');

  // Payment
  await page.fill('[data-testid="card-number"]', '4242424242424242');
  await page.fill('[data-testid="card-expiry"]', '12/28');
  await page.fill('[data-testid="card-cvc"]', '123');
  await page.click('[data-testid="pay"]');

  // Confirmation
  await expect(page).toHaveURL(/\/order\/\d+/);
  await expect(page.locator('[data-testid="order-number"]')).toBeVisible();
});
```

### Example 5: Responsive Design Testing
```javascript
// tests/e2e/responsive/mobile.spec.js
const { test, expect } = require('@playwright/test');

const viewports = [
  { name: 'mobile', width: 375, height: 667 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1280, height: 720 }
];

for (const vp of viewports) {
  test(`navigation works on ${vp.name}`, async ({ page }) => {
    await page.setViewportSize({ width: vp.width, height: vp.height });
    await page.goto('/');

    if (vp.width < 768) {
      await page.click('[data-testid="mobile-menu-toggle"]');
      await expect(page.locator('[data-testid="mobile-nav"]')).toBeVisible();
    }

    await page.click('[data-testid="nav-about"]');
    await expect(page).toHaveURL('/about');
  });
}
```

## Testing Patterns (3)

### Pattern 1: Page Object Model (POM)
```javascript
// tests/e2e/pages/LoginPage.js
class LoginPage {
  constructor(page) {
    this.page = page;
    this.email = page.locator('[data-testid="email"]');
    this.pwd = page.locator('[data-testid="pwd"]');
    this.submit = page.locator('[data-testid="submit"]');
    this.error = page.locator('[data-testid="error"]');
  }

  async goto() {
    await this.page.goto('/login');
  }

  async login(email, pwd) {
    await this.email.fill(email);
    await this.pwd.fill(pwd);
    await this.submit.click();
  }

  async expectError(message) {
    await expect(this.error).toBeVisible();
    await expect(this.error).toContainText(message);
  }
}

module.exports = { LoginPage };
```

```javascript
// Usage in test
const { LoginPage } = require('../pages/LoginPage');

test('login with POM', async ({ page }) => {
  const login = new LoginPage(page);
  await login.goto();
  await login.login('user@test.com', 'pwd');
  await expect(page).toHaveURL('/dashboard');
});
```

### Pattern 2: Test Fixtures for Reusable State
```javascript
// tests/e2e/fixtures/auth.fixture.js
const { test } = require('@playwright/test');
const { LoginPage } = require('../pages/LoginPage');

const authenticated = test.extend({
  page: async ({ page }, use) => {
    const login = new LoginPage(page);
    await login.goto();
    await login.login('test@test.com', 'pwd');
    await page.waitForURL('/dashboard');
    await use(page);
  }
});

module.exports = { authenticated };
```

```javascript
// Usage
const { authenticated } = require('../fixtures/auth.fixture');

authenticated('authenticated user sees dashboard', async ({ page }) => {
  await expect(page.locator('[data-testid="welcome"]')).toBeVisible();
});
```

### Pattern 3: Data-Driven Testing with External Test Data
```javascript
// tests/e2e/data/users.json
{
  "validUsers": [
    { "email": "admin@test.com", "pwd": "admin123", "role": "admin" },
    { "email": "user@test.com", "pwd": "user123", "role": "user" }
  ],
  "invalidUsers": [
    { "email": "wrong@test.com", "pwd": "wrong", "expectedError": "Invalid credentials" },
    { "email": "", "pwd": "test", "expectedError": "Email required" }
  ]
}
```

```javascript
// tests/e2e/auth/data-driven.spec.js
const { test, expect } = require('@playwright/test');
const { LoginPage } = require('../pages/LoginPage');
const testData = require('../data/users.json');

for (const user of testData.validUsers) {
  test(`valid login: ${user.role}`, async ({ page }) => {
    const login = new LoginPage(page);
    await login.goto();
    await login.login(user.email, user.pwd);
    await expect(page).toHaveURL('/dashboard');
  });
}

for (const user of testData.invalidUsers) {
  test(`invalid login: ${user.expectedError}`, async ({ page }) => {
    const login = new LoginPage(page);
    await login.goto();
    await login.login(user.email, user.pwd);
    await login.expectError(user.expectedError);
  });
}
```

## Edge Cases (4)

### Edge Case 1: Flaky Network / Slow API Responses
```javascript
test('handles slow API gracefully', async ({ page }) => {
  // Intercept and delay API
  await page.route('**/api/user', async route => {
    await new Promise(r => setTimeout(r, 3000)); // 3s delay
    route.continue();
  });

  await page.goto('/dashboard');
  // Test loading state
  await expect(page.locator('[data-testid="loading"]')).toBeVisible();
  await expect(page.locator('[data-testid="loading"]')).toBeHidden({ timeout: 5000 });
  await expect(page.locator('[data-testid="user-data"]')).toBeVisible();
});
```

### Edge Case 2: Authentication Token Expiry Mid-Session
```javascript
test('handles token expiry and redirects to login', async ({ page }) => {
  await page.goto('/dashboard');

  // Simulate expired token by clearing storage
  await page.evaluate(() => localStorage.clear());
  await page.evaluate(() => sessionStorage.clear());

  // Trigger API call that returns 401
  await page.click('[data-testid="refresh-data"]');

  // Should redirect to login
  await expect(page).toHaveURL('/login');
  await expect(page.locator('[data-testid="session-expired"]')).toBeVisible();
});
```

### Edge Case 3: Browser-Specific Behaviors (Safari/WebKit quirks)
```javascript
test.describe.configure({ retries: 2 }); // Extra retries for flaky browsers

test('file upload works across browsers', async ({ page, browserName }) => {
  await page.goto('/upload');

  const fileInput = page.locator('input[type="file"]');

  if (browserName === 'webkit') {
    // WebKit requires setInputFiles with absolute path
    await fileInput.setInputFiles({ name: 'test.pdf', mimeType: 'application/pdf', buffer: Buffer.from('test') });
  } else {
    await fileInput.setInputFiles('tests/fixtures/test.pdf');
  }

  await page.click('[data-testid="upload-btn"]');
  await expect(page.locator('[data-testid="success"]')).toBeVisible();
});
```

### Edge Case 4: Race Conditions in Async Operations
```javascript
test('handles rapid clicks without duplicate submissions', async ({ page }) => {
  await page.goto('/form');
  await page.fill('[data-testid="name"]', 'Test');

  // Rapid click submit 5 times
  const submitBtn = page.locator('[data-testid="submit"]');
  await Promise.all([
    submitBtn.click(),
    submitBtn.click(),
    submitBtn.click(),
    submitBtn.click(),
    submitBtn.click()
  ]);

  // Should only create ONE record
  await page.waitForURL('/success');
  const records = await page.evaluate(() => window.__testRecords || []);
  expect(records.length).toBe(1);
});
```

## Anti-Patterns (2)

### Anti-Pattern 1: Hardcoded Selectors & Sleep Waits
```javascript
// ❌ BAD: Brittle selectors, arbitrary waits
await page.click('/html/body/div[2]/form/button');  // XPath - breaks on layout change
await page.waitForTimeout(5000);                    // Fixed sleep - flaky & slow
await page.fill('#username', 'test');               // ID may change

// ✅ GOOD: Data-testid selectors, smart waits
await page.click('[data-testid="submit-btn"]');
await page.waitForLoadState('networkidle');         // Waits for network
await page.fill('[data-testid="username"]', 'test');
await expect(page.locator('[data-testid="welcome"]')).toBeVisible(); // Auto-retries
```

### Anti-Pattern 2: Test Interdependence & Shared State
```javascript
// ❌ BAD: Tests depend on each other's side effects
test('create user', async ({ page }) => { ... });      // Creates user
test('edit user', async ({ page }) => { ... });        // Edits user from test 1
test('delete user', async ({ page }) => { ... });      // Deletes user from test 1

// If test 1 fails, tests 2 & 3 fail cascade. No parallel execution.

// ✅ GOOD: Independent tests with isolated fixtures
test('create user', async ({ page }) => { ... });      // Creates & cleans up own user
test('edit user', async ({ page }) => {                // Creates own user via API
  await api.createUser({ name: 'Test' });
  await page.goto('/users/1/edit');
  ...
});
test('delete user', async ({ page }) => {              // Creates own user via API
  await api.createUser({ name: 'Test' });
  await page.goto('/users/1');
  ...
});
```

(End of file)
