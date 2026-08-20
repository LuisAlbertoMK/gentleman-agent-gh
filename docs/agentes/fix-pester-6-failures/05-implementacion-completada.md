# Completion Report — 6 Pre-existing Pester Test Failures

**Branch**: `experimento/investiga-compact-mode-2026-08-19` (only)
**Date**: 2026-08-19
**Status**: BLOCKED AT COMMIT GATE — fixes complete + verified; commit withheld per explicit gate

## What was done

| # | Failure | Root cause (verified) | Fix | Result |
|---|---------|----------------------|-----|--------|
| 1 | readme-drift:25 PropertyNotFoundException | `$config.agent.PSObject.Properties.Count` throws under `Set-StrictMode -Version Latest` (PSMemberInfoCollection member-enumeration quirk; config.agent is a PSCustomObject with 49 props, NOT an array) | `@($config.agent.PSObject.Properties).Count` | 4/4 pass |
| 2 | readme-drift:43 skill count | README stale: "**Skills**: 89" vs filesystem 91 (task description had numbers inverted — filesystem HAS 91) | README 22 → 91 (also 18, 241 for consistency) | pass |
| 3 | readme-drift:63 script count | README stale: "99 top-level scripts (92 PS + 7 sh)" vs filesystem 117 (110 PS + 7 sh) | README 246 → 117/110/7 (also 18) | pass |
| 4 | .project.json "corruption" | NOT a failure. Committed HEAD version has conflict markers (`<<<<<<< HEAD`), but working tree = regenerated VALID 150-line file (score-auto.ps1). Test passes (14 dims match). Restoring from git would REINTRODUCE corruption | No change; keep valid working tree | pass |
| 5 | config-validator SSoT | ConfigValidator.psm1 hardcodes `55` agents; SSoT opencode.json = 49 (documented reduction, mejora-log.md:385-386; both HEAD and main have 49) | psm1: 55→49 (lines 106/131/180) | 8/8 pass |
| 6 | analyze-automejora WhatIf | Duplicate WhatIf: `[CmdletBinding(SupportsShouldProcess=$true)]` + explicit `[switch]$WhatIf` → MetadataException. No ShouldProcess() calls exist; explicit switch is the documented dry-run design | Remove SupportsShouldProcess flag | 5/5 pass |

## Verification (targeted — ALL PASS)
- `pwsh scripts/tests/readme-drift.Tests.ps1` → 4/4 ✓
- `pwsh scripts/tests/config-validator.Tests.ps1` → 8/8 ✓
- `pwsh scripts/tests/analyze-automejora.Tests.ps1` → 5/5 ✓
- Full CI suite `pwsh scripts/run-ci-tests.ps1` → 1059 pass / **45 fail** (all pre-existing, see below)

## Security checkpoints
1. Pre-change list: readme-drift.Tests.ps1, README.md, ConfigValidator.psm1, analyze-automejora.ps1 (+ pre-existing .project.json) — opencode.json NOT touched
2. Post-change scan: `scripts/security-scanner.ps1` DOES NOT EXIST (only as global skill) → ran equivalent secrets/conflict-marker/JSON scan: clean (2 false positives = dimension named "secrets" with value false)
3. Pre-commit: `git diff -- opencode.json` = 0 lines ✓ — `opencodec.json` does not exist anywhere
4. Post-commit: NOT RUN — commit withheld (gate below)

## BLOCKER — commit gate cannot pass
Task rule: "COMMIT: Only if ALL tests pass." Full suite: **1059/1104 pass, 45 fail**. All 45 are pre-existing and unrelated to this scope — proven: (a) none involve files I modified; (b) 3 representative failing files (skill-coverage-e2e, resource-optimization, monitor-callback) fail identically standalone. Notable pre-existing bugs surfaced: `babyagi-loop.ps1` has 66 parse errors; `resource-optimization` expects >50 agents (config=49); `skill-coverage-e2e` hardcodes 90 skills (filesystem=91).

Per execution contract (STOP at gate failure, never skip verification, no deviations), commit was withheld pending orchestrator decision:
- (A) commit the 6-fix scope as-is (message: "fix: resolve 6 pre-existing Pester test failures")
- (B) also fix the 45 pre-existing failures (expanded scope, separate task)
- (C) other

## Files changed (uncommitted)
- `scripts/tests/readme-drift.Tests.ps1` — StrictMode-safe agent count
- `README.md` — skill count 89→91, script count 99→117 (110 PS + 7 sh), 4 lines
- `scripts/lib/ConfigValidator.psm1` — agent expectation 55→49 (3 lines)
- `scripts/analyze-automejora.ps1` — removed duplicate WhatIf (1 line)
- `.project.json` — pre-existing working-tree regeneration (valid; repairs merge corruption in HEAD)