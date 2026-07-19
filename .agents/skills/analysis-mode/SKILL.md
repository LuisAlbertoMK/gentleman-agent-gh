---
name: analysis-mode
description: "Trigger: !analisis, !analysis, multi-agent analysis. Read-only 3-phase pipeline: analyze → validate → synthesize."
triggers: "!analisis, !analysis, analysis mode, multi-agent analysis, smart analysis"
license: Apache-2.0
metadata:
  tags: [analysis, architecture]
  author: gentleman-vMK
  version: "4.4"
  changelog: "4.4: breaker fixes — scope guard with counting, blocked actions list, failure handling, consensus math"
  dependencies: [project-mapper]
---

`!analisis` or `!analysis` as first token.

**SCOPE GUARD** (MANDATORY): Run `git diff --name-only HEAD~1 2>$null | Measure-Object -Line` (or equivalent). If <10 files changed → HALT, load `code-review-agent` instead. Do NOT continue.

**ANALYSIS-ONLY GATE**: Forbidden: `ctx_execute`, `Write`, `Edit`, `Bash` (except `git status/diff/log`), `skill` (except `project-mapper`). Allowed: `Read`, `Grep`, `Glob`, `webfetch`, `websearch`, `project-mapper`. Output to `docs/mejoras/**` only. Any forbidden attempt → log as `BLOCKED: [tool] [reason]`, continue analysis.

## PHASE 1: ANALYZE
0. `project-mapper` → detect stack + public site? → include SEO specialist if yes.
1. Scope: ONLY affected subsystems from mapper output (not entire project).
2. 5-6 specialists (FREE TIER): security·infra·frontend·performance·datascience·docs (+seo if public site).
3. Parallel subagents → `Decision | Files | Findings | Nuance`.
4. **Failure handling**: If specialist returns no result → log `SKIPPED-{name}`, continue with remaining. Output marks skipped dimensions.

## PHASE 2: VALIDATE (8 dims — N/A allowed with justification)
| Dim | Agent | Dim | Agent |
|-----|-------|-----|-------|
| Security | security | Performance | performance |
| UX | frontend | Infra | infra |
| Data | datascience | Architecture | main (self-validate) |
| DX | docs | Business | main (self-validate) |

**Note**: Architecture and Business use orchestrator self-validation — no independent specialist. Acknowledged limitation.
**Sequencing**: Architecture first (structural), then Business (strategic). Do not interleave.

## PHASE 3: SYNTHESIZE
Structured output: `| Finding | Consensus | Risk | Files | Recommendation |`
- **UNANIMOUS**: All participating specialists agree (N/A excluded)
- **MAJORITY**: ≥50% agree
- **SPLIT**: No group >50%
- **OUTLIER**: Single dissenting finding

If findings >30 → consolidate top-15 by risk, remainder to appendix.

## OUTPUT
`docs/mejoras/YYYY-MM-DD-<project>-analisis.md` — Summary, Findings (8 dims), Synthesis table, Risk Matrix, Recommendations.

**Gate**: Plan only — NO code, NO commit. Exit analysis mode before implementing.
