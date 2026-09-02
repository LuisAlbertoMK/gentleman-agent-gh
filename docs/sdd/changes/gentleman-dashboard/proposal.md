# SDD Change Proposal: gentleman-dashboard

## Intent
Create a self-contained dashboard visualizing agent/skill health, quality gate metrics, and project score — zero external dependencies, served via tiny Node static server for E2E verification.

## Scope (In / Out)

### In — New Files
- `scripts/generate-dashboard-data.ps1` — #requires 7, PESTER_TEST=1 writes temp, emits `docs/dashboard/data.json`
- `docs/dashboard/index.html` — vanilla HTML+CSS+JS <50KB, dark OKLCH, semantic+ARIA, fetch('./data.json'), 4 cards + skills table, responsive
- `scripts/lib/serve-dashboard.js` — Node HTTP static server (port 4173, no deps)
- `scripts/tests/generate-dashboard-data.Tests.ps1` — validates JSON keys, counts match reality, PESTER_TEST isolation
- `e2e/dashboard.spec.js` — Playwright: page loads, cards render counts>0, no console errors
- `e2e/dashboard.smoke.js` — node fetch assertions, no browser dep (fallback)

### Out
- No modifications to `.githooks/`, `opencode.json`, or existing scripts
- No CDN dependencies, no framework, no build step
- No changes to registry.yaml beyond archive phase

## Approach
- **Backend**: Single PS7 script reads opencode.json agents count, scans `.agents/skills/*/SKILL.md` for token_budget frontmatter, runs `fast.exe --gate --json` for crossRef/tokenBudget, reads `.project.json` score — emits structured JSON to `docs/dashboard/data.json`
- **Frontend**: Single self-contained HTML file with inline CSS (OKLCH dark theme, @layer, container queries) and JS (fetch, render 4 metric cards: gate pass/fail, fast elapsed/crossRef/tokenBudget, agents total, skills budgeted/overBudget top5; skills table sortable; responsive grid)
- **Server**: 30-line Node `http.createServer` serving `docs/dashboard/` on 4173 — started by E2E, killed on teardown

## Risks
- **Token budget drift**: 8 skills currently over 3200B budget (fast.exe shows `overBudgetFiles: 8`) — dashboard will surface this; mitigation: unit test validates counts match live scan
- **PESTER_TEST isolation**: Script must not mutate repo when `PESTER_TEST=1` — uses temp files only; verified by test suite running in isolation

## Proposal Path
`docs/sdd/changes/gentleman-dashboard/proposal.md`