# Análisis de Fiabilidad del Sistema de Agentes — gentleman-agent-gh

**Fecha**: 2026-07-21
**Alcance**: Arquitectura del orquestador y mitigación de gaps de fiabilidad
**Método**: Pipeline analysis-mode — 6 especialistas + project-mapper en paralelo

---

## Resumen Ejecutivo

El sistema tiene una **arquitectura sólida** ( Builder ≠ Evaluator, triple-verify, zona-based risk, anti-pattern learning ) pero sufiere de **6 gaps críticos** que impiden fiabilidad completa:

| # | Gap | Severidad | Dimensión |
|---|-----|-----------|-----------|
| 1 | Sin health checks ni circuit breakers para MCP servers | **CRÍTICO** | Infra |
| 2 | Subagent writes scoped por prompt, no por runtime | **ALTO** | Security |
| 3 | Orchestrator ciego semánticamente (solo ve resúmenes) | **ALTO** | Performance |
| 4 | Sin detección de contradicciones en memoria al escribir | **ALTO** | Data Quality |
| 5 | Routing opaco al usuario — sin transparencia | **MEDIO** | UX |
| 6 | Sin runbook de infra para operadores | **MEDIO** | Docs |

**Assessment general**: PARTIAL — defensa en profundidad existe, pero la degradación silenciosa de MCP servers + subagentes sin límites de scope + memoria sin validación crean un vector de fallo en cascada.

---

## PHASE 1: Hallazgos por Dimensión (8)

### 1. Security

| # | Finding | Decision | Files | Nuance |
|---|---------|----------|-------|--------|
| S1 | Subagentes con edit+write pueden escribir fuera del scope intencionado | **HIGH** | `opencode.json:1291-1410` | `subagent-isolation` es advisory, no enforced por runtime |
| S2 | VERDE-zone salta adversarial-breaker — solo quality-gate structural | **MEDIUM** | `adversarial-breaker:27-29` | Riesgo real en AMARILLA-zone con <10 líneas |
| S3 | Prompt injection indirecto vía archivos maliciosos en repo | **MEDIUM** | `subagent-isolation:16` | Requiere supply chain attack previo |
| S4 | context7 (remote MCP) entra en cadena de confianza sin validación de integridad | **MEDIUM** | `opencode.json:197-201` | Contenido entra como documentación autoritativa |
| S5 | Orchestrator tiene el mayor attack surface (bash+edit+write+MCP) | **MEDIUM** | `opencode.json:238-364` | Deny-list bloquea RCE pero no daño filesystem |
| S6 | Outputs de subagentes pueden exponer credenciales inadvertidamente | **MEDIUM** | `subagent-isolation:32-36` | No hay redacción obligatoria de secrets |

**Security assessment**: **PARTIAL** — Deny-lists bien diseñados, Builder ≠ Evaluator sólido, pero subagent writes no están runtime-enforced.

### 2. Performance

| # | Finding | Decision | Files | Nuance |
|---|---------|----------|-------|--------|
| P1 | Sin fallback ni circuit breaker para MCP servers | **FAIL** | `opencode.json:174-234` | context7 remoto = single point of failure |
| P2 | Pipeline de routing secuencial: 4 gates antes de delegar | **PARTIAL** | `PROTOCOL.md:9-39` | Security → YAGNI → Skill Resolution → Model Router |
| P3 | Orchestrator solo ve resúmenes de subagentes — ciego semánticamente | **FAIL** | `PROTOCOL.md:75-95` | Para 10-file refactor: 3-5 summaries, nunca ve código raw |
| P4 | Free-tier models sin SLA — latencia variable 1-30s | **PARTIAL** | `opencode.json:366-1170` | Sin per-agent timeout, solo global mcp_timeout: 60s |
| P5 | Session resume cold-start: 4 operaciones secuenciales antes de trabajar | **PARTIAL** | `session-resume/SKILL.md:12-30` | git + mem_context + mem_search + skill-graph = 3-8s |
| P6 | Context compression overhead: L1 summary consume ~30-40% del original | **PARTIAL** | `context-watchdog/SKILL.md:16-49` | En ORANGE zone, 50K context → 15-20K solo para compresión |

**Performance assessment**: **PARTIAL** — Zone-based degradation es inteligente pero el orchestrator tiene un blind spot semántico fundamental.

### 3. Infrastructure

| # | Finding | Decision | Files | Nuance |
|---|---------|----------|-------|--------|
| I1 | context7 MCP: single point of failure, sin fallback | **FAIL** | `opencode.json:197-201` | Remote URL, sin retry, sin cache local |
| I2 | engram MCP: sin health check, sin auto-restart | **FAIL** | `opencode.json:204-211` | 30s timeout, health-check.ps1 NO valida MCP |
| I3 | codebase-memory MCP: sin health check | **FAIL** | `opencode.json:186-196` | health-check-system.ps1 salta MCP servers |
| I4 | Sin circuit breaker — fallos MCP se propagan en cascada | **FAIL** | `opencode.json`, recovery-protocol | recovery-protocol maneja errores lógicos, no infra |
| I5 | Config inconsistente: MCP disabled globally, enabled per-agent | **WARN** | `opencode.json:182-184,362-364` | Si MCP falla, agente pierde capabilities sin señal |
| I6 | Health checks miss MCP servers entirely | **FAIL** | `scripts/health-check-system.ps1` | Valida disk/git/node/python, NO MCP |

**Infra assessment**: **FAIL** — Tres MCP servers críticos sin health checks, circuit breakers, retry logic, ni degradación graceful.

### 4. UX (Frontend)

| # | Finding | Decision | Files | Nuance |
|---|---------|----------|-------|--------|
| U1 | Routing decisions opacos — usuario nunca ve qué agente ejecutó | **FAIL** | `opencode-model-router/SKILL.md` | Fallback chain invisible |
| U2 | Sin feedback de progreso durante tareas multi-subagent | **FAIL** | `delivery-harness/SKILL.md:19-27` | 5-10 work units = minutos de silencio |
| U3 | Verificación triple produce evidencia que nunca se muestra | **FAIL** | `triple-verify/SKILL.md` | Usuario confía en que el sistema se verificó |
| U4 | Recovery protocol reactivo — detecta frustración, no fallo temprano | **PARTIAL** | `recovery-protocol/SKILL.md` | Sin proactive "fallé, esto es por qué" |
| U5 | Help system minimal — 4 comandos para sistema de 79 skills | **FAIL** | `help/SKILL.md` | Usuario nuevo debe leer AGENTS.md (55 líneas) |
| U6 | Inconsistencia bilingüe en recovery flow | **PARTIAL** | `recovery-protocol/SKILL.md` | "Tenés razón" → "Diagnose" = jarring |

**UX assessment**: **PARTIAL** — Mecanismos internos excelentes pero poor external visibility. El usuario es un pasajero que ve el destino, no la ruta.

### 5. Documentation

| # | Finding | Decision | Files | Nuance |
|---|---------|----------|-------|--------|
| D1 | SHORTCUTS.md orfanado de la nav principal | **FAIL** | `AGENTS.md:5-11` | AGENTS.md lista 4 docs, omite SHORTCUTS.md |
| D2 | Routing logic fragmentado en 3+ archivos | **PARTIAL** | `PROTOCOL.md:9-39`, `review-rules.jsonc` | Sin diagrama de routing unificado |
| D3 | Sin runbook de infra para operadores | **PARTIAL** | `QUICKSTART.md:130-138` | Solo 4 troubleshooting rows |
| D4 | Agent permissions no enumeradas en docs | **PARTIAL** | `ARCHITECTURE.md:72` | 17 denied commands no listados |
| D5 | Discrepancia agents vs skills en SDD (9 vs 10) | **PARTIAL** | `ARCHITECTURE.md:70` | sdd-quick es skill pero no agent |

**Docs assessment**: **PARTIAL** — Skills bien documentados pero routing y infra sin documentation operacional.

### 6. Data Quality (Memory)

| # | Finding | Decision | Files | Nuance |
|---|---------|----------|-------|--------|
| M1 | Sin detección de contradicciones al escribir memoria | **RISK** | `engram-convention:43` | UPSERT sobrescribe sin validar coherencia |
| M2 | Memories sin provenance/linaje — no se puede verificar contra fuente | **RISK** | `engram-convention:36-38` | Sin `Source: file:line` ni `Commit: sha` |
| M3 | Dreaming manual — si usuario nunca ejecuta `!dream`, pipeline nunca corre | **RISK** | `dreaming:13` | wisdom-demote.ps1 existe pero es mensual/manual |
| M4 | Sub-agentes guardan sin validación cruzada | **RISK** | `persistence-contract:22-25` | Si resumen del orchestrator es wrong, error se compone |
| M5 | 300-char preview crea confianza falsa — LLMs usan preview como truth | **RISK** | `engram-convention:4` | Decisiones basadas en datos truncados |
| M6 | Inmunización permanente sin path de reversión | **PARTIAL** | `immune-system:37-38` | Reglas en AGENTS.md persisten forever sin TTL |

**Data quality assessment**: **PARTIAL** — Awareness de riesgos existe pero validación es manual/self-enforced.

### 7. Architecture (Self-validation)

| # | Finding | Decision | Files | Nuance |
|---|---------|----------|-------|--------|
| A1 | 5-layer architecture bien separada: Config → Runtime → Skills → Scripts → Memory | **PASS** | `docs/ARCHITECTURE.md` | Separación de concerns sólida |
| A2 | Builder ≠ Evaluator principle correctamente implementado | **PASS** | `adversarial-breaker` | Pero zona-gated — VERDE lo salta |
| A3 | Permission tiers claras: Orchestrator > Implementers > Read-Only | **PASS** | `opencode.json` | 3 tiers con deny-lists apropiados |
| A4 | Skill graph resolver (BFS) reduce 79 skills a 4-8 relevantes | **PASS** | `skill-graph.ps1` | 85-92% reducción, bien diseñado |
| A5 | Anti-pattern catalog como learning loop permanente | **PASS** | `ANTI-PATTERN-CATALOG.md` | 23 entradas con Symptom/Root/Fix/Prevention |

**Architecture assessment**: **PASS** — Estructura sólida, los gaps son de operación no de diseño.

### 8. Business (Self-validation)

| # | Finding | Decision | Files | Nuance |
|---|---------|----------|-------|--------|
| B1 | 13-dimension scoring system con bias-adjustment | **PASS** | `scripts/score-auto.ps1` | 9.1/10 raw → 7.3/10 adjusted — honesto |
| B2 | SDD pipeline de 9 fases para cambios estructurales | **PASS** | `prompts/sdd/` | Completo pero pesado para cambios simples |
| B3 | Free-tier models = costo operativo ~$0 | **PASS** | `opencode.json` | Trade-off: costo vs latencia/SLA |
| B4 | 88 scripts PowerShell como automation layer | **PASS** | `scripts/` | coverage good pero PS 5.1 = limitations |

**Business assessment**: **PASS** — ROI del sistema es positivo, los gaps son de madurez no de viabilidad.

---

## PHASE 3: Síntesis — Consenso Multi-Agente

| # | Finding | Consenso | Risk | Files | Recommendation |
|---|---------|----------|------|-------|----------------|
| 1 | MCP servers sin health checks ni circuit breakers | **UNANIMOUS** (Infra+Perf+Security+DataQuality) | **CRÍTICO** | `opencode.json`, `scripts/health-check*.ps1` | Implementar health-check MCP, circuit breaker pattern, retry con exponential backoff |
| 2 | Subagent writes sin scope enforcement por runtime | **MAJORITY** (Security+Infra+UX) | **ALTO** | `opencode.json`, `subagent-isolation` | Agregar write-scope validation post-delegation o restrict permissions por task |
| 3 | Orchestrator ciego semánticamente | **MAJORITY** (Perf+UX+DataQuality) | **ALTO** | `PROTOCOL.md`, `gentleman-vMK.md` | Implementar "semantic spot-check": orchestrator lee 1-2 archivos críticos post-delegación |
| 4 | Sin contradicción detection en memoria | **MAJORITY** (DataQuality+Security) | **ALTO** | `engram-convention`, `engram-protocol` | Agregar write-time similarity check antes de UPSERT |
| 5 | Routing opaco + sin progress feedback | **UNANIMOUS** (UX+Docs+Perf) | **MEDIO** | `opencode-model-router`, `delivery-harness` | Agregar routing log visible + progress indicators en multi-subagent |
| 6 | Sin runbook de infra | **MAJORITY** (Docs+Infra) | **MEDIO** | `QUICKSTART.md`, `scripts/` | Crear `docs/operations/RUNBOOK.md` con troubleshooting de MCP, context, loops |
| 7 | Dreaming manual = knowledge decay garantizado | **SPLIT** (DataQuality+Docs) | **MEDIO** | `dreaming`, `engram-protocol` | Hacer dreaming auto-trigger en session-end o cada N sesiones |
| 8 | Free-tier model latency sin per-agent timeout | **MAJORITY** (Perf+Infra) | **MEDIO** | `opencode.json` | Configurar per-agent timeout + fallback chain automática |
| 9 | Help system minimal vs complejidad real | **MAJORITY** (UX+Docs) | **BAJO** | `help/SKILL.md` | Expandir help con routing guide + common workflows |
| 10 | Memory sin provenance/linaje | **SPLIT** (DataQuality) | **MEDIO** | `engram-convention` | Agregar auto-capture de source file + commit SHA al guardar |

---

## Risk Matrix

```
                    IMPACTO
              Bajo    Medio    Alto    Crítico
            ┌────────┬────────┬────────┬────────┐
  Alta      │        │ M8     │ M3     │ I1-I6  │
            │        │        │ S1     │        │
  P         ├────────┼────────┼────────┼────────┤
  R  Media  │        │ U1-U3  │ S2-S6  │        │
  O         │        │ D1-D3  │ M1-M2  │        │
  B         │        │ M7-M8  │        │        │
            ├────────┼────────┼────────┼────────┤
  Baja      │ U6     │ D4-D5  │        │        │
            │        │ M6     │        │        │
            └────────┴────────┴────────┴────────┘
```

---

## Mitigaciones Recomendadas (Priorizadas)

### Tier 1 — CRÍTICO (Implementar primero)

**M1: MCP Health Check + Circuit Breaker**
- **Qué**: Script `scripts/mcp-health.ps1` que valida conectividad de cada MCP server
- **Dónde**: `scripts/mcp-health.ps1`, integrar en `scripts/health-check-system.ps1`
- **Cómo**: TCP probe para local MCPs, HTTP probe para context7. Circuit breaker: 3 fallos consecutivos → open state → fallback a grep/glob
- **Esfuerzo**: Medio (2-3 horas)
- **Impacto**: Elimina single point of failure más grande del sistema

**M2: MCP Retry con Exponential Backoff**
- **Qué**: Wrapper que reintenta MCP calls con backoff 1s → 2s → 4s
- **Dónde**: Nueva función en `scripts/lib/mcp-resilience.ps1`
- **Cómo**: Catch timeout/error → retry 3x con backoff → after 3 failures → graceful degradation
- **Esfuerzo**: Bajo (1-2 horas)
- **Impacto**: Transforma fallos transitorios en successes

### Tier 2 — ALTO

**M3: Subagent Write-Scope Validation**
- **Qué**: Post-delegation, orchestrator valida que archivos modificados están dentro del scope declarado
- **Dónde**: `gentleman-vMK.md` (orchestrator prompt), `delivery-harness`
- **Cómo**: Antes de cada delegación, declarar `allowed_paths: [...]`. Post-delegación, `git diff --name-only` vs allowed_paths
- **Esfuerzo**: Medio (2-3 horas)
- **Impacto**: Runtime enforcement del scope de subagentes

**M4: Semantic Spot-Check para Orchestrator**
- **Qué**: Orchestrator lee 1-2 archivos críticos post-delegación para validación semántica
- **Dócho**: `gentleman-vMK.md`, `PROTOCOL.md`
- **Cómo**: En tareas T2+, orchestrator hace `Read` de 1 archivo clave antes de declarar "done"
- **Esfuerzo**: Bajo (prompt change)
- **Impacto**: Reduce blind spot semántico sin romper Builder ≠ Evaluator

**M5: Memory Write-Time Contradiction Check**
- **Qué**: Antes de UPSERT, buscar memories con topic_key similar y comparar contenido
- **Dónde**: `engram-protocol`, `mem_save` workflow
- **Cómo**: `mem_search(topic_key)` → si resultado existe y contenido difiere >50% → alerta al usuario
- **Esfuerzo**: Medio (2-3 horas, depende de Engram API)
- **Impacto**: Previene knowledge decay silencioso

### Tier 3 — MEDIO

**M6: Routing Transparency + Progress Indicators**
- **Qué**: Log visible de routing decisions + progress updates en multi-subagent
- **Dónde**: `opencode-model-router`, `delivery-harness`
- **Cómo**: Formato: `[ROUTING] → gentleman-deep (nemotron-3-ultra-free) | reason: multi-file bugfix`
- **Esfuerzo**: Bajo (prompt changes)
- **Impacto**: Usuario confía más en el sistema

**M7: Infrastructure Runbook**
- **Qué**: Documento `docs/operations/RUNBOOK.md` con troubleshooting de MCP, context overflow, stuck loops
- **Dónde**: `docs/operations/RUNBOOK.md`
- **Cómo**: Tabla: Symptom → Diagnosis → Fix → Prevention para cada escenario
- **Esfuerzo**: Bajo (1-2 horas)
- **Impacto**: Operadores pueden diagnosticar sin escalación

**M8: Auto-Dreaming en Session-End**
- **Qué**: Trigger automático de dreaming cuando acumulación de memories > N desde último dream
- **Dónde**: `dreaming`, `close-session.ps1`
- **Cómo**: Contar memories nuevas desde último `!dream` → si >5 → auto-execute dreaming
- **Esfuerzo**: Medio (2-3 horas)
- **Impacto**: Previene knowledge decay por olvido del usuario

**M9: Per-Agent Timeouts**
- **Qué**: Timeout configurado por agente, no solo global
- **Dónde**: `opencode.json` agent configs
- **Cómo**: free-tier models → timeout 30s, default model → timeout 60s
- **Esfuerzo**: Bajo (config change)
- **Impacto**: Evita que un agente lento bloquee todo el pipeline

### Tier 4 — BAJO

**M10: Expanded Help System**
- **Qué**: Help skill con routing guide, common workflows, troubleshooting
- **Dónde**: `help/SKILL.md`
- **Cómo**: Agregar secciones: "How routing works", "Common tasks", "When things go wrong"
- **Esfuerzo**: Bajo (1 hora)
- **Impacto**: Reduce fricción para nuevos usuarios

---

## Effort vs Impact Summary

| Mitigación | Esfuerzo | Impacto | Prioridad |
|------------|----------|---------|-----------|
| M1: MCP Health Check | Medio | **CRÍTICO** | 🔴 Tier 1 |
| M2: MCP Retry/Backoff | Bajo | **CRÍTICO** | 🔴 Tier 1 |
| M3: Write-Scope Validation | Medio | **ALTO** | 🟠 Tier 2 |
| M4: Semantic Spot-Check | Bajo | **ALTO** | 🟠 Tier 2 |
| M5: Contradiction Check | Medio | **ALTO** | 🟠 Tier 2 |
| M6: Routing Transparency | Bajo | **MEDIO** | 🟡 Tier 3 |
| M7: Infra Runbook | Bajo | **MEDIO** | 🟡 Tier 3 |
| M8: Auto-Dreaming | Medio | **MEDIO** | 🟡 Tier 3 |
| M9: Per-Agent Timeouts | Bajo | **MEDIO** | 🟡 Tier 3 |
| M10: Expanded Help | Bajo | **BAJO** | 🟢 Tier 4 |

**Total esfuerzo estimado**: ~15-20 horas para Tier 1+2, ~8-10 horas para Tier 3+4

---

## Conclusión

El sistema tiene una **arquitectura de clase mundial** para un agente CLI — Builder ≠ Evaluator, zone-based risk, anti-pattern learning, triple-verify. Los gaps no son de diseño sino de **operational maturity**:

1. **Los MCP servers son el talón de Achiles** — sin health checks, circuit breakers, o retry, cualquier fallo de infra degrada silenciosamente todo el sistema
2. **Los subagentes tienen demasiada libertad** — scope enforcement es advisory, no enforced
3. **La memoria es write-heavy, validation-light** — se guarda mucho pero se valida poco

Las mitigaciones Tier 1+2 (M1-M5) transforman el sistema de "funciona cuando todo está bien" a "funciona incluso cuando algo falla". Eso es la diferencia entre un sistema frágil y uno resiliente.

---

*Análisis generado por analysis-mode pipeline — 6 especialistas + project-mapper en paralelo*
*Orchestrator: gentleman-vMK | Model: big-pickle*
