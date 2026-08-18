---
name: analysis-mode
description: "Trigger: !analisis, !analysis, multi-agent analysis. Read-only 4-phase pipeline. Supports --meta for process/workflow analysis (bypasses scope guard)."
triggers: "!analisis, !analysis, !analisis --meta, analysis mode, multi-agent analysis, smart analysis, process analysis"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Trigger: !analisis, !analysis, multi-agent analysis. Read-only 4-phase pipeline.

`!analisis`/`!analysis` as first token.

**Loading**: `skill(name="analysis-mode")`. Fail→`Read` this file(project→global). External: copy to `<project>/.agents/skills/analysis-mode/`.

**SCOPE GUARD**: `git diff --name-only HEAD~1|Measure-Object -Line`. <10 files→HALT→load `code-review-agent`.
- **EXCEPTION**: If `--meta` flag is passed (`!analisis --meta`), bypass scope guard — analysis is about WORK PROCESS, not code changes. Skip file-count check, focus on workflow efficiency, communication, tooling, and protocol adherence.

**GATE**: Forbidden: `ctx_execute`/`Write`/`Edit`/`Bash`(except git status/diff/log)/`skill`(except project-mapper). Allowed: `Read`/`Grep`/`Glob`/`webfetch`/`websearch`/`project-mapper`. Output→`docs/mejoras/**`. Forbidden→log `BLOCKED:[tool][reason]`, continue.

**CONCISO**: Salida concisa—sin introducciones, directo al punto.

## P1: ANALYZE
0. `project-mapper`→stack. Public site?→+seo. 1.Scope:affected subsystems only
2.5-6 specialists: sec·infra·frontend·perf·datascience·docs(+seo if public)
3.Parallel→`Decision|Files|Findings|Nuance`
4.No result→`SKIPPED-{name}`, continue

## P2: VALIDATE(8 dims, N/A ok)
Sec→security|UX→frontend|Data→datascience|DX→docs|Perf→performance|Infra→infra|Arch→main(self)|Biz→main(self)
Arch first(structural)→Biz(strategic). No interleave.

## P3: SYNTHESIZE
`|Finding|Consensus|Risk|Files|Recommendation|`
UNANIMOUS(all agree)|MAJORITY(≥50%)|SPLIT(<50%)|OUTLIER(single)
>30 findings→top-15, rest appendix

## P4: PERSIST
**4a Compare**: Extract `<project>` from filename. `mem_search("analysis:<project>", topic_key:"analysis/<project>")`. Found→delta(improvements/regressions/new/stale)→`## Trend vs Previous`. None→"No previous analysis—baseline"
**4b Save**: `mem_save(title:"analysis:<project>:<YYYY-MM-DD>",type:architecture,topic_key:"analysis/<project>")` Content:`**What**:Analyzed <project> on <date>—<scope>. **Why**:<trigger>. **Where**:<top files max8>. **Key Findings**:<top5 by risk>. **Learned**:<surprises or "None">`
**4c Enrich**: Append to `docs/mejoras/YYYY-MM-DD-<project>-analisis.md`: 1.`## Engram Persistence`—id+topic_key+ts 2.`## Trend Analysis`—delta

## OUTPUT: `docs/mejoras/YYYY-MM-DD-<project>-analisis.md`—Summary,Findings(8dims),Synthesis,RiskMatrix,Recs,Engram,Trend
Gate:Plan only—NO code/commit. Exit before implementing.

## AUTO-TRIGGER: In `_core-behavior-gp.md`. Loads only on explicit `!analisis`.

---
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/analysis-mode/reference.md

---
