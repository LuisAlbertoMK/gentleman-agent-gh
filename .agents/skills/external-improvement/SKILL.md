---
name: external-improvement
description: "5-phase improvement cycle for external projects — 3+ subagents per phase."
triggers: "improve external project, mejora proyecto, proyecto externo, 5-phase cycle, ciclo 5 fases, analizá este proyecto, corré el ciclo, revisame el proyecto, !5fases, !extimprove, aplicá las 5 fases"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
5-phase improvement cycle for external projects — 3+ subagen

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

## Output
```
docs/external/<project>/
├── P1-EXPLORE.md
├── P2-DIAGNOSIS.md
├── P3-PLAN.md
├── P4-EXECUTION.md
└── P5-REPORT.md
```

## Cross-Refs: delivery-harness | project-mapper | gap-analysis | sdd-propose | sdd-verify | triple-verify | bitacora | commit-crafter
---

docs/skills/external-improvement/reference.md
---