# Analysis Index — gentleman-agent-gh

> **Purpose**: Central index for all analysis documents. Updated when new analyses are created or executed.
> **For the orchestrator**: Run `glob docs/mejoras/*.md` + `ctx_search("analysis:gentleman-agent-gh")` before answering gap questions.

## Table of Contents

| Date | File | Domain | Key Finding | Status |
|------|------|--------|-------------|--------|
| 2026-07-31 | [`skill-usage-audit`](2026-07-31-gentleman-agent-gh-analisis.md) | Skills | Uso real (DB 716 sessions): 3 skills muertas, runtime `skill` roto por misconfig (plugin lazy-loader `skill/` vs `skills/`), 3 refs STALE skill-creator, 1 solape real. | 🏁 active (plan) |
| 2026-07-31 | [`tests-perf`](2026-07-31-gentleman-agent-gh-tests-perf.md) | Testing/Perf | Baseline suite: 553s secuencial / 150.3s paralelo (4.3×). Outliers: _e2e nested+coverage 178s, ScoreIntegration 88s = 42%. CRÍTICO: parallel unsafe (estado compartido: .gentleman-mode, BITACORA, $env:USERPROFILE). Proyección 150s→25-40s. | 🏁 active (plan) |
| 2026-07-29 | [`global-analysis`](2026-07-29-gentleman-agent-gh-global-analysis.md) | Multi-dimension | 15 findings: 84% sin tests (CRITICAL), score drift 9.1→6.2, .gitleaks vacío, -auto deny lists, bash-safe bypasses, BITACORA 121 dupes. | 🏁 active |
| 2026-07-29 | [`seo-skill`](2026-07-29-seo-skill-analisis.md) | SEO | v2.1→v3.0 upgrade | ✅ completed |
| 2026-07-28 | [`tdd-testing`](2026-07-28-gentleman-agent-gh-analysis.md) | Testing | 7 findings — validate-write-scope tests (26), close-session tests (43), restore/forge-rollback tests (18), strict_tdd, pre-commit hook, CodeCoverage, Mock. | ✅ 7/7 completed |
| 2026-07-28 | [`orchestrator-self-analysis`](2026-07-28-orchestrator-self-analysis.md) | Meta-Architecture | Pre-Answer Evidence Gate + Confidence Calibration. 7/8 findings implemented in `6270c57e`. | ✅ 7/8 completed |
| 2026-07-28 | [`permission-modes`](2026-07-28-permission-modes-analysis.md) | Permissions | 3 permission modes (manual/semi/auto). switch-mode.ps1 + permission-gate.ps1 + .gentleman-mode created. | ✅ completed |
| 2026-07-24 | [`execution-report`](2026-07-24-gentleman-agent-gh-ejecucion.md) | Execution | 12/15 findings implemented across 12 files. 3 skipped. Pipeline `!ejecutar` v1.1. | ✅ completed |
| — | [`PERFORMANCE-PLAN`](PERFORMANCE-PLAN.md) | Performance | `!ship` ~46s→32s. P0-1 (incremental PSSA), P0-2 (ThreadJob). 7 items remaining. | ⏸️ partial (2/9 done) |

> **Archived**: 12 stale/superseded analyses moved to `archived/` — Jul 13, 14, 18, 21 (×3), 24 (×1), state JSONs (×4), opencode-diff.

## Trend Summary

- **Total documents**: 8 active (7 analyses + 1 performance plan)
- **Archived**: 12 stale/superseded documents
- **Completed**: 4 (tdd-testing, orchestrator, permission-modes, execution-report)
- **Partial**: 1 (PERFORMANCE-PLAN 2/9)
- **Active**: 2 (global-analysis, skill-usage-audit)

## Quick Reference

| File | Most Critical Takeaway |
|------|----------------------|
| `global-analysis (07-29)` | 🏁 15 findings — security hardening en progreso. `opencode.json` -auto agents pending human edit. |
| `tdd-testing (07-28)` | ✅ 7/7: 100+ tests added for security-critical scripts. |
| `orchestrator-self-analysis (07-28)` | ✅ Fixed — Pre-Answer Evidence Gate + Confidence Calibration. |
| `permission-modes (07-28)` | ✅ 3 modes (manual/semi/auto) implemented. switch-mode.ps1 + mode-gate.ps1. |
| `execution-report (07-24)` | ✅ 12/15 findings implemented. |
| `PERFORMANCE-PLAN` | ✅ 9/9 items complete. pssa-gate granular cache: post-commit ~5.5s (antes 33.4s miss). score-auto recompute 35.2s→12.5s. |

## For Orchestrators

Before answering "what's missing" or gap questions:

1. Read this index
2. Check if your topic was already analyzed
3. If yes → `Read` that analysis file before answering
4. If novel → flag as `confidence: unvalidated`
