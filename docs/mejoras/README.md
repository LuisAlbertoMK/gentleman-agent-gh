# Analysis Index — gentleman-agent-gh

> **Purpose**: Central index for all analysis documents. Updated when new analyses are created or executed.
> **For the orchestrator**: Run `glob docs/mejoras/*.md` + `ctx_search("analysis:gentleman-agent-gh")` before answering gap questions.

## Table of Contents

| Date | File | Domain | Key Finding | Status |
|------|------|--------|-------------|--------|
| 2026-08-04 | [`analysis-08-04`](2026-08-04-gentleman-agent-gh-analisis.md) | Multi-dimension | 15 findings: 5 enforcement (CRÍTICO/Alto), benchmark gate, tokenize-all roto, 7 docs "numbers that lie". R1-R5 completado (92f848aa, gate 16/16); R10 docs cleanup. | 🏁 active (plan) |
| 2026-08-03 | [`analysis-08-03`](2026-08-03-gentleman-agent-gh-analisis.md) | Multi-dimension | Veredictos por audit (PASS / PASS-WITH-NOTES). Findings verificados como arreglados en trend 08-04 (SEC-1/2/5, INFRA-1/3, DX-1..4, DOCS-1 4/5). | ✅ completed |
| 2026-08-01 | [`globalization`](2026-08-01-gentleman-agent-gh-analisis.md) | Multi-dimension | Globalización del agente para N proyectos externos — veredicto APROBADO-CON-CONDICIONES (5/5 especialistas); 5 issues nuevos de globalización. | 🏁 active (plan) |
| 2026-08-01 | [`custom-agents-runtime-fallback`](2026-08-01-custom-agents-runtime-fallback.md) | Runtime | Agentes custom (`mode: primary`) no delegables como subagent por el runtime — fallback silencioso a `general`; 3 issues. | — |
| 2026-07-31 | [`skill-usage-audit`](2026-07-31-gentleman-agent-gh-analisis.md) | Skills | Uso real (DB 716 sessions): 3 skills muertas, runtime `skill` roto por misconfig (plugin lazy-loader `skill/` vs `skills/`), 3 refs STALE skill-creator, 1 solape real. | 🏁 active (plan) |
| 2026-07-31 | [`tests-perf`](2026-07-31-gentleman-agent-gh-tests-perf.md) | Testing/Perf | Baseline suite: 553s secuencial / 150.3s paralelo (4.3×). Outliers: _e2e nested+coverage 178s, ScoreIntegration 88s = 42%. CRÍTICO: parallel unsafe (estado compartido: .gentleman-mode, BITACORA, $env:USERPROFILE). Proyección 150s→25-40s. | 🏁 active (plan) |
| 2026-07-30 | [`infra-capabilities-audit`](2026-07-30-infra-capabilities-external-audit.md) | Infra | External audit: infrastructure capabilities — veredicto final en doc. | — |
| 2026-07-30 | [`auto-permission-analysis`](2026-07-30-auto-permission-analysis.md) | Permissions | Clasificador de auto-permiso — patrones ASK vs ALLOW. | — |
| 2026-07-30 | [`agent-delegation-research`](2026-07-30-agent-delegation-decision-research.md) | Research | Agent delegation & decision-making research. | ✅ completed |
| 2026-07-29 | [`global-analysis`](2026-07-29-gentleman-agent-gh-global-analysis.md) | Multi-dimension | 15 findings: 84% sin tests (CRITICAL), score drift 9.1→6.2, .gitleaks vacío, -auto deny lists, bash-safe bypasses, BITACORA 121 dupes. | 🏁 active |
| 2026-07-29 | [`cycle28-analysis`](2026-07-29-gentleman-agent-gh-cycle28-analysis.md) | Cycle Analysis | Cycle 28 kickoff: security hardening + quality recovery — scope y criterios del ciclo activo. | 🏁 active |
| 2026-07-29 | [`token-context-analysis`](2026-07-29-gentleman-agent-gh-token-context-analysis.md) | Context/Tokens | Token & context reduction. Bloque de corrección `limit.input` (commit 598746e2). | ✅ completed |
| 2026-07-29 | [`seo-skill`](2026-07-29-seo-skill-analisis.md) | SEO | v2.1→v3.0 upgrade | ✅ completed |
| 2026-07-28 | [`tdd-testing`](2026-07-28-gentleman-agent-gh-analysis.md) | Testing | 7 findings — validate-write-scope tests (26), close-session tests (43), restore/forge-rollback tests (18), strict_tdd, pre-commit hook, CodeCoverage, Mock. | ✅ 7/7 completed |
| 2026-07-28 | [`orchestrator-self-analysis`](2026-07-28-orchestrator-self-analysis.md) | Meta-Architecture | Pre-Answer Evidence Gate + Confidence Calibration. 7/8 findings implemented in `6270c57e`. | ✅ 7/8 completed |
| 2026-07-28 | [`permission-modes`](2026-07-28-permission-modes-analysis.md) | Permissions | 3 permission modes (manual/semi/auto). switch-mode.ps1 + permission-gate.ps1 + .gentleman-mode created. | ✅ completed |
| 2026-07-24 | [`execution-report`](2026-07-24-gentleman-agent-gh-ejecucion.md) | Execution | 12/15 findings implemented across 12 files. 3 skipped. Pipeline `!ejecutar` v1.1. | ✅ completed |
| 2026-08-14 | [`2026-08-14-resource-optimization-investigation`](2026-08-14-resource-optimization-investigation.md) | Resource Optimization | 5-pass research (25+ sources): 3 root causes, tiered config profiles, CPU/RAM monitoring scripts, PS 5.1/7 syntax validation. Implemented in `f4d4ec84`. | ✅ completed |
| — | [`PERFORMANCE-PLAN`](PERFORMANCE-PLAN.md) | Performance | `!ship` ~46s→32s. P0-1 (incremental PSSA), P0-2 (ThreadJob), P0-3/P1/P2 items. Todos completados (P0-1..3, P1-1..3, P2-1..3). | ✅ completed (9/9) |

## Trend Summary

- **Total documents**: 20 (19 analyses + 1 performance plan, all indexed above)
- **Completed**: 6 (tdd-testing, orchestrator, permission-modes, execution-report, PERFORMANCE-PLAN 9/9, resource-optimization)
- **Current**: 2026-08-04 analysis — R1-R5 completed (commit 92f848aa, gate 16/16); R10 docs cleanup in progress

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
