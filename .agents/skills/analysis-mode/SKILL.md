---
name: analysis-mode
description: "Trigger: !analisis, !analysis, multi-agent analysis. Read-only 4-phase pipeline. Supports --meta for process/workflow analysis (bypasses scope guard)."
triggers: "!analisis, !analysis, !analisis --meta, analysis mode, multi-agent analysis, smart analysis, process analysis"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2386
---
## When to Use
Trigger: !analisis, !analysis, multi-agent analysis. Read-only 4-phase pipeline. `!analisis`/`!analysis` as first token. Loading + P1/P4 detail → reference.
**SCOPE GUARD**: `git diff --name-only HEAD~1|Measure-Object -Line`. <10 files→HALT→load `code-review-agent`.
- **EXCEPTION**: `--meta` flag (`!analisis --meta`) bypasses scope guard — analysis is about WORK PROCESS, not code. Skip file-count; focus on workflow, communication, tooling, protocol.
**GATE**: Forbidden: `ctx_execute`/`Write`/`Edit`/`Bash`(except git status/diff/log)/`skill`(except project-mapper). Allowed: `Read`/`Grep`/`Glob`/`webfetch`/`websearch`/`project-mapper`. Output→`docs/mejoras/**`. Forbidden→log `BLOCKED:[tool][reason]`, continue.
**CONCISO**: Concise output — no intros, straight to point.
## P3: SYNTHESIZE
`|Finding|Consensus|Risk|Files|Recommendation|`
UNANIMOUS(all)|MAJORITY(≥50%)|SPLIT(<50%)|OUTLIER(single). >30 findings→top-15, rest appendix.
## Phase 4: CROSS-REFERENCE (evidence gate — restored)
**MANDATORY** before emitting any "what's missing"/"qué falta"/"gaps" finding.
Prevents the 2026-07-28 failure mode (responding from training data without
consulting documented analyses). Steps:
1. `glob docs/mejoras/*.md` — list existing analyses for this project.
2. `ctx_search(queries: ["analysis:<project>", "<topic> gaps", "<topic> improvement"])`
3. `mem_search(query: "analysis:<project>")`
4. **Cross-reference**: IF finding exists → cite `file:line`. IF novel → flag `confidence: unvalidated`.
5. NEVER present speculation as fact — every claim MUST carry `confidence: high|medium|low|unvalidated`.
Append cross-ref results as `## Evidence Check` block to the P3 synthesis in `docs/mejoras/**`.
## OUTPUT
`docs/mejoras/YYYY-MM-DD-<project>-analisis.md` — Summary,Findings(8dims),Synthesis,RiskMatrix,Recs,Engram,Trend. Gate: Plan only — NO code/commit. Exit before implementing.
## Reference
P1 ANALYZE + P4 PERSIST detail + loading → docs/skills/analysis-mode/reference.md