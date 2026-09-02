module.exports = {
  testDir: 'e2e',
  timeout: 30000,
  use: { baseURL: 'http://localhost:4173' },
  webServer: { command: 'node scripts/lib/serve-dashboard.js', port: 4173, reuseExistingServer: true, timeout: 15000 },
};
