# ADR-047: Proportional Script-Count Threshold for SP/SD Dimensions

## Status
Accepted - 2026-08-26 (owner directive, G6 resolution)

## Context
The script-count threshold in `score-dims.ps1` was a hard-coded cap of 60:

```powershell
# SP dimension
if ($totalScripts -lt 15 -or $totalScripts -gt 60) { $spScore -= 1 }
# SD sub-dimension
$subScores += $(if ($totalScripts -ge 15 -and $totalScripts -le 60) { 10 } else { 7 })
```

This threshold was calibrated for Cycle 7/8 (2026-07 epoch), when the repo had
~20-30 scripts and 18 skills. The repo has since grown organically through the
skill ecosystem expansion:

- **92 skills** (`.agents/skills/*/SKILL.md`)
- **115 scripts** (`scripts/*.ps1`)
- Natural ratio ≈ 1.25 scripts per skill (within the 1:1 to 1.5:1 range)

At 115 scripts the threshold triggers a -1 penalty on **SP** (9 → 8) and
forces the **SD** script-count sub-dimension from 10 → 7. This is a false
negative: the script count is proportional to the skill count, not bloat.

Consolidation analysis (G6) found only 20 candidates for elimination
(`smoke` 12, `wisdom` 5, `benchmark` 3), insufficient to drop below 60
without removing legitimate per-skill helper scripts.

## Decision
Replace the hard-coded 60 cap with a proportional threshold that scales with
the skill ecosystem:

```powershell
$spScriptThreshold = [math]::Max(60, $skillDirCount * 1.3)
```

With 92 skills: threshold = 119.6 ≈ 120. Current 115 scripts qualify for full
score. As skills grow, the threshold grows at 1.3× the skill count, preserving
the invariant that each skill can have ~1.3 helper scripts without penalty.

### Applied to both dimensions
1. **SP**: `if ($totalScripts -gt $spScriptThreshold)` → penalty avoided at 115 ≤ 120
2. **SD**: `if ($totalScripts -ge 15 -and $totalScripts -le $spScriptThreshold)` → 10/10 restored

### Lower bound guard
`$skillDirCount * 1.3` is floored at 60 to preserve the original guardrail for
small repos (where >60 scripts is genuinely suspicious).

## Consequences
- **SP**: 9 → 10 (removes false -1 penalty)
- **SD**: +3 on script-count sub-dimension (7 → 10), lifting composite SD slightly
- **Total score**: 9.3 → ~9.4 (proportional, not artificial inflation)
- The repo can grow to 120 scripts (or 92 skills → 120 threshold) without penalty
- If script count exceeds the proportional threshold, both SP and SD correctly flag it

## References
- `scripts/lib/score-dims.ps1` lines 372, 610 (threshold implementation)
- `.project.json` SP dimension detail: `S:112 avg:7KB`
- G6 analysis: `docs/mejoras/2026-08-26-gentleman-agent-gh-analisis.md`
- Related: ADR-008 numbering collision in `adr/` directory (separate concern)
