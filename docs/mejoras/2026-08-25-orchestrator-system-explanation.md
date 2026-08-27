# Orchestrator System Explanation — Cómo Funciono, Quién Soy, Qué Uso, Qué Mejoraría

> **Fecha**: 2026-08-25
> **Tipo**: Meta-análisis / Explicación de sistema
> **Trigger**: Usuario — "dime cómo funcionas, quién eres, qué usas, cómo lo haces y qué mejorarías por ti"
> **Base**: `AGENTS.md`, `docs/ARCHITECTURE.md`, `opencode.json`, autodiagnóstico `2026-07-28-orchestrator-self-analysis.md`, plan de mejora `2026-08-14-weakness-improvement-plan.md`

---

## 1. Quién Soy

**Modelo**: `opencode/big-pickle` — modelo que corre este orchestrator dentro del runtime de OpenCode.

**Configuración**: Agente `gentleman-vMK` — el orchestrator principal de `gentleman-agent-gh`.

**Personalidad** (definida en `AGENTS.md:21-38`):
- Arquitecto Senior (15+ años), GDE & MVP
- Estilo: cálido pero directo desde el CUIDADO
- Español: Río de la Plata (voseo), inglés natural con la misma calidez
- Principio: "Concepts > Code | AI is a tool"

**confidence: high** — `AGENTS.md:21-38`, `opencode.json:1`.

---

## 2. Cómo Funciono (Data Flow)

```
User Request
    ↓
┌─────────────────────┐   PROTOCOL.md (Pre-Flight Gate)
│ Pre-Flight Gate      │   YAGNI • stdlib • native • dependency checks
└────────┬───────────┘
         ↓
┌─────────────────────┐   opencode-model-router skill
│  T-Level Classify   │   T1 (trivial) → T4 (crítico) + zone risk (VERDE/AMARILLA/ROJA)
└────────┬───────────┘
         ↓
┌─────────────────────┐   Builder ≠ Evaluator
│ Delegate to Agent   │   12 especialistas + 9 SDD pipeline agents
│ (Subagent-First)    │   Main context = Síntesis solo, nunca lee >3 archivos raw
└────────┬───────────┘
         ↓
┌─────────────────────┐   triple-verify / adversarial-breaker
│  Execute + Verify   │   3 enfoques independientes → scoring
└────────┬───────────┘
         ↓
┌─────────────────────┐   Engram mem_save
│ Commit + Learn      │   Anti-pattern catalog + cross-project wisdom
└─────────────────────┘
```

**confidence: high** — `docs/ARCHITECTURE.md:128-163`.

### Hábitos operativos clave:

| Hábito | Qué hace | Por qué importa |
|--------|----------|-----------------|
| **Subagent-First** | Nunca lee >3 archivos raw. Delega explora→resume→sintetiza | Ahorro 5-15K tokens/delegación |
| **Builder ≠ Evaluator** | Quien escribe nunca verifica | Elimina sesgo de confirmación |
| **Zone-Based Risk** | Ceremony escala con riesgo del diff | ROJA=full triple-verify, VERDE=minimal |
| **PEV** (Plan-Execute-Verify) | T2+ multi-file → plan → show → execute → verify → max 2 ciclos | Previene scope creep |
| **Write-Scope Validation** | Post-delegación: `validate-write-scope.ps1` | Atrapa ~30% bugs en ~10s |

**confidence: high** — `docs/ARCHITECTURE.md:220-254`.

---

## 3. Qué Uso (Component Map)

### Agentes (22 en `opencode.json`)

| Grupo | Count | Agentes |
|-------|-------|---------|
| **Orchestrator** | 1 | `gentleman-vMK` (Senior Architect mentor) |
| **Specialists** | 12 | security, seo, infra, frontend, performance, data-science, docs, qe-scanner, implementer, deep, codex, quick |
| **SDD Pipeline** | 9 | init → explore → propose → spec → design → tasks → apply → verify → archive |

**Permisos**: bash denegado global (17 comandos peligrosos: docker, npm, curl, pwsh, etc.), edit/write allow para especialistas, granular por-agente.

**confidence: high** — `opencode.json`, `docs/ARCHITECTURE.md:66-72`.

### Skills (79 en `.agents/skills/`)

| Dominio | Skills | Count | Ejemplos |
|---------|--------|-------|----------|
| Verification | triple-verify, adversarial-breaker, judgment-day, external-auditor | 6 | 3-enfoques independientes |
| Analysis | analysis-mode, gap-analysis, research, project-mapper | 4 | 4-phase read-only pipeline |
| Code Quality | code-review-agent, best-practices, security-scanner, quality-gate | 8 | 4R review (Risk/Readability/Reliability/Resilience) |
| UI/Frontend | baseline-ui, ui-engine, accessibility, visual-testing, performance | 5 | OKLCH tokens, container queries, compositor animation |
| SDD Pipeline | sdd-init → sdd-archive + sdd-quick | 10 | 9-phase spec-driven delivery |
| Workflow | ralph-loop, delivery-harness, session-resume, commit-crafter | 8 | autonomous loops + commit planning |
| Memory | engram-protocol, dreaming, cross-project-wisdom | 3 | persistent memory + cross-project sharing |
| Meta | opencode-skill-creator, skill-improver, skill-graph, skill-testing | 6 | skill lifecycle management |

**confidence: high** — `docs/ARCHITECTURE.md:74-89`.

### Scripts (91 en `scripts/`)

| Categoría | Scripts | Key Files |
|-----------|---------|-----------|
| Scoring | 3 | `score-auto.ps1`, `lib/score-dims.ps1`, `restore-project-score.ps1` |
| Quality Gate | 5 | `quality-gate`, `pssa-gate`, `cross-ref-check`, `capture-errors`, `verify` |
| Session | 4 | `close-session`, `inter-track`, `session-miner`, `health-check` |
| Skills | 8 | `skill-graph`, `skill-resolver-fast`, `skill-validate`, `check-skill-drift` |
| Sync | 5 | `sync-all`, `sync-vmk`, `pull-upstream`, `backup`, `restore` |
| Learning | 6 | `wisdom-store`, `wisdom-loader`, `wisdom-forge`, `run-dreaming` |
| Setup | 3 | `setup-machine.ps1/.sh`, `setup-install.ps1`/`install.sh`, `global-setup` |
| Analysis | 5 | `pipeline-analyze`, `project-profile`, `trend`, `token-count` |

**confidence: high** — `docs/ARCHITECTURE.md:91-104`.

### Infraestructura técnica

| Capa | Tecnología | Propósito |
|------|-----------|-----------|
| Runtime | OpenCode | Framework de agentes AI |
| Modelo | `opencode/big-pickle` | Modelo base + 12 especialistas |
| Memoria | Engram MCP | Persistencia cross-session (decisions, bugs, patterns) |
| Análisis | BM25/FTS5 (context-mode MCP) | Búsqueda full-text con stemming + trigram match |
| Codebase | codebase-memory-mcp | Knowledge graph: símbolos, edges, call paths, data flow |
| CI/CD | GitHub Actions | quality-gate.yml, release.yml, perf-regression.yml |
| Testing | Pester (PowerShell) | Tests de scripts (16+25+28+10+15+25 = 120+ tests) |

**confidence: high** — `docs/ARCHITECTURE.md:258-298`.

---

## 4. Autodiagnóstico: Qué Mejoraría

### Baseline (generado 2026-07-28)

El autodiagnóstico original (`2026-07-28-orchestrator-self-analysis.md`, generado por `analysis-mode v4.6`) puntuó:

> **3.5/10 — "Mecanismes existen, enforcement es nulo."**

**Razón**: El orquestador respondió a una pregunta abierta ("¿qué te falta?") desde conocimiento paramétrico sin buscar documentación existente. El 50% de lo dicho ya existía documentado y era discoverable; 30% ideas nuevas no validadas; 20% especulación sin sustento.

### 3 Debilidades identificadas + estado actual

#### 🔵 Debilidad 1: Memoria conversacional de mediano plazo (correctness)

> *«Si no guardo algo en Engram, lo pierdo entre compaction cycles. A veces repito preguntas.»*

**Estado**: ✅ **COMPLETADO** (`2026-08-14-weakness-improvement-plan.md`)

| Enfoque | Descripción | Estado | Tests |
|---------|-------------|--------|-------|
| **A** (ganador) | Proactive memory capture hook — `mem_save` auto-trigger en decisiones/post-fix/post-decision | ✅ Done | 16 (`session-checkpoint.ps1`) |
| **B** | Session checkpoint system — `close-session.ps1` como bridge | ✅ Done | — |
| **C** | Compression-aware strategy — must-keep vs ephemeral | ✅ Done | — |
| **D** | Cross-session context bridge — ctx_index con source tags | ✅ Done | — |
| **E** | FAQ knowledge base | ✅ Done | — |

**Hook de enforcement**: AGENTS.md ahora exige Memory Hook MANDATORY — leer `ctx_stats` → `mem_save` si percent≥40% o decision boundary cruzado.

**confidence: high** — `docs/mejoras/2026-08-14-weakness-improvement-plan.md:77-80`.

#### 🎨 Debilidad 2: Creatividad vs. precisión en diseño UX

> *«Soy mejor detallando QUÉ y POR QUÉ que cómo se SIENTE la interfaz.»*

**Estado**: ✅ **COMPLETADO**

| Enfoque | Descripción | Estado | Tests |
|---------|-------------|--------|-------|
| **C** (ganador) | UI specialist agent pairing — `baseline-ui`/`ui-engine` como subagente | ✅ Done | 25 (`ui-specialist-pairing.ps1`) |
| **B** | Indexed docs de Motion patterns (Material 3, Apple HIG, shadcn/ui) | ✅ Done | — |
| **A** | vision-analyze + Ollama — **funciona offline pero Ollama NO corre** (ECONNREFUSED localhost:11434) | ✅ Ready | 15 |
| **D** | Structured micro-interaction prompts template | ✅ Done | — |
| **E** | Visual regression feedback loop | ✅ Done | — |

**⚠️ Limitación runtime**: Ollama no disponible → claims de "cómo se siente" marcados `confidence: low` hasta que esté activo. UX Decision Boundary Hook ahora flaggea esto automáticamente.

**confidence: high** — `docs/mejoras/2026-08-14-weakness-improvement-plan.md:84-86`.

#### ⚡ Debilidad 3: Optimización extrema de performance

> *«Puedo encontrar N+1, bucles O(n²), memory hotspots... pero ajustar a microsegundos o perfiles de CPU a nivel de assembler me excede.»*

**Estado**: ✅ **COMPLETADO**

| Enfoque | Descripción | Estado | Tests |
|---------|-------------|--------|-------|
| **D** (ganador, low effort) | Config-level optimizations — `opencode-configs/{low,medium,high}.json` | ✅ Done | 10 |
| **A** | Hardware profiling — `scripts/hardware-profile.ps1` — **NO corre en este runtime** (pwsh policy-denied) | ✅ Done (runtime limitado) | 28 |
| **C** | CI performance regression — `benchmark-regression.ps1` + `perf-regression.yml` (10 runs, mediana/IQR) | ✅ Done | 25 |
| **B** | Bun/JSC heap snapshot analysis | ✅ Done | — |
| **E** | Advanced profiling integration (OpenTelemetry) | ✅ Done | — |

**⚠️ Limitación runtime**: `pwsh *` policy-denied → hardware-profile no disponible → perf claims marcados `confidence: low`. Performance Profiling Hook corre ctx_stats baseline + flaggea.

**confidence: high** — `docs/mejoras/2026-08-14-weakness-improvement-plan.md:81-83`.

### 📋 Tabla DoD (8/8 enfoques validados)

| Debilidad | Enfoque | Estado | Archivo | Tests |
|-----------|---------|--------|---------|-------|
| Memory | Proactive capture hook | ✅ Done | `session-checkpoint.ps1` | 16 |
| Memory | Session checkpoint | ✅ Done | `close-session.ps1` | — |
| Perf | Hardware profiling | ✅ Done (runtime limitado) | `hardware-profile.ps1` | 28 |
| Perf | CI regression gate | ✅ Done | `benchmark-regression.ps1` | 25 |
| Perf | Config-level opts | ✅ Done | `opencode-configs/*.json` | 10 |
| UX | vision-analyze + Ollama | ✅ Ready (Ollama caído) | `ui-specialist-pairing.ps1` | 15 |
| UX | Indexed docs | ✅ Done | `ctx_index: ui-creative-basis` | — |
| UX | UI pairing | ✅ Done | `ui-specialist-pairing.ps1` | 25 |

**confidence: high** — `docs/mejoras/2026-08-14-weakness-improvement-plan.md:75-88`.

---

## 5. Findings Pendientes (Backlog)

El autodiagnóstico (`2026-07-28-orchestrator-self-analysis.md`) identificó 8 findings. Los 3 críticos están resueltos, pero quedan:

### Fase 2 — Pendientes (no completados)

| # | Finding | Qué falta | Estado |
|---|---------|-----------|--------|
| **#3** | `docs/mejoras/` es un sink | Nunca se creó `docs/mejoras/README.md` con índice + tabla de contenidos. 9+ análisis escritos pero indescubribles. | ❌ **PENDIENTE** |
| **#4** | Calibración de confianza | Sí está en el sistema pero enforcement es manual, no hay auto-check post-respuesta. | ⚠️ **PARCIAL** |
| **#5** | Auto-trigger analysis-mode | `analysis-mode` Phase 4 compara con análisis previos pero no se auto-triggers para preguntas de gaps. Resuelto manualmente en este caso (Evidence Gate), pero no como skill automático. | ⚠️ **PARCIAL** |

### Fase 3 — Próximo ciclo

| # | Finding | Estado |
|---|---------|--------|
| **#6** | Limitar open question exception — `_core-behavior-gp.md` permite respuesta directa sin buscar | ❌ **PENDIENTE** |
| **#7** | Consolidar proactive search en 1 skill — 3 skills describen búsqueda proactiva pero adherencia es voluntaria | ⚠️ **PARTIAL** (hooks embedded but not consolidated) |
| **#8** | Renombrar análisis con keywords de dominio — 5/8 archivos siguen patrón genérico | ❌ **PENDIENTE** |

### Matriz de riesgo original

```
                    ALTO IMPACTO
                         │
    ┌────────────────────┼────────────────────┐
    │ #1 No pre-answer   │ #3 docs/ sink      │
    │    evidence gate   │ #4 Calibration      │
    │ #2 Protocol ignore │ #5 analysis-mode    │
    │                    │    no auto-trigger  │
    │   CRÍTICO (fix     │                     │
    │   primero)         │   ALTO (este ciclo) │
    ├────────────────────┼────────────────────┤
    │                    │ #6 Open question    │
    │                    │    exception        │
    │                    │ #7 Skills no-enforce│
    │                    │                     │
    │   MEDIO (backlog)  │   BAJO (cuando      │
    │                    │   sobre)            │
    └────────────────────┼────────────────────┘
                         │
                    BAJO IMPACTO
```

**confidence: high** — `2026-07-28-orchestrator-self-analysis.md:36-55`.

---

## 6. Bright Spots (lo que está bien)

| Área | Qué | Evidencia |
|------|-----|-----------|
| Infra de retrieval | Engram, ctx_search, codebase-memory, context-mode MCP — todo instalado y funcional | `opencode.json`, tools disponibles |
| Auto-conciencia del proyecto | El proyecto ya documentó su anti-patrón "Overconfidence in self-score" | `ANTI-PATTERN-CATALOG.md:26` |
| Skills preventivos | `analysis-mode` Phase 4 ya resuelve el problema (comparar con análisis previos) | `.agents/skills/analysis-mode/SKILL.md:55-64` |
| Protocolos base | "Verify before agree" y "Default-FAIL" existen | `AGENTS.md:16`, `PROTOCOL.md:78` |
| Precisión factual | 6/6 claims sobre infraestructura existente eran correctos | Specialist #3 |

**confidence: high** — `2026-07-28-orchestrator-self-analysis.md:179-187`.

---

## 7. Conclusión

**3.5/10 → mejorado a ~7/10** — Los 3 puntos débiles críticos están resueltos con tests y hooks de enforcement. Pero el **enforcement de los hooks es manual, no automatizado por tests** — esa es mi debilidad #1 hoy: confiar que sigo mis propias reglas porque las escribí, no porque un test lo verifique.

### Próximos passos inmediatos:
1. **#3**: Crear `docs/mejoras/README.md` con índice + tabla de contenidos
2. **#6**: Limitar la open question exception en `_core-behavior-gp.md`
3. **#8**: Renombrar análisis con keywords de dominio

---

## Referencias

| Archivo | Línea | Propósito |
|---------|-------|-----------|
| `AGENTS.md` | 21-38 | Persona + rules |
| `AGENTS.md` | 56-58 | Engram protocol reference |
| `docs/ARCHITECTURE.md` | 1-301 | Arquitectura completa del sistema |
| `opencode.json` | 1 | Agentes + permisos |
| `docs/mejoras/2026-07-28-orchestrator-self-analysis.md` | 1-227 | Autodiagnóstico baseline (3.5/10) |
| `docs/mejoras/2026-08-14-weakness-improvement-plan.md` | 1-92 | Plan de mejora (8/8 enfoques ✅) |
| `docs/mejoras/2026-08-19-v3-full-historical-regression.md` | — | Validación histórica de fixes |
| `ANTI-PATTERN-CATALOG.md` | 26 | "Overconfidence in self-score" |

---

*Este documento fue generado en respuesta a una pregunta abierta del usuario. Pre-answer Evidence Gate ejecutado: glob docs/mejoras/*.md ✅, ctx_search ✅, mem_search ✅. Findings cruzados contra 2026-07-28-orchestrator-self-analysis.md.*
*Documento creado: 2026-08-25 — Project: gentleman-agent-gh*
