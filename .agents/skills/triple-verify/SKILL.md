---
name: triple-verify
description: "Triple verification — 3 enfoques, thresholds por zona, modos !ship/!fast/!draft"
triggers: "Triple verify, triangulate, 3 enfoques, !ship, !listo, !fast, !draft"
license: Apache-2.0
metadata:
  tags: [engineering, quality]
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.1: karpathy compress"
  dependencies: [quality-gate, code-review-agent, commit-crafter]
---
## Zones — Declarative (review-rules.jsonc)
Zones, patterns, thresholds, and verify depth are defined in `review-rules.jsonc` at repo root.
- **Roja**: full triple-verify (E1+E2+E3) — see `zones.roja.patterns`
- **Amarilla**: verify if diff > threshold lines — see `zones.amarilla.thresholds.min_lines_for_verify`
- **Verde**: skip verify, quality-gate only — see `zones.verde.patterns`
- Context zones (green/yellow/orange/red) in `context_zones`
- Workflow modes (`!ship`/`!listo`/`!fast`/`!draft`) in `modes`
- **Edit `review-rules.jsonc` to adjust — NOT this file**
## 3 Distinct Approaches
| E1 — Testing | E2 — Static | E3 — Build/Runtime |
|---|---|---|
| Unit/integration/e2e | Lint, 4R, secrets | Build, dry-run, schema |
| Tests pass, reproduce bug | No regressions, edge cases | Build OK, runtime checks |
| Schema validate, PSSA pass | Lint, 4R review | Dry-run, `-WhatIf`, `docker build` |
## Workflow

**Step 1 — Mode routing (keyword overrides everything):**

```
┌─ Modo keyword? ───────────────────────────────────────────────┐
│ !ship/!listo → capture-learnings → quality-gate MANDATORY     │
│               → triple-verify (por zona) → commit-crafter     │
│               → commit+push                                   │
│ !fast        → quality-gate → commit+push (skip verify)       │
│ !check       → quality-gate only (no commit)                  │
│ !draft       → solo aviso (no gates)                          │
│ (sin keyword) → zona determina profundidad verify (paso 2)    │
└───────────────────────────────────────────────────────────────┘
```

**IMPORTANT**: `quality-gate` is ALWAYS mandatory in `!ship`/`!fast`/`!check` mode regardless of zone. The zone only affects whether triple-verify (E1+E2+E3) runs, NOT the quality gate.

**Step 2 — Zone routing (verify depth, only when a keyword didn't already route):**

```
Propuesto → Verde? → SKIP verify → quality-gate si hay commit
         → Amarilla ≤10L? → quality-gate
         → Rojo/Amarilla>10L → TRIPLE VERIFY (E1+E2+E3 parallel)
Falla? → STOP + evidencia · Pasa → continuar
```
## Rules
1. **3 DISTINCT approaches**: behavior + quality + compilation — not 3 identical tests
2. **Default-FAIL**: no evidence of 3 steps → not verified
3. **Build mandatory** for compilable code
4. **!ship = responsibility**: quality-gate is NEVER optional — if you skipped it, you broke the pipeline
5. **capture-learnings**: run `session-miner.ps1 -Mode scan -Json` (if available), stage `.learnings/` changes. No session-miner? Skip gracefully — `.learnings` changes are optionals.
6. **Override**: `!ship --no-verify` emergency only (not recommended)
7. **Self-improvement override**: difficulty levels from CYCLE.md override verify depth
## References
quality-gate · code-review-agent · judgment-day · commit-crafter · CYCLE.md
