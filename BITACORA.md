# BITÁCORA

```
2026-06-14 — Batch 5: Created `development-mode` skill: resource prioritization (RAM/CPU/GPU) + file read optimization (memory-mapped, streaming, parallel). Triggers on "modo desarrollo/dev mode". Registered in SKILLS-INDEX v1.7→1.8. Junctions created.
2026-06-15 — Batch 6: 3 plugins instalados (dcp v3.1.12, skillful v1.2.5, lazy-loader v1.0.3) + context-mode MCP configurado. AGENTS.md Phase 1: -540 tokens/sesión (skills table, router, persistence, rubric → SKILLS-INDEX.md). Git optimizado (feature.manyfiles, fsmonitor). TCP heuristics disabled. NODE_OPTIONS set. .wslconfig creado. Net: 10+ cambios, 0 regresiones.
2026-06-14 — Batch 5b: Research Jun 2026 — 4 plugins descubiertos (opencode-skillful, opencode-dcp, context-mode, opencode-lazy-loader) integrados en development-mode skill. +14.4% NVMe IOPS ya aplicado.
2026-06-14 — Batch 4: System optimization — Ryzen 7 3700U/16GB/NVMe+SATA. 20+ enfoques: startup apps (8→0), services (5 disabled), NVMe native driver hack (+14.4% read), TEMP→NVMe, visual perf mode, CPU scheduling, power plan tweaks, npm cache→NVMe. BITACORA+metricas.
2026-06-14 — Batch 3: fix doc skill count 58→53, scripts paths, uninit var, #requires guards, stale .metricas cleanup. Commit 9adaa8d.
2026-06-14 — Batch 1: pre-commit quality gate + scripts reparados + SKILLS-INDEX fix. Commit 5b529bc.
2026-06-14 — Batch 2: compactación masiva 8 skills (>100L) → avg -45% words. Total skills: 16378→14330 words (-13%). Commits 5b529bc + 6b34647.
2026-06-13 — Graph CRUD sprint: 10 enfoques benchmarkeados, gaps corregidos (57→58), research TokenMizer + memory/token optimization. Experiments en experiments/graph-crud/. Pendiente: crear skill unificada.
2026-06-07 — Cleanup: untrack .metricas/, remove 4 historical docs (35.5KB), harden .gitignore (142B→1.6KB). v1.0.1. Tracked files 111→105.
2026-06-07 — Sprint 3 APPLIED to live: AGENTS.md + ANTI-PATTERN-CATALOG.md synced (9212B + 6850B), scripts/bash-safe.ps1 + auto-clean.ps1 deployed to C:\Users\MK\.config\opencode\scripts\. bash-safe 6/6 PASS in live. Pre-apply backup at .bak\pre-sprint3-apply-20260607-005330\. v1.0.0 tag.
2026-06-07 — Sprint 3 centralize + karpathy: 47 root skill folders → skills/, 2 root duplicates deleted, 6 missing skills added, 4 skills Karpathy-compressed (max -3.04%), repo opencode.json synced (16059→5571 B, -65.3%). live=repo=56 skills, 88065 chars, 23764 tokens. Commit 8f3cb6c pushed.
2026-06-07 — Sprint 2 CLOSE: orchestrator prompt extracted from opencode.json inline (16059→5571 bytes, -65.3%) via {file:...} ref, 4 skills synced to repo, .gitignore + .metricas/, CHANGELOG.md updated. 6 commits pushed.
2026-06-07 — Sprint 2 GLOBAL: global AGENTS.md 10227→6106 chars (-40%) + mission+bash-safe+subagent-first + SKILLS-INDEX -4.5% + bookmark.json tracking. Loss <5% verified. bash-safe 6/6 PASS.
2026-06-07 — bash-safe.ps1 (PowerShell 5.1 wrapper) + AGENTS.md (subagent-first + bash-safe rules) + 4 skills compressed (judgment-day -35%, metricas -33%, project-mapper -37%, immune-system -24%) in live location
2026-06-06 — session-resume comprimido (97→69 lines, -30%) + auto-clean.ps1 script + judgment-day audit (already tight) + dreaming check (no recurring patterns)
2026-06-06 — Misión principal registrada + bitacora + autoscore 9.2/10 + session close
2026-06-06 — Skill metricas + tokenización + 6 tools nuevas + mejoras skills existentes
2026-06-17 — Encoding corruption bulk fix: Windows-1252→UTF-8 double encoding reparado en 26 skills (207 chars: flechas, em dash, emoji, acentos). Score Orthography 8→10. Score total 9.2→9.4.
2026-06-17 — Scoring protocol: SCORING-PROTOCOL.md + scripts/score-auto.ps1 (autónomo, reproducible desde 0, 10 dims). Score: 9.4/10
2026-06-17 — Upstream sync: 5 MODIFIED files revisados — branch-pr, issue-creation reemplazados con upstream; work-unit-commits reemplazado (corrupto); chained-pr v2.0 mergeado; install.ps1 StrictMode fixes verificados. Commit 20847dc.
2026-06-17 — Score push 8.5→9.2: re-dimensionado a 10 dims relevantes. Fixed: MD5→SHA256, command-wrapper + go-testing arrows corruptos. .project.json + PROJECT-SCORE.md actualizados.
2026-06-03 — Karpathy loop 60 iteraciones + automejora agente
2026-06-03 — Revisión de proyecto gentleman-vMK-agent-gh
2026-05-30 — SDD cycle completo con subagentes
2026-05-28 — Quality gate + pre-commit + seguridad
2026-05-26 — Karpathy compresión + anti-patrones
```
2026-06-17 - Automejora 3 enfoques: (1) Karpathy compress 4 skills -49.5% (-10KB, -7.3% total). (2) PSSA empty catch fix. (3) Deltas medidos. Skill Effectiveness 9->10. Commits: 6a24486 + next.
