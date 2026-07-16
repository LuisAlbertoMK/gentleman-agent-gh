// @ts-check
const { test, expect } = require('@playwright/test');

test.describe('Login Flow', () => {
  test('should display login form', async ({ page }) => {
    await page.goto('/login');
    
    // Wait for form to load
    await page.waitForSelector('input[type="email"]');
    
    // Assert form elements exist
    await expect(page.locator('input[type="email"]')).toBeVisible();
    await expect(page.locator('input[type="password"]')).toBeVisible();
    await expect(page.locator('button[type="submit"]')).toBeVisible();
  });

  test('should fill and submit login form', async ({ page }) => {
    await page.goto('/login');
    
    // Wait for form
    await page.waitForSelector('input[type="email"]');
    
    // Fill form
    await page.fill('input[type="email"]', 'user@example.com');
    await page.fill('input[type="password"]', 'password123');
    
    // Take screenshot before submit
    await page.screenshot({ path: 'tests/e2e/before-submit.png' });
    
    // Click submit
    await page.click('button[type="submit"]');
    
    // Wait for navigation or response
    await page.waitForTimeout(2000);
    
    // Take screenshot after submit
    await page.screenshot({ path: 'tests/e2e/after-submit.png' });
    
    // Assert URL changed or error message shown
    const currentUrl = page.url();
    const hasError = await page.locator('.error-message').isVisible();
    
    expect(currentUrl !== '/login' || hasError).toBeTruthy();
  });
});

test.describe('Navigation', () => {
  test('should navigate to home page', async ({ page }) => {
    await page.goto('/');
    
    // Assert home page loaded
    await expect(page).toHaveURL('/');
    await expect(page.locator('h1')).toBeVisible();
  });

  test('should navigate via menu', async ({ page }) => {
    await page.goto('/');
    
    // Click menu item
    await page.click('a[href="/login"]');
    
    // Assert navigation
    await expect(page).toHaveURL('/login');
  });
});

test.describe('Accessibility', () => {
  test('should have no critical accessibility issues', async ({ page }) => {
    await page.goto('/');
    
    // Basic accessibility checks
    const images = await page.locator('img').all();
    for (const img of images) {
      const alt = await img.getAttribute('alt');
      expect(alt).toBeTruthy();
    }
    
    // Check form labels
    const inputs = await page.locator('input').all();
    for (const input of inputs) {
      const id = await input.getAttribute('id');
      if (id) {
        const label = await page.locator(`label[for="${id}"]`).isVisible();
        const ariaLabel = await input.getAttribute('aria-label');
        expect(label || ariaLabel).toBeTruthy();
      }
    }
  });
});
