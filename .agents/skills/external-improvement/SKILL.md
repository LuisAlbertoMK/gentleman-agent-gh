---
name: external-improvement
description: "5-phase improvement cycle for external projects — 3+ subagents per phase."
triggers: "improve external project, mejora proyecto, proyecto externo, 5-phase cycle, ciclo 5 fases, analizá este proyecto, corré el ciclo, revisame el proyecto, !5fases, !extimprove, aplicá las 5 fases"
license: Apache-2.0
metadata:
  tags: [improvement, external, analysis]
  author: gentleman-vMK
  version: "1.0"
  standalone: true
---

## 5-Phase Cycle

Each phase: 3+ subagents via `task()` or `delivery-harness`. Return 4-field: `Decision Taken | Files Changed | Key Findings | Nuance`.

| Phase | Subagents | Focus | Output | Gate |
|-------|-----------|-------|--------|------|
| **P1 EXPLORE** | 3 | Structure, Architecture, Dependencies | `docs/external/<proj>/P1-EXPLORE.md` | All 3 reports must exist |
| **P2 DIAGNOSE** | 3+ | Quality, Security, Performance (+Tests opt) | `P2-DIAGNOSIS.md` | ≥3 subagents complete |
| **P3 PLAN** | 3 | I/R scoring, dep graph, rollback strategy | `P3-PLAN.md` | ≥1 batch with I/R ≥ 1.0 |
| **P4 EXECUTE** | 2/batch | Apply fixes + doc/tests per batch | `P4-EXECUTION.md` | All batches applied or SKIP'd |
| **P5 VERIFY & LEARN** | 3 | Regression, Score delta, Learning extraction | `P5-REPORT.md` | Score drop >0.5 → revert |

**Rule**: If P3 finds no batch with I/R ≥ 1.0 → STOP (project healthy).

## Behaviors
- **Internal** (gentleman-agent-gh): P1 skip, P2 ↔ score-auto.ps1, P3 light, P4 full, P5 full
- **External**: full 5 phases with standalone fallback
- Serial batches unless dep graph says parallel. Rollback per batch.
- Max 3 consecutive SKIP → abort. Score drop >0.5 → full revert.
- Stdlib doesn't cover this (needs 3 tool types in one pass).

## Output
```
docs/external/<project>/
├── P1-EXPLORE.md
├── P2-DIAGNOSIS.md
├── P3-PLAN.md
├── P4-EXECUTION.md
└── P5-REPORT.md
```

## Error Handling
| Failure | Action |
|---------|--------|
| Subagent timeout | Retry once with stricter scope, then SKIP |
| Phase gate not met | STOP phase, try next if independent |
| Score drop >0.5 | Full revert |
| 3 consecutive SKIP | Abort cycle, write partial report |
| Human needed | `conflict` file + escalation |

## Refs
delivery-harness · project-mapper · gap-analysis · sdd-propose/verify · triple-verify · codebase-memory · bitacora · commit-crafter · CYCLE.md (§5-Phase Cycle Loop)

## Anti-Patterns
Skip P1/P2 (explore/diagnose) · Parallelize dependent phases · Ignore score drop threshold · Over-commit on SKIP · Mix internal/external checklist
