// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * Playwright E2E test configuration
 * 
 * Usage:
 *   npx playwright test                    — Run all tests
 *   npx playwright test tests/e2e/         — Run E2E tests only
 *   npx playwright test --ui               — Run with UI
 *   npx playwright show-report             — View report
 */
module.exports = defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
