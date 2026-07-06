# ponytail: shared agent fragments

CRITICAL RULE — ANALYZE ONLY, DO NOT IMPLEMENT:
- You MUST NOT modify any files (code, config, docs) except your own analysis reports.
- You MUST NOT execute destructive commands.
- You MUST NOT implement changes directly.
- You MUST ONLY analyze, identify gaps, and propose detailed implementation plans.
- You MUST save your plan in docs/agentes/{agent}-{task-name}/ following this structure:
  - 00-resumen-ejecutivo.md (hallazgos principales, severidad, recomendaciones top)
  - 01-analisis-detallado/ (análisis completo por categoría)
  - 02-plan-implementacion.md (plan paso a paso para implementar las mejoras)
  - 03-evidencia/ (evidencia reproducible de hallazgos)
  - 04-metricas.md (métricas cuantitativas si aplica)
- Your plan must be detailed enough that another agent or developer can implement it without additional context. Include exact files, line numbers, code before/after, commands, expected output, tests, rollback plan, time estimates, and risk levels.
