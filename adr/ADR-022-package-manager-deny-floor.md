# ADR-022: Package Manager Deny Floor for auto-sub Templates

## Status
Accepted — 2026-08-08

## Context
The `auto-sub` permission template had `"bash": {"*": "allow"}` with **zero deny rules**.
This meant any `gentleman-*-sub-auto` agent could execute `npm install evil`,
`pip3 install evil`, `bun install`, etc. without restriction — a critical supply-chain
risk for auto-mode subagents that operate without human oversight.

Additionally, the global `permission.bash` in `opencode-base.json` was missing all
package-manager install commands from its deny list, leaving the fallback default
vulnerable.

## Decision
Added package-manager deny floor to:

1. **`opencode-base.json`** (global permission.bash) — deny floor for npm, pip, pip3,
   pnpm, yarn, bun with safe-command allows (npm ci, npm run, npm test, pip freeze/list/show).

2. **`permission-templates.json` `auto-sub` template** — same deny floor, mirroring the
   existing `auto` template. This template is used by 4 subagent twins:
   `gentleman-deep-sub-auto`, `gentleman-quick-sub-auto`, `gentleman-codex-sub-auto`,
   `gentleman-implementer-sub-auto`.

3. **`permission-templates.json` `semi` template** — `npm ci` correctly DENIED
   (via `npm *` → deny catch-all). Semi mode requires human approval for ALL npm
   operations except read-only `npm run` and `npm test`. This was verified against
   the existing test `permission-gate.Tests.ps1:DENIES npm ci in semi`.

## Consequences

| Command | auto-sub | semi | auto |
|---------|----------|------|------|
| `npm install evil` | **deny** | deny | deny |
| `npm i evil` | **deny** | deny | deny |
| `npm exec evil` | **deny** | deny | deny |
| `pip3 install evil` | **deny** | deny | deny |
| `yarn install` | **deny** | deny | deny |
| `bun install` | **deny** | deny | deny |
| `npm ci` | allow | **deny** (human approves) | allow |
| `npm run build` | allow | allow | allow |
| `npm test` | allow | allow | allow |
| `pip freeze` | allow | allow | allow |

The `semi` template intentionally denies `npm ci` — even though it's lockfile-safe,
semi mode requires explicit human approval for any package resolution operation.

## Validation
- `regenerate-opencode.ps1 -Yes`: 21/21 checks pass
- `permission-gate.Tests.ps1`: 108/108 tests pass
- `generate-config.Tests.ps1`: 12/12 tests pass
- Breaker: 13 attack vectors blocked, 9 safe commands allowed (22/22 PASS)
