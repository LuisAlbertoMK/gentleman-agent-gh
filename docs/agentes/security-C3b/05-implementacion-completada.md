# C3b (Security Subset) — Implementation Completed

- **Protocol**: v3, security subset C3b
- **Agent**: gentleman-implementer-sub
- **Date**: 2026-08-07
- **Branch**: experimento/mejora-autonoma-v3-2026-08-07
- **Commits**:
  - `f5031ca0` — fix(security): npm/pip/yarn/pnpm/bun deny floor in auto+semi permission templates (C3b)
  - `d935241f` — fix(ci): tag-push release gated on Quality Gate conclusion (C3b)

## Scope executed (strict, 2 files + test extension)

| Path | Change |
|---|---|
| `scripts/lib/permission-templates.json` | Gap 1 — npm/pip/pip3/yarn/pnpm/bun deny floor added to `auto` and `semi` bash blocks; legitimate `npm run`/`npm test` (both modes) + `npm ci` (auto only) + `pip freeze/list/show` (both modes) preserved with explicit allow |
| `opencode.json` | REGENERATED derived artifact (required by pre-commit [14/15] + CI `node scripts/lib/generate-opencode-config.js --validate`). 240 changed lines = only the npm/pip family rules across 5 auto + 5 semi agents; no unrelated drift (verified by diff filter) |
| `.github/workflows/release.yml` | Gap 2 — new `quality-gate-check` job (runs on both release paths; on tag-push it queries the Quality Gate workflow runs and `core.setFailed` unless a completed run with `conclusion == success` exists for the tag commit) + `release: needs: quality-gate-check` |
| `scripts/tests/permission-gate.Tests.ps1` | Extended with `Describe "SSoT supply-chain deny floor (permission-templates.json)"` — 17 new config-layer cases (longest-token-prefix matcher over the SSoT rules) |

## DoD verification (binary)

| DoD item | Result |
|---|---|
| `npm install evil-pkg` => deny (auto) / deny (semi) | PASS — SSoT: auto `deny`, semi `deny`; Pester asserts both |
| `pip install numpy` => deny (auto) | PASS — SSoT `pip *` deny |
| `npm run build` => allow (auto) | PASS — SSoT `npm run *` allow |
| Tag push → quality-gate completion gate enforced | PASS — `release` needs `quality-gate-check`; tag-push path fails unless QG success |
| 0 E2E regressions | PASS — permission-gate battery 103/103 (86 pre-existing + 17 new); regenerate 17/17 checks OK incl. post-write-validate; both commits passed 18/18 pre-commit gate |
| Regla Fowler: 2 atomic commits | PASS — f5031ca0 (deny floor) + d935241f (release gate) |
| JSON valid (permission-templates.json) | PASS — node JSON.parse + generator `--validate` in sync |
| YAML valid (release.yml) | PASS — pyyaml safe_load parses; `on` KeyError is only PyYAML YAML 1.1 boolean resolution, GitHub handles `on` natively |

## Breaker matrix

| # | Attack vector | Expected | Result |
|---|---|---|---|
| 1a | `npm i -g evil` | deny | deny (SSoT `npm *`) |
| 1b | `npx evil` | deny | deny (`npx *` pre-existing) |
| 1c | `pip3 install evil` | deny | deny (`pip3 *`) |
| 1d | `yarn add evil` | deny | deny (`yarn *`) |
| 1e | `bun install evil` | deny | deny (`bun *`) |
| 2a | `npm run build` (auto) | allow | allow (`npm run *`) |
| 2b | `npm test` (auto) | allow | allow (`npm test`) |
| 2c | `npm ci` (auto) | allow | allow (`npm ci *`) |
| 3 | tag push without QG passing | blocked | `release` has `needs: quality-gate-check`; job fails on missing QG success |

Extras covered by the new floor: `pnpm add evil` deny (both), `npm exec -y evil` deny (both — closes SEC-F4; `npm exec` was NOT in any existing allowlist, so per the plan's "if needed (check existing allowlists)" conditional it stays denied).

## Verification evidence

- `Invoke-Pester scripts/tests/permission-gate.Tests.ps1` → **103 passed / 0 failed** (was 86)
- `scripts/regenerate-opencode.ps1 -Yes -Quiet` → `status: ok`, 17/17 checks, size 64710 B ≤ 65536 budget, post-write-validate in sync
- Longest-prefix token simulation (node) over auto+semi blocks → all 22 DoD/breaker commands classified as expected
- Both `git commit`s passed the full 18/18 pre-commit gate (incl. config sync, secrets scan, Pester)

## ESCALATION — runtime gate layer NOT fixed (scope lock violation if attempted)

The delegation stated `scripts/lib/permission-gate-lib.ps1` was **"done in C3a"**. On-disk verification (git + Get-Content) shows the runtime lib is **NOT** updated: `$script:denyPatterns` has no `^npm`, `^pip`, `^yarn`, `^pnpm`, `^bun` entries, and `$script:semiAllowPatterns` still allows `^npm ci`. Consequently:

- `scripts/permission-gate.ps1` / `Get-CommandClass` STILL returns `allow` for `npm install` in auto and `allow` for `npm ci` in semi.
- The behavior-level DoD items are satisfied at the **opencode agent config layer** (permission-templates.json → opencode.json, the SSoT this task owns) but NOT at the **runtime lib layer**.
- I did NOT add lib-behavior tests expecting `deny` (they would fail → E2E regression) nor touch the lib (explicitly FORBIDDEN).

**Required follow-up (C3a/C3c)**: add to `$script:denyPatterns` in `permission-gate-lib.ps1` (and its comment mirror in `permission-gate.ps1:62-89`, plus `scripts/opencode-config/shared-deny-rules.json` if it should stay the global floor):
```
'^npm (install|i|add|ci|exec)(\s|$)',
'^pip install', '^pip3 (install|i)(\s|$)',
'^yarn add', '^pnpm add', '^bun (install|add|i)(\s|$)'
```
while keeping `'^npm test'`, `'^npm run'`, `'^pip (freeze|list|show)'` in `semiAllowPatterns`. Then the lib battery can be extended to assert the same matrix.

## Return Contract

## Decision Taken
Closed C3b Gap 1 (npm/pip deny floor at SSoT layer) and Gap 2 (release gated on Quality Gate) with 2 atomic commits; runtime lib layer left untouched per scope lock and escalated.

## Files Changed
- `scripts/lib/permission-templates.json` — npm/pip/pip3/yarn/pnpm/bun deny floor in auto+semi, legit allows preserved
- `opencode.json` — regenerated from SSoT (derived, required by CI validate + pre-commit [14/15])
- `scripts/tests/permission-gate.Tests.ps1` — +17 SSoT supply-chain cases (103/103)
- `.github/workflows/release.yml` — quality-gate-check job + `needs:` on release

## Key Findings
1. [HIGH] Runtime gate still allows `npm install` (auto) / `npm ci` (semi) — `permission-gate-lib.ps1` lacks npm/pip deny despite "done in C3a"; SSoT layer fixed, runtime layer needs the lib edit (escalated above).
2. [MEDIUM] `shared-deny-rules.json` (global floor, re-asserted by `use-gentleman.ps1`/`sync-global.ps1`) also lacks npm/pip deny — keeping it out of scope left a second config chain unpatched.
3. [INFO] `npm exec` intentionally denied in both modes (not in any existing allowlist; closes SEC-F4 vector).
4. [INFO] Two layered permission chains exist (SSoT templates → opencode.json; semi-agents.json + shared-deny-rules → expand-config) — SSoT edit alone does not propagate to the semi-agents chain (pre-existing layering drift, documented 2026-08-01/07-30 analyses).

## Nuance
- The `-Force` breaker semantic only upgrades `ask`→`allow` in `permission-gate.ps1`; it never overrides `deny`. For `npm ci` to remain usable in auto (breaker 2) the SSoT therefore keeps explicit `npm ci *: allow` — it is the *deny floor* on `npm *` that changes, not the legit CI path.
- The on-disk test file (440 lines) was newer than the Read-tool snapshot (394) — a C3a-era "Unicode whitespace" Describe already existed and was preserved untouched.
- Release gating deliberately prefers "correctness > speed": if a tag is pushed while QG is still running, the tag-push path blocks; the subsequent QG completion re-triggers Release via the `workflow_run` path.
