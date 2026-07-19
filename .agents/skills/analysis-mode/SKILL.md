---
name: analysis-mode
description: "Trigger: !analisis, !analysis, multi-agent analysis. Read-only 3-phase pipeline: analyze → validate → synthesize."
triggers: "!analisis, !analysis, analysis mode, multi-agent analysis, smart analysis"
license: Apache-2.0
metadata:
  tags: [analysis, architecture]
  author: gentleman-vMK
  version: "4.3"
  changelog: "4.3: read-only gate restored, removed Phase 4 implementation. Kept scope guard, structured Phase 3."
  dependencies: [project-mapper]
---

`!analisis` or `!analysis` as first token. **SCOPE GUARD**: <10 files → use `code-review-agent` instead.

**ANALYSIS-ONLY GATE**: NO code execution, NO file writes EXCEPT the output plan (`docs/mejoras/`). Any write attempt → BLOQUEAR + log as "blocked action". Must exit analysis mode before implementing.

## PHASE 1: ANALYZE
0. `project-mapper` → detect stack + public site? → SEO if yes.
1. Scope: ONLY affected subsystems (not entire project).
2. 5-6 specialists (FREE TIER): security·infra·frontend·performance·datascience·docs (+seo).
3. Parallel subagents → `Decision | Files | Findings | Nuance`.

## PHASE 2: VALIDATE (8 dims — N/A allowed with justification)
| Dim | Agent | Dim | Agent |
|-----|-------|-----|-------|
| Security | security | Performance | performance |
| UX | frontend | Infra | infra |
| Data | datascience | Architecture | main |
| DX | docs | Business | main |

Architecture first, then Business. Do not interleave.

## PHASE 3: SYNTHESIZE
Structured output: `| Finding | Consensus | Risk | Files | Recommendation |`
Consensus: UNANIMOUS / MAJORITY / SPLIT / OUTLIER.

## OUTPUT
`docs/mejoras/YYYY-MM-DD-<project>-analisis.md` — Summary, Findings (8 dims), Synthesis table, Risk Matrix, Recommendations.

**Gate**: Plan only — NO code, NO commit. Exit analysis mode before implementing.
