# G3/G4 Inter-Track CA Drift — Verification Fix

Live checks `2026-08-28`. Branch `fix/g3-g4-docs-verify`. Docs-only.

## G3 — gh remote verification
- `git remote -v` correct (`confidence: high`, live check).
- `gh` not installed on this host (`confidence: high`).
- Both items already documented in `RUNBOOK.md` entry; no code change needed (`confidence: high`).

## G4 — inter-track CA drift
`.learnings/inter-track.json`:
- `count: 29` (not 10), target `30`, `CA: 9.7` (not 3.0) (`confidence: high`).
- BITACORA cycle-30 `CA10` requirement: `BITACORA.md` states `CA10` needs exactly **30**; current drift is **1**, not 20 (`confidence: high`).

### Corrected semantics (root cause)
- `count` = interactions within the **current cycle**, not cycles closed — see `score-dims.ps1:468` (`confidence: high`).
- Therefore a naive proposal to bump `count → 12` would wrongly compute `CA = 4.0` (`12 / 3 = 4.0`), misrepresenting drift (`confidence: medium`, arithmetic inference).
- **No count change needed yet** — current `29` already satisfies nothing mandatory and drift is trivial (`confidence: high`).
- Wiring `inter-track.ps1` to `close-session` is **future work**, not this change (`confidence: high`).

### Alternative (recommend verify first)
- If `CA10` at close-time is authoritative, incrementing `count 29 → 30` would align.
- **Recommend verifying the close-time count before any increment** (`confidence: medium`).

## Decision
Docs only. No `inter-track.json`, `RUNBOOK.md`, or other files modified.
