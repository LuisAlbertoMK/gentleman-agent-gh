# SDD Delta Spec: gentleman-dashboard — Smoke E2E

## ADDED Requirements

### Requirement: Static server serves on port 4173
The server `scripts/lib/serve-dashboard.js` MUST:
- Use Node `http.createServer` (no external dependencies)
- Serve files from `docs/dashboard/` directory
- Listen on port 4173
- Return 200 for `index.html` and `data.json`
- Return 404 for non-existent files
- Set correct Content-Type headers (text/html, application/json)

### Requirement: E2E test validates HTTP 200
The test `e2e/dashboard.smoke.js` (Node fetch, no browser) MUST:
- Start the static server on port 4173
- Wait for server ready
- `fetch('http://localhost:4173/')` returns HTTP 200
- `fetch('http://localhost:4173/data.json')` returns HTTP 200
- Response body of `/` contains `<title>` and card markup
- Response body of `/data.json` parses as valid JSON
- Shutdown server cleanly

### Requirement: E2E test validates data.json parses
The smoke test MUST verify:
- `data.json` Content-Type is `application/json`
- JSON parses without error
- Required keys exist: generatedAt, agents, skills, gate, projectScore
- `agents.total` > 0
- `skills.total` > 0

### Requirement: Playwright test validates cards render
The test `e2e/dashboard.spec.js` (Playwright) MUST:
- Start server on 4173
- Navigate to `http://localhost:4173/`
- Wait for network idle
- Assert 4 cards visible (`.card` or `[data-card]`)
- Assert each card's `innerText` is non-empty (length > 0)
- Assert no console errors (page.on('console', filter errors))
- Assert skills table has ≥1 row (or "No over-budget skills" message)

### Requirement: Tests run in CI without browser (smoke) and with browser (full)
- `dashboard.smoke.js` runs with `node` only (no Playwright install)
- `dashboard.spec.js` runs with Playwright (headed or headless)
- Both tests exit 0 on success, non-zero on failure

## Scenarios

### Scenario: Happy path — smoke test passes
Given generator has run and `docs/dashboard/data.json` exists
When `node e2e/dashboard.smoke.js` executes
Then server starts on 4173
And GET / returns 200
And GET /data.json returns 200 with valid JSON
And agents.total > 0
And skills.total > 0
And server stops
And process exits 0

### Scenario: Happy path — Playwright test passes
Given generator has run and server is running on 4173
When `npx playwright test e2e/dashboard.spec.js` executes
Then page loads
And 4 cards visible with non-empty innerText
And skills table present
And no console errors
And test exits 0

### Scenario: Edge case — server already running on 4173
Given port 4173 is in use
When smoke test starts
Then it detects conflict and exits non-zero with clear message "Port 4173 in use"

### Scenario: Error case — data.json missing
Given `docs/dashboard/data.json` does not exist
When smoke test runs
Then GET /data.json returns 404
And test exits non-zero

### Scenario: Error case — cards empty innerText
Given data.json has agents.total=0 (edge)
When Playwright test runs
Then card innerText assertion fails
And test exits non-zero

### Scenario: Cleanup — server killed on test failure
Given smoke or Playwright test fails mid-run
Then server process is terminated (no orphaned process on 4173)