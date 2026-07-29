# Analysis Index — gentleman-agent-gh

> **Purpose**: Central index for all analysis documents. Updated when new analyses are created or executed.
> **For the orchestrator**: Run `glob docs/mejoras/*.md` + `ctx_search("analysis:gentleman-agent-gh")` before answering gap questions.

## Table of Contents

| Date | File | Domain | Key Finding | Status |
|------|------|--------|-------------|--------|
| 2026-07-28 | [`permission-modes`](2026-07-28-permission-modes-analysis.md) | Permissions | 3 permission modes (manual/semi/auto). switch-mode.ps1 + permission-gate.ps1 + .gentleman-mode created. `opencode.json` -auto agents pending user apply. | ⏸️ partial (scripts done, agents pending) |
| 2026-07-28 | [`tdd-testing`](2026-07-28-gentleman-agent-gh-analysis.md) | Testing | 7 findings — validate-write-scope tests (26), close-session tests (43), restore/forge-rollback tests (18), strict_tdd, pre-commit hook, CodeCoverage, Mock. | ✅ 7/7 completed |
| 2026-07-28 | [`orchestrator-self-analysis`](2026-07-28-orchestrator-self-analysis.md) | Meta-Architecture | Pre-Answer Evidence Gate + Confidence Calibration. 7/8 findings implemented in `6270c57e`. | ✅ 7/8 completed |
| 2026-07-28 | [`auto-mode-fix`](2026-07-28-session-fix.md) | Permissions | Fixed !auto mode: SHORTCUTS.md updated, .gentleman-mode→auto. Protected files (opencode.json, gentleman-vMK.md) need user apply. | ✅ partial |
| 2026-07-24 | [`deep-analysis`](2026-07-24-gentleman-agent-gh-analisis.md) | Multi-dimension | SSoT, skill count, skill tool, docs 30% stale. 47 findings → top 15. | ✅ 12/15 completed |
| 2026-07-24 | [`execution-report`](2026-07-24-gentleman-agent-gh-ejecucion.md) | Execution | 12/15 findings implemented across 12 files. 3 skipped. Pipeline `!ejecutar` v1.1. | ✅ completed |
| 2026-07-21 | [`session-miner-fix`](5f091774) | Data | Session-miner reconnected: -Mode populate + regex anchoring + 20 Pester tests. close-session passes discoveries/errors. | ✅ fixed |
| 2026-07-21 | [`reliability-analysis`](2026-07-21-gentleman-agent-gh-reliability-analysis.md) | Infra/Architecture | M1-M10: mcp-resilience.ps1 (circuit breaker, health probes, retry), write-scope validation, runbook. | ✅ completed |
| 2026-07-21 | [`engineering-analysis`](2026-07-21-gentleman-agent-gh-engineering-analysis.md) | Engineering | DRY 77KB→18KB. Testing (~10%), ADR, CI caching, script org pending. | ⏸️ partial (3/15) |
| 2026-07-21 | [`deep-analysis-v3`](2026-07-21-gentleman-agent-gh-analisis.md) | Multi-dimension | SSoT ✅, health-check ✅, .dockerignore ✅, N+1 ✅, session-miner ✅. | ✅ resolved |
| 2026-07-18 | [`deep-analysis-v4`](2026-07-18-gentleman-agent-gh-analisis.md) | Multi-dimension | Permission blocks ✅ resolved. Dual routing, return contracts pending. | ⏸️ partial |
| 2026-07-14 | [`token-optimization`](2026-07-14-gentleman-agent-gh-analisis.md) | Performance | AGENTS.md duplication (4,247 tok/turn), skill registry bloat. | ⏸️ pending |
| 2026-07-13 | [`initial-analysis`](2026-07-13-gentleman-agent-gh-analisis.md) | Multi-dimension | Auto-aprendizaje CRÍTICO. Session-miner ✅ fixed, skill-graph status unknown. | ⏸️ pending |
| — | [`PERFORMANCE-PLAN`](PERFORMANCE-PLAN.md) | Performance | `!ship` ~46s→32s. P0-1 (incremental PSSA), P0-2 (ThreadJob). 7 items remaining. | ⏸️ partial (2/9 done) |

## Trend Summary

- **Total documents**: 13 (12 analyses + 1 performance plan)
- **Completed**: 6 (tdd-testing, orchestrator 7/8, execution report, reliability M1-M10, session-miner fix, deep-analysis-v3)
- **Partial**: 4 (permission-modes, auto-mode-fix, engineering 3/15, deep-analysis-v4)
- **Pending**: 2 (token-optimization, initial-analysis)
- **Performance plan**: 2/9 done

## Quick Reference

| File | Most Critical Takeaway |
|------|----------------------|
| `permission-modes (07-28)` | ⚠️ Scripts + mode file done. Agents AUTO en opencode.json pending user apply. |
| `tdd-testing (07-28)` | ✅ 7/7: 100+ tests added for security-critical scripts. |
| `orchestrator-self-analysis (07-28)` | ✅ Fixed — Pre-Answer Evidence Gate + Confidence Calibration. |
| `auto-mode-fix (07-28)` | ✅ SHORTCUTS + .gentleman-mode + mode file updated. Pending opencode.json agents. |
| `reliability-analysis (07-21)` | ✅ M1-M10: mcp-resilience, circuit breaker, write-scope validation. |
| `session-miner (07-21)` | ✅ Fixed: -Mode populate, regex anchoring, 20 tests. |
| `engineering-analysis (07-21)` | DRY ✅ refactored 77KB→18KB. Pending: testing, ADR, CI caching, scripts. |
| `deep-analysis-v3 (07-21)` | ✅ All resolved: SSoT, health-check, .dockerignore, N+1, session-miner. |
| `deep-analysis-v4 (07-18)` | Permission blocks resolved. Dual routing pending. |
| `token-optimization (07-14)` | AGENTS.md duplication — needs re-verification. |
| `initial-analysis (07-13)` | Most items superseded by later fixes. |
| `PERFORMANCE-PLAN` | `!ship` ~46s → ~32s. 7/9 items remaining (P0-3, P1-1-3, P2-1-3). |

## For Orchestrators

Before answering "what's missing" or gap questions:

1. Read this index
2. Check if your topic was already analyzed
3. If yes → `Read` that analysis file before answering
4. If novel → flag as `confidence: unvalidated`
