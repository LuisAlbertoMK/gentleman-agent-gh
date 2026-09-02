# Tasks: gentleman-dashboard

## Workload Forecast
- Lines: ~810 (150 gen+120 tests+300 html+40 server+80 smoke+80 pw+40 readme)
- 400-line risk: Medium (isolated, no schema/auth, atomic revert)
- Chained PRs: No (single-pr)
- Strategy: TDD RED→GREEN, A→D sequential, no user interaction

## Guard Contract
```
Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: single-pr
400-line budget risk: Medium
```

## Dependencies
```
A (gen+Pester) → B (HTML+server) → C (smoke+playwright) → D (README+verify)
B needs A data.json contract; C needs B server; D needs C green
```

## Resolved Ambiguities
- #5 Port 4173 EADDRINUSE → `console.error("Port 4173 in use")` + `process.exit(0)` with message
- #4 Page size → raw bytes `<51200` (Get-Item).Length, no gzip, inline only

## Cluster A — Backend Generator + Pester

- [ ] **T-A1 RED — Pester tests** `scripts/tests/generate-dashboard-data.Tests.ps1` (1 file)
  - Tests: PESTER_TEST=1 temp isolation, JSON keys/types, counts 58/93/8, fast.exe missing→gate.pass false, git status clean.
  - Maps: generator.spec 4req/5scen + data-contract 3req/3scen =7req/8scen
  - Verify: `PESTER_TEST=1 pwsh -Command "Invoke-Pester ./scripts/tests/generate-dashboard-data.Tests.ps1"` → RED fail; Rollback: delete file

- [ ] **T-A2 GREEN — Generator** `scripts/generate-dashboard-data.ps1` (1 file → `docs/dashboard/data.json`)
  - `#requires -Version 7.0`; PESTER_TEST=1→$env:TEMP else docs/dashboard/data.json; reads opencode.json/skills/fast.exe/.project.json; no throw
  - Verify: `pwsh ./scripts/generate-dashboard-data.ps1; PESTER_TEST=1 pwsh ./scripts/generate-dashboard-data.ps1; git status --porcelain` only data.json; Invoke-Pester green; Rollback: rm script+data.json

## Cluster B — Frontend HTML + Node Server

- [ ] **T-B1 — Dashboard HTML** `docs/dashboard/index.html` (1 file)
  - Inline OKLCH dark @layer, 4 cards (gate/fast/agents/skills top5), sortable table, fetch('./data.json') error role=alert, header/main/section×4/footer aria-labelledby, aria-sort/tabindex, focus-visible, reduced-motion
  - Maps: rendering 4req/6scen + a11y 5req/6scen =9req/12scen
  - Verify: `(Get-Item docs/dashboard/index.html).Length -lt 51200` + landmarks present; Rollback: delete html

- [ ] **T-B2 — Static server** `scripts/lib/serve-dashboard.js` (1 file)
  - http.createServer serves docs/dashboard on 4173, Content-Type html/json, 404 else, EADDRINUSE exit 0
  - Maps: smoke-e2e 1req/1scen
  - Verify: `node scripts/lib/serve-dashboard.js` curl 200 + EADDRINUSE check; Rollback: delete js

## Cluster C — E2E

- [ ] **T-C1 — Smoke (no browser)** `e2e/dashboard.smoke.js` (1 file)
  - Starts server, fetch /→200 has title/cards, /data.json→200 json keys>0, Content-Type, finally kill
  - Maps: smoke-e2e 3req/3scen + cleanup
  - Verify: `node e2e/dashboard.smoke.js` exit 0; rm data.json→404 non-zero; Rollback: delete file

- [ ] **T-C2 — Playwright** `e2e/dashboard.spec.js` (1 file)
  - goto 4173, 4 cards non-empty, table ≥1 row or "No over-budget", no console errors, Delta sort toggles aria-sort
  - Maps: smoke-e2e 1req + rendering sort + a11y keyboard =1req/3scen
  - Verify: `npx playwright test e2e/dashboard.spec.js`; fallback T-C1 if no browser; Rollback: delete file

## Cluster D — Verify Wiring

- [ ] **T-D1 — README + archive** `docs/dashboard/README.md` (1 file)
  - 1-page: generate/serve/test cmds, port/size notes, traceability 21req/26scen table, archive checklist (registry.yaml, specs→archive, revert)
  - Verify: `pwsh ./scripts/generate-dashboard-data.ps1 && node e2e/dashboard.smoke.js && Invoke-Pester` all green; Rollback: delete readme

## Traceability
- 21 req (4+3+4+5+5) / 26 scen (5+3+6+6+6) all mapped above
- Total files: 7 new +1 generated data.json =8; each task ≤10 files
