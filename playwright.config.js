// E2E_MODE: visible|headless|smoke (via env, default headless)
const E2E_MODE = process.env.E2E_MODE || 'headless';
const isVisible = E2E_MODE === 'visible';

module.exports = {
  testDir: 'e2e',
  timeout: 30000,
  outputDir: 'test-results',
  use: {
    baseURL: 'http://localhost:4173',
    screenshot: 'only-on-failure',
    trace: 'retain-on-failure',
    viewport: { width: 1280, height: 720 },
    headless: !isVisible,
  },
  webServer: { command: 'node scripts/lib/serve-dashboard.js', port: 4173, reuseExistingServer: true, timeout: 15000 },
};
