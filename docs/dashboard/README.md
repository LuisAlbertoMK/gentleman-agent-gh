# Gentleman Dashboard

Self-contained health dashboard (no deps, <50KB HTML).

## Generate
```pwsh
pwsh ./scripts/generate-dashboard-data.ps1        # writes docs/dashboard/data.json
pwsh ./scripts/generate-dashboard-data.ps1 -WhatIf # preview only
$env:PESTER_TEST=1; pwsh ./scripts/generate-dashboard-data.ps1 # temp only
```

## Serve
```js
node scripts/lib/serve-dashboard.js // http://localhost:4173/
```

## Test
```pwsh
Invoke-Pester ./scripts/tests/generate-dashboard-data.Tests.ps1
node e2e/dashboard.smoke.js            # no browser
npx playwright test e2e/dashboard.spec.js # needs browsers
```

## Notes
- Port 4173; EADDRINUSE → `Port 4173 in use` + exit 1.
- HTML raw <51200B; inline OKLCH dark, header/main/section/footer.
- Specs: see docs/sdd/changes/gentleman-dashboard/specs/.

## Archive checklist
- Update registry.yaml → archived; move specs to archive/; revert = delete 7 files + data.json.
