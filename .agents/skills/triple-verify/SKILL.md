---
name: triple-verify
description: "Triple verification — 3 enfoques, thresholds por zona, modos !ship/!fast/!draft"
triggers: "Triple verify, triangulate, 3 enfoques, !ship, !listo, !fast, !draft"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Triple verification — 3 enfoques, thresholds por zona, modos

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
- `!ship/!listo` → quality-gate → triple-verify (por zona) → commit-crafter → commit+push
- `!fast` → quality-gate → commit+push (skip verify)
- `!check` → quality-gate only (no commit)
- `!draft` → no gates
- (no keyword) → zona determina verify depth

**quality-gate ALWAYS mandatory** in `!ship`/`!fast`/`!check` regardless of zone. Zone only affects triple-verify, NOT quality-gate.

**Zone routing** (verify depth, when keyword didn't route):
- Verde → SKIP verify → quality-gate if commit
- Amarilla ≤10L → quality-gate
- Rojo/Amarilla >10L → TRIPLE VERIFY (E1+E2+E3 parallel)
- Fail → STOP + evidence · Pass → continue

## Rules
1. **3 DISTINCT approaches**: behavior + quality + compilation
2. **Default-FAIL**: no evidence of 3 steps → not verified
3. **Build mandatory** for compilable code
4. **!ship = responsibility**: quality-gate NEVER optional
5. **capture-learnings** (inline): run `scripts/session-miner.ps1 -Mode scan -Json` post-task or pre-commit. Parse JSON for new patterns → store in `.learnings/`. `mem_save` decisions/bugfixes to Engram. Skip if unavailable. Stage `.learnings/`.
6. **Override**: `!ship --no-verify` emergency only
7. **Self-improvement override**: difficulty levels from CYCLE.md override verify depth

## References
quality-gate · code-review-agent · judgment-day · commit-crafter · CYCLE.md

## Anti-Patterns
Ship without quality-gate · Two approaches instead of three · Skip build for compilable code · Ignore zone thresholds · !ship --no-verify as default
