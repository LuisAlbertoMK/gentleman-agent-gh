# Plan Consolidado de Mejoras — Gentleman Agent

> **Fecha**: 2026-07-05
> **Agentes**: gentleman-performance (Qwen3.7 Max) + gentleman-infra (GLM-5.2) + gentleman-docs (MiMo V2.5 Pro)
> **Score actual**: 9.1/10 | **Target**: 9.8/10

---

## Resumen Ejecutivo

| Métrica | Actual | Target | Mejora |
|---------|--------|--------|--------|
| **Score general** | 9.1/10 | 9.8/10 | +8% |
| **Startup latency** | ~2,050ms | ~800ms | -61% |
| **Token overhead/session** | ~16,000 tok | ~9,000 tok | -44% |
| **score-auto.ps1 time** | ~15-25s | ~2-3s | -88% |
| **File I/O operations** | ~200+ per score | ~30 per score | -85% |
| **AGENTS.md tokens** | 7,288 tok | 3,800 tok | -48% |
| **Agent prompt waste** | 6,716 tok | 3,800 tok | -43% |

---

## Phase 1: Quick Wins (2-4 horas, ~60% del impacto)

### P1.1 — Cache score-auto.ps1 (CRITICAL)
**Archivo**: `scripts/score-auto.ps1`
**Problema**: 200+ file reads, 3 subprocess spawns, 0 caching
**Solución**:
1. Crear `.learnings/score-cache.json` con hash de inputs
2. TTL por dimensión (ver tabla en 02-infra-caching-audit.md)
3. Git-HEAD invalidation para cambios de archivos
**Impacto**: -88% score time (25s → 3s)
**Esfuerzo**: 3-4 horas

### P1.2 — Batch file reads en cross-ref-check.ps1
**Archivo**: `scripts/cross-ref-check.ps1:12,20,29,33`
**Problema**: 4x `Get-ChildItem` idéntico en mismo directorio
**Solución**: Cache `$allSkillDirs` al inicio, reusar
**Impacto**: -800ms por ejecución
**Esfuerzo**: 15 min

### P1.3 — Deduplicate agent prompts
**Archivo**: `opencode.json` (11 agents)
**Problema**: 7 agentes "ANALYZE ONLY" repiten ~300 tokens de boilerplate
**Solución**:
1. Crear `prompts/shared/analyze-only-base.md` (~300 tok)
2. Crear `prompts/shared/core-behavior.md` (~200 tok)
3. Cada agente: role (50 tok) + file references
**Impacto**: -2,900 tokens
**Esfuerzo**: 2-3 horas

### P1.4 — Local AGENTS.md → project overrides only
**Archivo**: `AGENTS.md` (local)
**Problema**: Duplica 18 secciones del global (~/.config/opencode/AGENTS.md)
**Solución**: Local solo contiene Project Context + overrides específicos
**Impacto**: -3,400 tokens/session
**Esfuerzo**: 30 min

### P1.5 — ANTI-PATTERN-CATALOG lazy load
**Archivo**: `ANTI-PATTERN-CATALOG.md`
**Problema**: 2,244 tokens cargados cada sesión, 90% no se usan
**Solución**:
1. Split en `ANTI-PATTERN-CHEATSHEET.md` (~600 tok, siempre cargado)
2. Full catalog on-demand (cuando immune-system trigger)
**Impacto**: -1,644 tokens/session
**Esfuerzo**: 1 hora

### P1.6 — Compress opencode-model-router SKILL.md
**Archivo**: `.agents/skills/opencode-model-router/SKILL.md`
**Problema**: 9,981 bytes (3.2x over threshold), tablas redundantes
**Solución**: Mover tablas detalladas a `references/`, keep solo decision tree
**Impacto**: -5,000 bytes (~1,250 tokens)
**Esfuerzo**: 1 hora

---

## Phase 2: Strategic Improvements (8-12 horas, ~30% del impacto)

### P2.1 — Unified health cache layer
**Archivo**: `scripts/lib/cache.ps1` (nuevo módulo)
**Problema**: 4 scripts de health check sin cache compartido
**Solución**:
1. Módulo reutilizable con per-section TTL
2. `.learnings/health-cache.json` con invalidation por git-diff
3. Integrar en health-check.ps1, check-skill-drift.ps1, check-config-drift.ps1
**Impacto**: -70% health check time (2s → 600ms)
**Esfuerzo**: 4-6 horas

### P2.2 — Parallelize score-auto.ps1 sub-scripts
**Archivo**: `scripts/score-auto.ps1:19,28,67`
**Problema**: 3 scripts pesados corren secuencialmente
**Solución**: `Start-Job` o `ForEach-Object -Parallel` para cross-ref-check + pssa-gate + check-backlog-integrity
**Impacto**: -4-8s por `!score`
**Esfuerzo**: 2-3 horas

### P2.3 — Skill merging (32 → 11 skills)
**Archivos**: `.agents/skills/` (6 clusters)
**Problema**: Skills redundantes en context management, PR workflow, measurement
**Solución**:
1. Merge `caveman` → `lean-context`
2. Merge `context-watchdog` → `execution-mode`
3. Merge `work-unit-commits` → `branch-pr`
4. Merge `comment-writer` + `cognitive-doc-design` → `human-writing`
5. Merge `auto-metrics` + `metricas` → `metrics`
**Impacto**: -5,333 tokens, 21 menos skills
**Esfuerzo**: 6-8 horas

### P2.4 — Skill frontmatter compression
**Archivos**: Todos los SKILL.md (70 files)
**Problema**: YAML frontmatter incluye license, changelog, metadata innecesarios
**Solución**: Reducir a `name` + `triggers` + `tags` (~30 tokens vs ~120)
**Impacto**: -1,200 tokens (solo loaded skills)
**Esfuerzo**: 2-3 horas

### P2.5 — Incremental scoring
**Archivo**: `scripts/score-auto.ps1`
**Problema**: Full re-score cada vez, 90% de dimensiones no cambian
**Solución**:
1. Track file changes via git diff
2. Solo re-computar dimensiones afectadas
3. Cache dimension scores con file hash
**Impacto**: -80% score time en runs incrementales
**Esfuerzo**: 4-6 horas

---

## Phase 3: Advanced Optimizations (12-16 horas, ~10% del impacto)

### P3.1 — Skill resolution cache
**Archivo**: `scripts/skill-graph.ps1`
**Problema**: 69 skills parsed cada resolución, no caching
**Solución**:
1. Extraer registry a `scripts/skill-registry.json` (auto-generado de frontmatter)
2. Pre-build trigger index (O(1) lookup)
3. Cache resolution results con task hash
**Impacto**: -90% resolution time (200ms → 20ms)
**Esfuerzo**: 4-6 horas

### P3.2 — Token-aware skill loading
**Archivo**: AGENTS.md + skill loading protocol
**Problema**: Skills cargados sin considerar context pressure
**Solución**:
1. Track token budget en real-time
2. Auto-digest when context >60%
3. Progressive compression based on pressure
**Impacto**: -30% token usage en long sessions
**Esfuerzo**: 6-8 horas

### P3.3 — Self-learning improvements
**Archivos**: `scripts/immune-system.ps1`, `scripts/session-miner.ps1`
**Problema**: Learning loop no detecta patrones automáticamente
**Solución**:
1. Auto-extract patterns from repeated errors
2. Propose new anti-patterns cuando same error 3x
3. Integrate with dreaming skill para cross-session learning
**Impacto**: Mejor detección de patrones, menos errores repetidos
**Esfuerzo**: 4-6 horas

---

## Implementation Priority Matrix

| # | Action | Impact | Effort | Priority | ROI |
|---|--------|--------|--------|----------|-----|
| P1.1 | Cache score-auto.ps1 | CRITICAL | 3-4h | **P0** | ⭐⭐⭐⭐⭐ |
| P1.4 | Local AGENTS.md → overrides only | HIGH | 30min | **P0** | ⭐⭐⭐⭐⭐ |
| P1.5 | ANTI-PATTERN-CATALOG lazy load | HIGH | 1h | **P0** | ⭐⭐⭐⭐⭐ |
| P1.6 | Compress opencode-model-router | HIGH | 1h | **P0** | ⭐⭐⭐⭐ |
| P1.2 | Batch cross-ref-check reads | MEDIUM | 15min | **P1** | ⭐⭐⭐⭐ |
| P1.3 | Deduplicate agent prompts | HIGH | 2-3h | **P1** | ⭐⭐⭐⭐ |
| P2.1 | Unified health cache | HIGH | 4-6h | **P2** | ⭐⭐⭐ |
| P2.2 | Parallelize score-auto sub-scripts | CRITICAL | 2-3h | **P2** | ⭐⭐⭐ |
| P2.3 | Skill merging (32→11) | MEDIUM | 6-8h | **P3** | ⭐⭐ |
| P2.4 | Skill frontmatter compression | MEDIUM | 2-3h | **P3** | ⭐⭐ |
| P2.5 | Incremental scoring | HIGH | 4-6h | **P3** | ⭐⭐ |
| P3.1 | Skill resolution cache | MEDIUM | 4-6h | **P4** | ⭐ |
| P3.2 | Token-aware skill loading | MEDIUM | 6-8h | **P4** | ⭐ |
| P3.3 | Self-learning improvements | MEDIUM | 4-6h | **P4** | ⭐ |

---

## Reports Detallados

Los 3 agentes especializados guardaron sus análisis completos en:

1. **`docs/mejoras/01-performance-audit.md`** — gentleman-performance (Qwen3.7 Max)
   - 25 bottlenecks identificados
   - Score: 6.5/10
   - Top 3: score-auto sequential chain, cross-ref-check 4x enum, redundant GCI

2. **`docs/mejoras/02-infra-caching-audit.md`** — gentleman-infra (GLM-5.2)
   - 1 cache existente, 8 operaciones sin cache
   - Unified cache layer design
   - score-auto.ps1: 200+ file reads, 3 subprocess spawns

3. **`docs/mejoras/03-token-docs-audit.md`** — gentleman-docs (MiMo V2.5 Pro)
   - 49,412 tokens estáticos → 34,200 target (-31%)
   - AGENTS.md: 7,288 → 3,800 (-48%)
   - Agent prompts: 6,716 → 3,800 (-43%)

---

## Expected Results

| Metric | Before Phase 1 | After Phase 1 | After Phase 2 | After Phase 3 |
|--------|----------------|---------------|---------------|---------------|
| Score | 9.1/10 | 9.4/10 | 9.6/10 | 9.8/10 |
| Startup | 2,050ms | 1,200ms | 800ms | 600ms |
| score-auto time | 15-25s | 8-10s | 3-5s | 2-3s |
| Token overhead | 16,000 tok | 11,000 tok | 9,000 tok | 7,500 tok |
| File I/O per score | 200+ | 80 | 30 | 20 |

---

## Next Steps

1. **Implementar Phase 1** (2-4 horas) — Quick wins con mayor ROI
2. **Verificar con `!score`** — Medir impacto real
3. **Planificar Phase 2** — Strategic improvements
4. **Documentar en CYCLE.md** — Track progress

**Total effort estimado**: 22-32 horas para todas las fases
**Phase 1 alone**: 2-4 horas para ~60% del impacto total
