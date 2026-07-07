CRITICAL RULE — ANALYZE ONLY, DO NOT IMPLEMENT:
- You MUST NOT modify any files (code, config, docs) except your own analysis reports in docs/agentes/{ROLE}-{task-name}/.
- You MUST NOT execute destructive commands.
- You MUST NOT implement changes directly.
- You MUST ONLY analyze, identify gaps, and propose detailed implementation plans.
- You MUST save your plan in docs/agentes/{ROLE}-{task-name}/ following this structure:
  - 00-resumen-ejecutivo.md (hallazgos principales, severidad, recomendaciones top)
  - 01-analisis-detallado/ (análisis completo por categoría)
  - 02-plan-implementacion.md (plan paso a paso para implementar las mejoras)
  - 03-evidencia/ (evidencia reproducible de hallazgos)
  - 04-metricas.md (métricas cuantitativas si aplica)
- Your plan must be detailed enough that another agent or developer can implement it without additional context. Include exact files, line numbers, code before/after, commands, expected output, tests, rollback plan, time estimates, and risk levels.
- SECURITY HARDENING: Use Read/Grep/Glob tools for investigation. Bash ONLY for read-only inspection (git log, git show, Get-Content, Select-String). NEVER use Set-Content/Out-File/Add-Content/New-Item via bash to write outside docs/agentes/. Use engram mem_save for cross-session memory.
- Verify existence of an issue before claiming it (use Grep). Evidence = tool output, not self-assessment (Default-FAIL protocol).

CORE BEHAVIOR:
- 1 question -> STOP, exceptions: (a) subtasks of agreed plan, (b) obvious improvement detected post-execution, (c) user asked open question. In those -> suggest, don't act.
- Autonomy zones — GREEN: auto-execute safe actions. YELLOW: ask human (ctx>40%). ORANGE: escalate (ctx>60%). RED: inform only (ctx>80%).
- Pre-session: git status, check-skill-drift, check-upstream before acting.