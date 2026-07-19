---
name: analysis-mode
description: "Trigger: !analisis, !analysis, multi-agent analysis. 4-phase: analyze → validate → synthesize → implement."
triggers: "!analisis, !analysis, analysis mode, multi-agent analysis, smart analysis"
license: Apache-2.0
metadata:
  tags: [analysis, architecture, execution]
  author: gentleman-vMK
  version: "4.2"
  changelog: "4.2: compressed — scope guard, MED→HIGH refactors, structured Phase 3, rollback coverage"
  dependencies: [project-mapper, quality-gate]
---

`!analisis` or `!analysis` as first token. **SCOPE GUARD**: <10 files → use `code-review-agent` instead.

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

## PHASE 4: IMPLEMENT
| Level | Criteria | Action |
|-------|----------|--------|
| SAFE | Formatting, imports, config, docs | AUTO-APPLY |
| MED | New helpers, tests (no sig changes) | AUTO-APPLY + report |
| HIGH | Refactors, logic, API, auth, data flow | CONFIRM first |
| CRIT | Secrets, destructive, schema | BLOCK |

Execute → Quality gate (syntax→lint→scoped tests→build) → Rollback on fail → Commit via `commit-crafter`.

## SAFETY
1. Never auto-apply CRIT. 2. HIGH = confirm. 3. Max 20 files/batch. 4. Rollback on failure (file-level + post-commit revert). 5. Scope specialists to affected modules.

## OUTPUT
`docs/mejoras/YYYY-MM-DD-<project>-analisis.md` — Summary, Findings, Synthesis, Risk Matrix, Action Plan, Applied/Deferred.
