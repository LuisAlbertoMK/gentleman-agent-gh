# Ideas — 5 Enfoques Research → Backlog

> Branch: improve/auto-capture-20260826 | Date: 2026-08-26 | No push a main hasta aprobación

## Fuente 1: Azure Agent Orchestration (Magentic)
- Model-per-agent routing: usar modelo chico para classification/formatting, grande solo para reasoning → -30% cost
  - I/R: 2/1 → 2.0 — probar: benchmark 3 tareas con big-pickle vs nemotron en classify
- Per-agent token ledger: medir tokens por agente/orchestración → baseline + optimize
  - I/R: 3/1 → 3.0 — integrar en delivery-harness retry

## Fuente 2: PowerShell AnalysisCache
- Ya aplicado (score-cache 99.8%). Siguiente: skill discovery cache (91 skills → manifest hash)
  - I/R: 2/1 → 2.0 — similar a score-cache, medir Get-ChildItem .agents/skills

## Fuente 3: OpenCode Skills
- Skill lazy-load por dominio: cargar solo skills del dominio de la tarea (no 91)
  - I/R: 2/2 → 1.0 — medir skill-graph resolution antes/después

## Fuente 4: JetBrains Context Mgmt (ELEGIDO → implementado)
- Windowed compaction window=10: observation masking = 50% cost, 0% perf loss
  - Implementado: Compact-QueueWindow en engram-auto-capture.ps1 (HIGH/NORMAL/LOW tiered + window cap)
  - Validado: DryRun HIGH/NORMAL/LOW PASS, queue 4→3, score 9.9 stable
  - Resta: probar en sesión real con 15+ captures → medir engram-batch.json size

## Fuente 5: ENGRAM Typed Memory (arXiv 2025)
- Typed retrieval (episodic/semantic/procedural) → +15pt con 1% tokens
  - Actual: flat topic_key; sería: prefix episodic/semantic/procedural en mem_search
  - I/R: 2/2 → 1.0 — medir LoCoMo-style recall antes/después

## Selección (SkillOpt gate: target≥+0.1, no dim≤-0.3)
- Ejecutado: #4 (JetBrains window) — más medible, número duro, aplica directo al batch tiered ya existente
- Pendiente (próxima iteración, mismo branch): #1 per-agent ledger si #4 pasa tu aprobación

## Medición del prototipo (#4)
- Before: engram-auto-capture 5990 bytes, sin compaction (queue ilimitada)
- After:  6784 bytes (+794, +13.3%), Compact-QueueWindow(window=10) en NORMAL+LOW
- Regresión: 0 — score 9.9 stable, cross-ref allClean, parse OK, breaker no profile match
- Riesgo: bajo — solo afecta .learnings/engram-batch.json (gitignored, local)
