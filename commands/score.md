---
description: Score auto-update across 13 dimensions + docs sync
---

You are executing `!score`. Measure project health across 13 dimensions and sync the score docs.

Steps:

1. **Resolve script root**:
   `$root = $env:GENTLEMAN_AGENT_ROOT; if (-not $root -or -not (Test-Path "$root\scripts\score-auto.ps1")) { $root = Split-Path $PSScriptRoot -Parent }`
2. **Run the score**: `& "$root\scripts\score-auto.ps1"` (add `-Json` for machine-readable output, `-Quiet` for a one-line summary). The script caches by content hash — use `-Json` if you need fresh numbers.
3. **Docs sync**: verify `docs/operations/project-score.md` reflects the new composite and per-dimension scores; update it if stale.
4. **Cross-ref**: run `& "$root\scripts\cross-ref-check.ps1"` and include integrity results.
5. **Report**: previous vs current composite, biggest gain, biggest regression. List dimensions below 7 with a one-line remediation each. Suggest follow-ups; do NOT implement them in this command.
