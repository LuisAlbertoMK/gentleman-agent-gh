# C28 — C9 check-token-budget: Script Compression (Completion Report)

**Date**: 2026-08-15
**Task**: Token Budget Recovery — compress over-budget scripts (safe mode)
**Agent**: implementer (plan-execution) → CYCLE.md Pilar 1 ("Script Performance — compress scripts >8KB")

## What was done

Karpathy-style read→compress→verify loop on the 8 scripts >8KB, with per-file syntax verification and behavioral diff against `git HEAD`. Cuts applied ONLY to: help-block prose, decorative banner comments, verbose prose comments, and cosmetic output separators. **Zero logic, signature, or CLI behavior changes.**

## Per-file results (before → after, % saved)

| File | Before | After | Delta | % |
|------|--------|-------|-------|---|
| scripts/use-gentleman.ps1 | 24,455 | 21,675 | −2,780 | −11.4% |
| scripts/setup-machine.ps1 | 17,706 | 17,458 | −248 | −1.4% |
| scripts/skill-graph.ps1 | 16,620 | 15,330 | −1,290 | −7.8% |
| scripts/delegation-registry.ps1 | 15,855 | 14,904 | −951 | −6.0% |
| scripts/analyze-automejora.ps1 | 14,565 | 13,986 | −579 | −4.0% |
| scripts/setup-machine.sh | 13,833 | 11,688 | −2,145 | −15.5% |
| scripts/pssa-gate.ps1 | 13,544 | 13,544 | 0 | 0% (NO-OP) |
| scripts/cross-ref-check.ps1 | 12,862 | 12,619 | −243 | −1.9% |
| **TOTAL** | **129,440** | **121,204** | **−8,236** | **−6.4%** |

## Verification performed

1. **Syntax (all 8)**: PowerShell `Parser::ParseFile` clean for all 7 .ps1; `bash -n` (Git Bash, not WSL stub) clean for setup-machine.sh.
2. **Behavioral diff vs HEAD** (safe runs only):
   - `use-gentleman.ps1 -DryRun -Yes -Json` → `status: ok`, `dry_run: true`, identical JSON structure
   - `skill-graph.ps1 -Task "security audit" -Format Json` → identical (only nondeterministic tie-order of 2 equal-score skills — proven by same-version double run)
   - `cross-ref-check.ps1 -Json` → identical except timestamp + hashtable key order (proven nondeterministic)
   - `analyze-automejora.ps1 -WhatIf` → byte-identical
   - `delegation-registry.ps1 list/register/poll` (temp repo) → byte-identical + register→running flow works
   - `setup-machine.sh --help` → byte-identical
3. **Pester**: `tests/script-documentation.Tests.ps1` 4/4 PASSED (mandatory help tags intact, no duplicated help blocks); `tests/health-check.Tests.ps1` 8 passed / 0 failed / 1 skipped. No `tests/*token-budget*` or `tests/*pipeline*` files exist.
4. **check-token-budget.ps1 -BudgetBytes 2000 -Json**: still `passed:false` with 82 files over — **unchanged and expected**: that gate measures `skills`/`prompts` averages, NOT scripts. Scripts are not part of this gate's measurement; the compression targets the CYCLE.md Pilar 1 script-size pillar instead.

## Target vs achieved

- Task target: ≥30% total reduction. **Achieved: 6.4%** — the 30% target is **not achievable with safe cuts**: the 8 files are code-dense (their combined comment surface was only 13,289B ≈ 10.3% of the total; comment removal + whitespace collapse yields at most ~8-10%). Reaching 30% would require touching logic/CLI behavior, which the safe-mode protocol forbids.

## Constraints honored

- ✅ No function signature, exported command, or CLI behavior changed
- ✅ No `[Parameter()]`, `#requires`, `#Requires` removed
- ✅ `.learnings/` and `.project.json` untouched
- ✅ No file failed the safety gate → no `git checkout` rollback needed
- ✅ PSSA-critical `SuppressMessage` attributes left untouched (justification prose retained)

## Rollback

Not needed — no syntax failures. To revert: `git checkout -- scripts/use-gentleman.ps1 scripts/setup-machine.ps1 scripts/skill-graph.ps1 scripts/delegation-registry.ps1 scripts/analyze-automejora.ps1 scripts/setup-machine.sh scripts/cross-ref-check.ps1`

## 4-Field Contract

### Decision Taken
Compressed 7 of 8 over-budget scripts (help prose, banner comments, whitespace-only decoration) with zero functionality loss; pssa-gate.ps1 left untouched as already at compression floor; total −8,236B (−6.4%).

### Files Changed
- scripts/use-gentleman.ps1 (24,455 → 21,675B)
- scripts/setup-machine.ps1 (17,706 → 17,458B)
- scripts/skill-graph.ps1 (16,620 → 15,330B)
- scripts/delegation-registry.ps1 (15,855 → 14,904B)
- scripts/analyze-automejora.ps1 (14,565 → 13,986B)
- scripts/setup-machine.sh (13,833 → 11,688B)
- scripts/cross-ref-check.ps1 (12,862 → 12,619B)
- scripts/pssa-gate.ps1 — untouched (already minified, 96B comment surface; it IS the quality gate)

### Key Findings
1. [MEDIUM] 30% target unreachable via safe cuts — files are code-dense; comment surface was only ~10% of bytes. Achieved −6.4% (−8,236B), the safe maximum. — evidence: comment inventory analysis (13,289B comments across 8 files) — recommendation: further reduction requires logic-level cuts (out of scope per safe-mode protocol).
2. [LOW] `check-token-budget.ps1` does NOT measure scripts (only skills+prompts averages; still 82 over) — the gate's over-budget count cannot move from script compression. This task addresses CYCLE.md Pilar 1 (script size pillar) instead.
3. [LOW] `skill-graph.ps1` + `cross-ref-check.ps1` outputs are nondeterministic between runs (non-stable Sort-Object on tied scores; hashtable key order in ConvertTo-Json) — pre-existing, NOT caused by compression; verified via same-version double runs.

### Nuance
- `pssa-gate.ps1` is a deliberate NO-OP: it is already written in ultra-minified style (13.5KB/187 lines, ~96B of comments) and it gates the whole repo's PSSA — compressing it would be pure risk with ~0 reward. `confidence: high`
- Write-Host separator lines in use-gentleman.ps1 (`═══` runs, 43→24 chars) were shortened — cosmetic decoration only, no informational content changed; this matches the task's diagnosed target "verbose Write-Host verbosity". `confidence: high`
- Get-Help `-Parameter TargetDir` quirk on use-gentleman.ps1 (fails to resolve) exists identically on HEAD — pre-existing, no regression. `confidence: high`
- Byte baselines in this report use the actual filesystem `Length`; git-show comparisons earlier in the session showed slightly larger "old" sizes due to `Out-String` trailing-newline artifacts — deltas are unaffected.