# Analysis Index — gentleman-agent-gh

> **Purpose**: Central index for all analysis documents. Updated when new analyses are created or executed.
> **For the orchestrator**: Run `glob docs/mejoras/*.md` + `ctx_search("analysis:gentleman-agent-gh")` before answering gap questions.

## Table of Contents

| Date | File | Domain | Key Finding | Status |
|------|------|--------|-------------|--------|
| 2026-07-28 | [`orchestrator-self-analysis`](2026-07-28-orchestrator-self-analysis.md) | Meta-Architecture | Pre-Answer Evidence Gate + Confidence Calibration. 7/8 findings implemented in `6270c57e`. | ✅ 7/8 completed |
| 2026-07-24 | [`deep-analysis`](2026-07-24-gentleman-agent-gh-analisis.md) | Multi-dimension | SSoT scores compete, skill count triple-desalineado, skill tool roto, docs 30% stale. 47 findings → top 15. | ✅ 12/15 completed |
| 2026-07-24 | [`execution-report`](2026-07-24-gentleman-agent-gh-ejecucion.md) | Execution | 12 of 15 findings implemented across 12 files. 3 skipped/deferred. Pipeline `!ejecutar` v1.1. | ✅ completed |
| 2026-07-21 | [`reliability-analysis`](2026-07-21-gentleman-agent-gh-reliability-analysis.md) | Infra/Architecture | M1-M10 implemented in `5ce4a6b7` — mcp-resilience.ps1 (circuit breaker, health probes, retry), write-scope validation, runbook. | ✅ completed |
| 2026-07-21 | [`engineering-analysis`](2026-07-21-gentleman-agent-gh-engineering-analysis.md) | Engineering | DRY violation (29% of opencode.json duplicated) → ✅ refactored 77KB→18KB in `fd42c9f1`. Testing, ADR, scripts organization still pending. | ⏸️ partial (3/15) |
| 2026-07-21 | [`deep-analysis-v3`](2026-07-21-gentleman-agent-gh-analisis.md) | Multi-dimension | Pipeline de datos roto (session-miner) ❌ still pending. SSoT ✅, health-check ✅, .dockerignore ✅, N+1 ✅ fixed. 5/15 resolved. | ⏸️ partial (5/15) |
| 2026-07-18 | [`deep-analysis-v4`](2026-07-18-gentleman-agent-gh-analisis.md) | Multi-dimension | Permission blocks ✅ resolved in `fd42c9f1`. Dual routing, return contracts still pending verification. | ⏸️ partial |
| 2026-07-14 | [`token-optimization`](2026-07-14-gentleman-agent-gh-analisis.md) | Performance | AGENTS.md duplication (4,247 tok/turn), skill registry bloat. Need verification. | ⏸️ pending |
| 2026-07-13 | [`initial-analysis`](2026-07-13-gentleman-agent-gh-analisis.md) | Multi-dimension | Auto-aprendizaje CRÍTICO (pipeline roto), session-miner not wired, skill-graph uncached. 5 verified + 3 incorrect findings. | ⏸️ pending |
| — | [`PERFORMANCE-PLAN`](PERFORMANCE-PLAN.md) | Performance | Plan to reduce `!ship` from ~46s→1-2s. P0-1 (incremental PSSA), P0-2 (ThreadJob) completed. 7 items remaining. | ✅ partial (2/9 done) |

## Trend Summary

- **Total documents**: 10 (9 analyses + 1 performance plan)
- **Completed**: 4 (orchestrator 7/8, deep analysis 12/15, execution report, reliability M1-M10)
- **Partial**: 3 (engineering partial 3/15, deep-analysis-v3 partial 5/15, deep-analysis-v4 partial)
- **Pending**: 2 (token-optimization pending verification, initial-analysis pending)
- **Performance plan**: 2/9 done

## Quick Reference

| File | Most Critical Takeaway |
|------|----------------------|
| `orchestrator-self-analysis` | ✅ Fixed — Pre-Answer Evidence Gate + Confidence Calibration in `gentleman-vMK.md`. 7/8 findings implemented. |
| `deep-analysis (07-24)` | SSoT conflict ✅ resolved. 12/15 executed. Remaining: skill tool (platform), !compress, SHORTCUTS date. |
| `execution-report (07-24)` | `!ejecutar` pipeline works — 12 findings in 12 files in one pass. State persisted for resume. |
| `reliability-analysis (07-21)` | ✅ Fixed — M1-M10 in `5ce4a6b7`. mcp-resilience.ps1 with circuit breaker, health probes, retry. |
| `engineering-analysis (07-21)` | DRY ✅ refactored 77KB→18KB. Remaining: test coverage (~10%), ADR, CI caching, script org. |
| `deep-analysis-v3 (07-21)` | ❌ Session-miner still disconnected. SSoT/health-check/.dockerignore ✅ fixed. |
| `deep-analysis-v4 (07-18)` | Permission blocks ✅ resolved. Dual routing needs verification. |
| `token-optimization (07-14)` | AGENTS.md loaded twice — needs verification if still applies. |
| `initial-analysis (07-13)` | Session-miner ❌ still pending. Skill-graph status unknown. |
| `PERFORMANCE-PLAN` | `!ship` reduced from ~46s to ~32s (P0-2: ThreadJob). 7/9 items remaining. |

## For Orchestrators

Before answering "what's missing" or gap questions:

1. Read this index
2. Check if your topic was already analyzed
3. If yes → `Read` that analysis file before answering
4. If novel → flag as `confidence: unvalidated`
