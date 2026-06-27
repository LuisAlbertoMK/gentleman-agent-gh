---
name: triple-verify
description: "Triple verification — 3 enfoques, thresholds por zona, modos !ship/!fast/!draft"
triggers: "Triple verify, triangulate, 3 enfoques, !ship, !listo, !fast, !draft"
license: Apache-2.0
metadata:
  tags: [engineering, quality]
  author: gentleman-vMK
  version: "1.2"
  changelog: "1.2: karpathy compress"
  dependencies: [quality-gate, code-review-agent, commit-crafter, session-miner]
---
## Zones
Zones, thresholds, verify depth defined in `review-rules.jsonc`.
- **Roja**: full triple-verify (E1+E2+E3)
- **Amarilla**: verify if diff > threshold lines
- **Verde**: skip verify, quality-gate only
- Context zones in `context_zones`, workflow modes in `modes`
- **Edit `review-rules.jsonc` — NOT this file**

## 3 Approaches
| E1 — Testing | E2 — Static | E3 — Build/Runtime |
|---|---|---|
| Unit/integration/e2e | Lint, 4R, secrets | Build, dry-run, schema |
| Tests pass, bug repro | No regressions | Build OK, runtime checks |
| Schema validate, PSSA | Lint, 4R review | Dry-run, `-WhatIf` |

## Workflow

**Mode routing** (keyword overrides):
- `!ship/!listo` → quality-gate → triple-verify (por zona, incl. capture-learnings) → commit-crafter → commit+push
- `!fast` → quality-gate → commit+push (skip verify)
- `!check` → quality-gate only (no commit)
- `!draft` → solo aviso (no gates)
- (sin keyword) → zona determina profundidad verify

**quality-gate ALWAYS mandatory** in `!ship`/`!fast`/`!check` regardless of zone. Zone only affects triple-verify (E1+E2+E3), NOT quality gate.

**Zone routing** (verify depth, only when keyword didn't route):
- Verde → SKIP verify → quality-gate si hay commit
- Amarilla ≤10L → quality-gate
- Rojo/Amarilla >10L → TRIPLE VERIFY (E1+E2+E3 parallel)
- Falla? → STOP + evidencia · Pasa → continuar

## Rules
1. **3 DISTINCT approaches**: behavior + quality + compilation
2. **Default-FAIL**: no evidence of 3 steps → not verified
3. **Build mandatory** for compilable code
4. **!ship = responsibility**: quality-gate NEVER optional
5. **capture-learnings** (inline — previously separate skill): run `$env:GENTLEMAN_AGENT_ROOT\scripts\session-miner.ps1 -Mode scan -Json` after task completion or pre-commit. Parses JSON output for new pattern proposals → stores in `.learnings/`. Also `mem_save` significant decisions/bugfixes to Engram. Skip gracefully if session-miner unavailable. Stage `.learnings/` files for commit tracking.
6. **Override**: `!ship --no-verify` emergency only
7. **Self-improvement override**: difficulty levels from CYCLE.md override verify depth

## References
quality-gate · code-review-agent · judgment-day · commit-crafter · CYCLE.md
