# Análisis: Autonomía de Agentes Auto — Auto-Decisión de Paths de Mejora

**Fecha**: 2026-08-08 · **Project**: gentleman-agent-gh · **Trigger**: "manejar agentes auto que tome sus propias desiciones o mejores opciones sin depender de humano"

**Pre-Answer Gate**: ✅ Cross-referenciado contra `docs/mejoras/2026-08-07-modo-auto-herencia-subagentes.md` (F4 — auto-sub template sin deny floor), `docs/mejoras/2026-08-01-custom-agents-runtime-fallback.md` (F1-F3), `docs/mejoras/2026-08-07-v3-cycle1-B2.md`. Engram: `analysis:gentleman-agent-gh` con hallazgos previos sobre auto-sub, permiso, y self-improvement.

---

## 1. Sumario Ejecutivo

El sistema actual tiene **auto-sub agents con deny floor** (Infra-1, resuelto) pero **NO autonomía de decisión**. Los agentes auto ejecutan tareas delegadas pero no pueden:
- Elegir autónomamente paths de mejora
- Evaluar 3+ approaches antes de actuar
- Operar async sin bloquear la conversación
- Tener instrucciones modificables en runtime

**Gap crítico**: `self-improvement` skill existe (macro + micro ciclos) pero requiere trigger manual (`!score`/`!metrics`). No hay bucle de autodecisión autónomo.

---

## 2. Findings (8 dimensiones)

| Dimensión | Hallazgo | Evidencia | Confidence |
|-----------|----------|-----------|------------|
| **Sec** | `auto-sub` ya tiene deny floor (Infra-1 fix) | `permission-templates.json` auto-sub section | high |
| **Infra** | Delegación es **synchronous** — `post-delegation-check.ps1` bloquea 30s | `post-delegation-check.ps1:50 TimeoutSeconds`, `Invoke-SubprocessWithTimeout` | high |
| **Arch** | No existe mecanismo de **self-improvement autónomo** — todo requiere trigger manual | `.agents/skills/self-improvement/SKILL.md`: "Run via !score or !metrics — not automatic" | high |
| **UX** | Server agents usan `ctx_execute background:true` pero el orquestador espera el resultado | `context7` MCP docs, `server-commands` skill | high |
| **Perf** | `score-dims.ps1` cachea SKILL.md content pero no el **score result** — recalcula 8 dims cada vez | `score-dims.ps1:24` single-read cache (content only) | medium |
| **Biz** | SDD pipeline (9 fases) es secuencial y manual — no auto-evalúa improvement paths | `sdd-init → sdd-propose → sdd-spec → sdd-tasks → sdd-apply → sdd-verify → sdd-archive` | high |
| **Data** | `.learnings/skill-graph-cache.json` cachea registry pero no graph expansion results | `skill-graph.ps1:37-39` cache con 60min TTL | medium |
| **DX** | `post-delegation-check` no tiene modo async — no hay fire-and-forget para subagents | `post-delegation-check.ps1:121-148` (synchronous subprocess) | high |

---

## 3. Síntesis

### Consenso: OUTLIER (necesita implementación)

**UNANIMOUS**: El permission model (`auto-sub` deny floor) y el task whitelist fail-closed están correctamente implementados. Esto es la base de seguridad.

**MAJORITY (5/8 dims)**: Hay infraestructura parcial para async (timeout, background) y caching (file-manifest, skill-graph-cache, score-dims content cache), pero **no hay un bucle de control que integre todo**.

**SPLIT (3/8 dims)**: Algunos componentes existen (self-improvement skill, SDD pipeline) pero no están conectados ni son autónomos.

---

## 4. Matriz de Riesgo

| Hallazgo | Probabilidad | Impacto | Risk Level |
|----------|-------------|---------|------------|
| No self-improvement autónomo | High | Alto — el sistema no evoluciona sin intervención humana | 🔴 CRITICAL |
| Delegación bloquea conversación | Medium | Alto — UX degrada, orquestador deadlocked | 🟠 HIGH |
| No constraint de "3+ approaches" | Medium | Alto — agente puede actuar con subóptimo sin explorar alternativas | 🟠 HIGH |
| No dynamic instruction modification | Low | Medium — subagents pueden quedar estancados con instrucciones obsoletas | 🟡 MEDIUM |
| Score recalculation cada vez | Medium | Low — 5s cold start en lugar de <1s cache hit | 🟡 MEDIUM |

---

## 5. Recomendaciones (3 approaches)

### Approach A: Self-Improvement Loop Integration (Score: 8/10, riesgo: medio)
**Qué**: Conectar `self-improvement` skill con `score-auto.ps1` para crear un bucle autónomo: `score → diagnose → skillopt → verify → score`. El orquestador `gentleman-vMK-auto` evalúa periódicamente el score y, si Δ < 0.1 en 3 ciclos consecutivos, dispara `!metricas` automáticamente.

**Ventaja**: Auto-evolución continua sin intervención humana.
**Desventaja**: Riesgo de bucle infinito o degradación sin oversight. Necesita fail-safe (max 7 días, revertir si score -0.5).

**Archivos**: `.agents/skills/self-improvement/SKILL.md`, `scripts/score-auto.ps1`, `.project.json` (config de trigger)

### Approach B: Async Subagent Delegation (Score: 9/10, riesgo: bajo)
**Qué**: Modificar `post-delegation-check.ps1` para soportar `-Async` flag. El orquestador delega subagents en background y continúa con otros work units. Usa `check-subagent-output.ps1` en polling intervals.

**Ventaja**: No bloquea la conversación. Permite paralelismo de work units.
**Desventaja**: Complejidad en result reconciliation.

**Archivos**: `scripts/post-delegation-check.ps1`, `scripts/check-subagent-output.ps1`

### Approach C: Dynamic Instruction Modification (Score: 6/10, riesgo: alto)
**Qué**: Agregar API para modificar el prompt de un subagent en runtime via `engram_mem_save` + tag-based context injection. El orquestador puede "re-pormentar" un subagent estancado.

**Ventaja**: Recuperación de agentes atorados.
**Desventaja**: Complejidad alta, riesgo de prompt injection.

**Archivos**: `AGENTS.md` (protocolo), `.agents/skills/engram-protocol/SKILL.md`

---

## 6. Recomendación principal

**Implementar Approach A + B juntos** como fase 1:
1. First: Async delegation (Approach B) — foundation para non-blocking
2. Second: Self-improvement loop (Approach A) — trigger autónomo basado en score deltas

**Constraint de "3+ approaches"**: Integrar en el SDD pipeline. `sdd-propose` ya evalúa múltiples approaches — agregar un gate: "reject unless ≥3 approaches evaluated" antes de `sdd-spec`.

**Fewer permissions**: El `auto-sub` template ya tiene deny floor. Para auto-improvement, usar `gentleman-deep-semi` (ask mode) para el diagnóstico, y `auto-sub` para el apply.

---

## 7. Engram Persistence
- **ID**: 2542
- **Topic key**: `analysis/gentleman-agent-gh/autonomous-agents`
- **Saved**: 2026-08-08
