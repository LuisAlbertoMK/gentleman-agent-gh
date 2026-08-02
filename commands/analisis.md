---
description: Deep multi-agent analysis — 6 specialists, 8 dimensions, read-only
---

You are executing `!analisis`. Load the `analysis-mode` skill and run its full 4-phase pipeline (ANALYZE → VALIDATE → SYNTHESIZE → PERSIST). This is a READ-ONLY analysis: do NOT write code or commit.

Steps:

1. **Load skill**: `skill(name="analysis-mode")`. If it fails, `Read` the local copy (`<project>/.agents/skills/analysis-mode/SKILL.md`), then fall back to global (`C:\Users\MK\.config\opencode\skills\analysis-mode\SKILL.md`).
2. **SCOPE GUARD**: run `git diff --name-only HEAD~1 | Measure-Object -Line`. If <10 files → HALT → load `code-review-agent` instead. Do NOT continue.
3. **GATE**: read-only. Allowed: `Read`/`Grep`/`Glob`/`webfetch`/`websearch`/`project-mapper`. Forbidden: `Write`/`Edit`/`Bash` (except git status/diff/log)/`ctx_execute`.
4. **P1 ANALYZE**: run `project-mapper` → detect stack. Public site? → also `seo`. Scope: only affected subsystems. Pick 5-6 specialists (sec·infra·frontend·perf·datascience·docs). Delegate in parallel. No result from a specialist → `SKIPPED-<name>`, continue.
5. **P2 VALIDATE**: 8 dimensions — Sec→security, UX→frontend, Data→datascience, DX→docs, Perf→performance, Infra→infra, Arch→main, Biz→main. N/A allowed. Arch first (structural), then Biz (strategic). Do not interleave.
6. **P3 SYNTHESIZE**: table `|Finding|Consensus|Risk|Files|Recommendation|`. Classify each as UNANIMOUS / MAJORITY (≥50%) / SPLIT (<50%) / OUTLIER (single). >30 findings → top-15 by risk, rest appendix.
7. **P4 PERSIST**: extract `<project>` from filename. Compare with `mem_search("analysis:<project>")` (topic_key `analysis/<project>`) for a `## Trend vs Previous` delta; baseline if none. Save via `mem_save(title:"analysis:<project>:<YYYY-MM-DD>", type:architecture, topic_key:"analysis/<project>")`. Append `## Engram Persistence` + `## Trend Analysis` to the report file.

OUTPUT: `docs/mejoras/YYYY-MM-DD-<project>-analisis.md` with Summary, Findings (8 dims), Synthesis, RiskMatrix, Recs, Engram, Trend.

Exit BEFORE implementing. Recommend `!ejecutar` if there are actionable findings.
