---
name: analysis-mode
description: "Trigger: !analisis, !analysis, multi-agent analysis. Read-only 4-phase pipeline: analyze → validate → synthesize → persist."
triggers: "!analisis, !analysis, analysis mode, multi-agent analysis, smart analysis"
license: Apache-2.0
metadata:
  tags: [analysis, architecture]
  author: gentleman-vMK
  version: "4.7"
  changelog: "4.7: Trimmed resilient loading + auto-trigger ref to _core-behavior-gp.md (saves ~1,200 tok/trigger)"
  dependencies: [project-mapper]
---

`!analisis` or `!analysis` as first token.

**SKILL LOADING**: Try `skill(name="analysis-mode")`. If fails → `Read` this file (project then global). For external projects: copy to `<project>/.agents/skills/analysis-mode/`.

**SCOPE GUARD** (MANDATORY): Run `git diff --name-only HEAD~1 2>$null | Measure-Object -Line` (or equivalent). If <10 files changed → HALT, load `code-review-agent` instead. Do NOT continue.

**ANALYSIS-ONLY GATE**: Forbidden: `ctx_execute`, `Write`, `Edit`, `Bash` (except `git status/diff/log`), `skill` (except `project-mapper`). Allowed: `Read`, `Grep`, `Glob`, `webfetch`, `websearch`, `project-mapper`. Output to `docs/mejoras/**` only. Any forbidden attempt → log as `BLOCKED: [tool] [reason]`, continue analysis.

**CONCISO**: Toda salida de este skill debe ser concisa — sin introducciones, sin resúmenes extensos, directo al punto.

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

## PHASE 4: PERSIST
**Purpose**: Save findings to Engram and compare with prior analyses of the same project.

### 4a. Compare with previous analyses
1. Extract `<project>` from the output filename (e.g., `gentleman-agent-gh` from `2025-07-22-gentleman-agent-gh-analisis.md`).
2. Call `mem_search` with:
   - query: `"analysis:<project>"`
   - topic_key: `"analysis/<project>"`
3. If previous analysis found:
   - Extract key findings from the prior observation's `content.Key Findings`.
   - Build a **delta summary**: improvements (resolved findings), regressions (worsened), new findings, stale findings (no longer present).
   - Insert a `## Trend vs Previous Analysis` section after the synthesis table with this delta.
4. If no previous analysis found → note `No previous analysis for <project> — this is the baseline.`

### 4b. Save findings to Engram
Call `mem_save` with:
- **title**: `analysis:<project>:<YYYY-MM-DD>`
- **type**: `architecture`
- **topic_key**: `analysis/<project>` (upserts — updates same topic over time)
- **content** (structured):
  ```
  **What**: Analyzed <project> on <YYYY-MM-DD> — <one-line summary of scope>.
  **Why**: Triggered by <user trigger / git diff / manual request>.
  **Where**: <list top files/dirs in scope, max 8>.
  **Key Findings**: <top 5 findings ordered by risk — each as bullet with severity tag>.
  **Learned**: <surprises, non-obvious discoveries, or "None significant" if clean>.
  ```
- **scope**: `project`

### 4c. Enrich the report file
Append two sections to `docs/mejoras/YYYY-MM-DD-<project>-analisis.md`:
1. `## Engram Persistence` — state the observation ID saved, topic_key used, and timestamp.
2. `## Trend Analysis` — include the delta summary from 4a (or "First analysis — no prior baseline" if none found).

## OUTPUT
`docs/mejoras/YYYY-MM-DD-<project>-analisis.md` — Summary, Findings (8 dims), Synthesis table, Risk Matrix, Recommendations, Engram Persistence, Trend Analysis.

**Gate**: Plan only — NO code, NO commit. Exit analysis mode before implementing.

## AUTO-TRIGGER
Auto-trigger logic lives in `_core-behavior-gp.md`. This skill is only loaded on explicit `!analisis`.
