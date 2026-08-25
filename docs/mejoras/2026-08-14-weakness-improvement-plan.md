# Plan: Ataque a 3 puntos débiles — Protocolo Automejora v3

**Protocolo**: `docs/protocolos/protocolo_mejora_autonoma_v3.md`
**Base**: `experimento/resource-optimization-2026-08-14` → nuevo branch `experimento/weakness-improvement-2026-08-14`
**Presupuesto**: 5 enfoques por debilidad, prioridad a los que tengan bajo effort + alto impacto

---

## Debilidad 1: Memoria conversacional de mediano plazo

> *Si no guardo algo en Engram, lo pierdo entre compaction cycles. A veces repito preguntas.*

### 5 Enfoques

| Enfoque | Descripción | Effort | Impact | Risk | Confidence |
|---------|-------------|--------|--------|------|------------|
| **A** | **Proactive memory capture hook** — Auto-trigger `mem_save` en decisiones clave (decision, architecture, bugfix, pattern). Hook: post-fix / post-decision. | 2h | High | Low | high |
| **B** | **Session checkpoint system** — `session-resume` skill ya existe; fortalecer con `checkpoint` marcadores cada N interacciones + auto-resumen antes de compaction. | 3h | Medium-High | Low-Med | high |
| **C** | **Compression-aware strategy** — Priorizar qué debe sobrevivir a compaction. Definir "must-keep" list (decisions, bug fixes, configs) vs "ephemeral" (greetings, small talk). | 2h | Medium | Low | medium |
| **D** | **Cross-session context bridge** — Indexar outputs grandes en ctx_index con source tags para recuperación via ctx_search. Ya parcialmente implementado. | 4h | High | Med | medium |
| **E** | **FAQ knowledge base** — Para preguntas frecuentes sobre el proyecto, mantener un KB de Q&A actualizado. | 3h | Medium | Low | low |

### Ganador esperado: **A** (proactive capture) + **B** (checkpoint system)

---

## Debilidad 2: Creatividad vs precisión en diseño UX

> *Soy mejor detallando qué y por qué que cómo se siente la interfaz.*

### 5 Enfoques

| Enfoque | Descripción | Effort | Impact | Risk | Confidence |
|---------|-------------|--------|--------|------|------------|
| **A** | **vision-analyze + Ollama** — Capturar screenshots de componentes y analizar micro-interacciones (easing, timing, feedback states) localmente. | 4h | High | Low | high |
| **B** | **Context7 UI/UX docs** — Indexar documentación de UX patterns (Material 3, Apple HIG, shadcn/ui) para referencia creativa justificada. | 3h | High | Low | high |
| **C** | **UI specialist agent pairing** — Usar `baseline-ui` / `ui-engine` skills como subagente para generar alternativas de micro-interacciones, luego sintetizar. | 2h | Medium-High | Low | high |
| **D** | **Structured micro-interaction prompts** — Template prompt para timing, easing, duration, feedback states. Ej: "hover: 150ms ease-out, tap: 100ms scale-95". | 3h | Medium | Low | medium |
| **E** | **Visual regression feedback loop** — vision-analyze sobre cambios UI, comparar antes/después, validar coherencia visual. | 5h | High | Med | unvalidated |

### Ganador esperado: **A** (vision-analyze) + **C** (UI specialist pairing) + **B** (docs indexados)

---

## Debilidad 3: Optimización extrema de performance

> *Puedo encontrar N+1, bucles O(n²), memory hotspots... pero ajustar a microsegundos o perfiles de CPU a nivel de assembler me excede.*

### 5 Enfoques

| Enfoque | Descripción | Effort | Impact | Risk | Confidence |
|---------|-------------|--------|--------|------|------------|
| **A** | **Hardware profiling + dynamic config** — Detectar capacidad del sistema, aplicar perf-files (low/medium/high). Ya existe scripts parciales. | 3h | High | Low | high |
| **B** | **Bun/JSC heap snapshot analysis** — Automatizar captura de heap snapshots, análisis de crecimiento entre múltiples snapshots. | 4h | High | Med | high |
| **C** | **CI performance regression detection** — Benchmark estadístico (mediana/IQR, 10 runs) como quality gate en CI. | 4h | High | Low | high |
| **D** | **Config-level optimizations** — compaction.prune, watcher.ignore, snapshot.enabled, MCP timeouts. Ya investigado en resource-optimization-investigation.md. | 2h | Medium | Low | high |
| **E** | **Advanced profiling integration** — conectar con `perf-profiling` skill + OpenTelemetry para tracing distribuido. | 6h | Medium-High | Med | low |

### Ganador esperado: **A** (hardware profiling) + **C** (CI regression detection) + **D** (config-level)

---

## Execution Order (por protocolo v3 §3.1 — correctness > security > performance > size)

1. **Debilidad 1** (correctness) → A + B
2. **Debilidad 3** (performance) → D + A + C
3. **Debilidad 2** (UX) → C + B + A

## Execution Order (por protocolo v3 §3.1 — correctness > security > performance > size)

1. **Debilidad 1** (correctness) → A + B ✅ COMPLETADO
2. **Debilidad 3** (performance) → D + A + C ✅ COMPLETADO
3. **Debilidad 2** (UX) → C + B + A ✅ COMPLETADO

## DoD Verification (todos los enfoques implementados y validados)

| Debilidad | Enfoque | Estado | Archivos | Tests | confidence |
|-----------|---------|--------|----------|-------|------------|
| **1. Memory** | A: Proactive capture | ✅ Done | session-checkpoint.ps1 | 16 | high |
| **1. Memory** | B: Checkpoint system | ✅ Done | close-session.ps1 (bridge) | — | high |
| **3. Performance** | A: Hardware profiling | ✅ Done | hardware-profile.ps1 | 28 | high |
| **3. Performance** | C: CI regression gate | ✅ Done | benchmark-regression.ps1 + perf-regression.yml | 25 | high |
| **3. Performance** | D: Config-level opts | ✅ Done | opencode-configs/{low,medium,high}.json | 10 | high |
| **2. UX** | A: vision-analyze+ollama | ✅ Ready | ui-specialist-pairing.ps1 (integration) | 15 | high |
| **2. UX** | B: Indexed docs | ✅ Done | ctx_index: ui-creative-basis:m3-motion-patterns | — | high |
| **2. UX** | C: UI pairing | ✅ Done | ui-specialist-pairing.ps1 | 25 | high |

**Validation**: All scripts have valid JSON structure, zone math (12 test-points) correct, config profiles validated (required fields + profile-specific settings), CI workflow passes 10/10 structural checks.

## Constraints (Scope Lock)
- **IN**: `docs/mejoras/`, `scripts/`, `.github/workflows/`, nuevos archivos de utilidad
- **OUT**: No tocar `main`, no cambiar configs de runtime sin validación, no crear archivos fuera de scope
