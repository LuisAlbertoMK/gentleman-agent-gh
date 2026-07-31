# Plan: Sistema de Conocimiento Cross-Project

> Consolidado de 4 subagentes de investigación (2026-07-07)
> Arquitecto: gentleman-vMK
> Estado: **Plan — pendiente de aprobación**

---

## Índice

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Arquitectura general](#2-arquitectura-general)
3. [Componentes](#3-componentes)
   - 3.1 Pattern Store
   - 3.2 Pattern Guard
   - 3.3 Skill Forge
4. [Taxonomía de categorías](#4-taxonomía-de-categorías)
5. [Flujo de datos](#5-flujo-de-datos)
6. [Plan de implementación por fases](#6-plan-de-implementación-por-fases)
7. [Matriz de riesgos](#7-matriz-de-riesgos)
8. [Métricas de éxito](#8-métricas-de-éxito)
9. [Puntos de integración](#9-puntos-de-integración)
10. [Lo que no cambia](#10-lo-que-no-cambia)

---

## 1. Resumen ejecutivo

**Problema:** Hoy el aprendizaje del agente es estanco por proyecto. Lo que se aprende en la landing page farmacia no se aplica automáticamente a la próxima landing page. Lo que se descubre en una API no se replica a otras APIs.

**Solución:** Una **Wisdom Layer** cross-project compuesta de tres componentes:
1. **Pattern Store** — almacén persistente de patrones aprendidos, categorizados por tipo de proyecto
2. **Pattern Guard** — detector proactivo que al iniciar un proyecto nuevo busca patrones conocidos
3. **Skill Forge** — pipeline que promueve patrones recurrentes (≥2 proyectos) a skills auto-generados

**Filosofía:** Híbrido minimalista. Engram (`scope: personal`) para retrieval rápido. Archivos (`docs/cross-project/patterns/`) como fuente de verdad versionada. Nada de bases nuevas, nada de dependencias externas.

---

## 2. Arquitectura general

```
                          ┌─────────────────────────────────────┐
                          │        CROSS-PROJECT WISDOM        │
                          └─────────────────────────────────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              ▼                      ▼                      ▼
     ┌────────────────┐   ┌──────────────────┐   ┌──────────────────┐
     │  PATTERN MINE  │   │   PATTERN GUARD  │   │   SKILL FORGE    │
     │  (descubrir)   │   │   (detectar)     │   │   (automatizar)  │
     ├────────────────┤   ├──────────────────┤   ├──────────────────┤
      │ session-miner  │   │ project-mapper   │   │ opencode-skill-creator    │
     │ immune-system  │   │ → clasifica proy │   │ → forge skill    │
     │ dreaming       │   │ → busca patterns │   │ → quality-gate   │
     │ auto-detector  │   │ → reporta match  │   │ → registra       │
     └────────┬───────┘   └────────┬─────────┘   └────────┬─────────┘
              │                    │                       │
              └────────────────────┼───────────────────────┘
                                   ▼
                      ┌─────────────────────────┐
                      │     PATTERN STORE       │
                      │  (almacenamiento dual)  │
                      ├─────────────────────────┤
                      │ Engram scope:personal   │ ← retrieval rápido (FTS5)
                      │ docs/cross-project/     │ ← fuente de verdad (git)
                      │   patterns/{cat}/       │
                      └─────────────────────────┘
```

### Flujo de datos

```
DESCUBRIR ──► ALMACENAR ──► CLASIFICAR ──► DETECTAR ──► APLICAR ──► EVOLUCIONAR
    │             │              │              │            │            │
    ▼             ▼              ▼              ▼            ▼            ▼
session-     Pattern Store   project-      session-      pre-flight   wisdom-
miner/       Engram + files  mapper +     resume +      gate rung    forge/
immune-       (dual)         wisdom-      pattern       0b + auto-   dreaming/
system                         classifier  guard        fix          demotion
```

---

## 3. Componentes

### 3.1 Pattern Store

#### Schema de cada patrón (JSON)

```jsonc
{
  "id": "landing-a11y-001",
  "name": "Hero .btn accent + white text fails contrast",
  "version": 2,

  // Clasificación
  "category": "ux/a11y",
  "tags": ["landing-page", "hero", "contraste", "wcag"],
  "project_types": ["landing-page", "web-app"],

  // Contenido
  "symptom": "Hero CTA button with accent bg + white text → 2.5:1",
  "root_cause": "Accent color #52b788 is too light for white text",
  "fix": ".hero .btn { background: var(--clr-primary); color: var(--clr-white) }",
  "prevention": "Never use accent bg + white text without checking ratio ≥4.5:1",

  // Detección automática
  "detection": {
    "type": "regex",
    "pattern": "\\.hero\\s*\\.btn\\s*\\{[^}]*background:\\s*var\\(--clr-accent\\)[^}]*color:\\s*var\\(--clr-white\\)",
    "scope": "code",
    "confidence_weight": 0.85
  },

  // Metadata
  "severity": "high",
  "confidence": 0.72,
  "occurrences": [
    { "project": "gentleman-agent-gh", "date": "2026-07-07", "count": 1, "resolved": true },
    { "project": "proyecto-x", "date": "2026-06-15", "count": 1, "resolved": true }
  ],
  "first_seen": "2026-06-15",
  "last_seen": "2026-07-07",
  "deprecated": false,
  "status": "active",

  // Referencias
  "ref_files": [
    "docs/revisiones/farmacia/styles.css",
    "docs/cross-project/evidence/contrast-fix-001.md"
  ],
  "related_patterns": ["landing-a11y-002"]
}
```

#### Estrategia de almacenamiento (dual)

| Capa | Storage | Propósito | Update |
|------|---------|-----------|--------|
| **Runtime index** | Engram `scope: personal` | Búsqueda FTS5 cross-project, ranking | Escritura en cada `!close` |
| **Source of truth** | `docs/cross-project/patterns/{cat}/{id}.json` | Versionado, review, PR, portabilidad | Escritura en cada `!close` |
| **Session cache** | Engram `scope: project` | Patrones activos/suprimidos del proyecto actual | Lectura/escritura en sesión |

**Principio:** Engram es caché, archivos son fuente de verdad. Engram siempre regenerable desde archivos.

#### Taxonomía — árbol de categorías

Ver [sección 4](#4-taxonomía-de-categorías).

#### Fórmula de ranking (retrieval)

```
score = (overlap_project_types × 0.40)
      + (confidence × 0.30)
      + (recency_factor × 0.30)

recency_factor = 1.0 / (días_desde_última_ocurrencia + 1)
```

Threshold de visualización: `score ≥ 0.3`. Top 10 patrones máximo.

#### Ciclo de vida de un patrón

```
DESCUBIERTO → BORRADOR → ACTIVO → OBSOLETO → ARCHIVADO
     │           │          │         │          │
  1 proyecto   2+ proy   conf≥0.5  90d sin    180d en
  (Engram)     (Engram   + en       hits       obsoleto
                + file)    archivo
```

Fórmula de confianza:
```
confidence = min(1.0,
    (proyectos_únicos × 0.15)      // breadth
  + (ocurrencias_totales × 0.05)   // depth
  + (factor_severidad × 0.10)      // critical=1.0, high=0.75, medium=0.5, low=0.25
  + (factor_actualidad × 0.05)     // <30d=0.3 >90d=0
)
```

---

### 3.2 Pattern Guard

#### Clasificación de proyecto

Usa `project-mapper` existente + gap-analysis categories:

```
Entrada: estructura del proyecto (package.json, go.mod, *.html, Dockerfile...)
Salida: { tech_layer: "frontend", biz_type: "landing-page", confidence: 0.9 }
```

Cada archivo señal aporta un peso. Si top-2 tipos quedan a <0.15 de distancia → clasificación ambigua, mostrar ambos.

#### Matching

```
1. mem_search(query="patterns/{biz_type}/*", all_projects=true, limit=50)
2. Si <3 resultados: expandir a "patterns/{tech_layer}/*"
3. Ranking por fórmula de score (§3.1)
4. Top 10 con score ≥ 0.3
```

#### Capas de detección

| Modo | Costo | Qué corre | Cuándo |
|------|-------|-----------|--------|
| **LAZY** | <100ms | grep + glob por detection_heuristic | Siempre después de clasificar |
| **BATCH** | ~segundos | + static analysis, linters | Background post-session-start |
| **ON_DEMAND** | lento | Playwright, npm audit, etc. | Solo si usuario pide (`!guard`) |

#### Cuándo y cómo reportar

| Momento | Acción |
|---------|--------|
| **Session start** | Si hay patrones CRITICAL → alerta inmediata. Si no → guardar en "relevant patterns" |
| **Pre-flight rung 0b** | Solo si la tarea toca tags del patrón. "add endpoint" gatilla patterns de API/security |
| **On-demand** | `!guard`, `!guard security`, `!guard run <pattern-id>` |
| **Nunca** | Bloquear un commit. Los patrones son advisory, no hard gate. |

#### Feedback loop

| Usuario dice | Sistema hace |
|-------------|--------------|
| "No aplica" | Suprime para este proyecto + baja prioridad global. Si 3x → auto-desactiva |
| "Arreglalo" | Auto-fix si detection_heuristic permite diff seguro. Muestra diff primero. |
| "Falso positivo" | -0.2 confianza. Si 2 reportes → exclusion rule automática |
| "Se revertió" | Baja a INFO + immune-system cataloga la reversión |

Cada patrón tiene **health score**:
```
health = triggers × 0.3 − suppressed × 0.2 − false_positives × 0.4 + fixes × 0.3
```
Si `health ≤ 0` → auto-deshabilitar.

---

### 3.3 Skill Forge

#### Thresholds de activación

| Severidad | Threshold | Acción |
|-----------|-----------|--------|
| CRITICAL (security, data loss, auth bypass) | 1 ocurrencia | Forja inmediata con flag `# experimental` |
| HIGH | 2 ocurrencias en ≥2 proyectos | Forja automática |
| MEDIUM | 3 ocurrencias en ≥2 proyectos | Forja automática (default) |
| LOW (convenciones, estilo) | 5 ocurrencias en ≥3 proyectos | Forja automática |

#### Pipeline de forja

```
Pattern con count ≥ threshold
│
├─ 1. GENERATE skill
│   ├─ name de pattern.name normalizado
│   ├─ description de pattern.symptom (≤120 chars)
│   ├─ triggers de pattern.tags + project_types
│   └─ rules de pattern.prevention + pattern.fix generalizados
│
├─ 2. QUALITY GATES (todos obligatorios)
│   ├─ Syntax: frontmatter YAML parsea
│   ├─ Trigger uniqueness: no duplica skills existentes
│   ├─ Size: SKILL.md ≤ 2KB (auto-Karpathy-compress si excede)
│   ├─ Non-trivial: al menos 1 regla ejecutable (verbo imperativo + condición)
│   ├─ Conflict check: no contradice skill existente
│   ├─ Integration test: skill-graph resuelve el skill para su trigger
│   └─ Security scan: sin secrets ni paths locales
│
├─ 3. REGISTER
│   ├─ Copy a .agents/skills/cross-project-{name}/SKILL.md
│   ├─ skill-registry scan → detecta nuevo skill
│   ├─ skill-graph re-scan → agrega al resolver (lazy-load, no auto-load)
│   └─ AGENTS.md: agregar a router table
│
└─ 4. PERSIST
    └─ mem_save(topic_key="forge/{name}", content=metadata)
```

#### Actualización (merge)

```
Nueva ocurrencia de pattern existente
│
├─ pattern.key == skill.name → UPDATE
│   ├─ Prevention nuevo o más específico → merge a reglas
│   ├─ Trigger word nueva → agregar (si unique)
│   ├─ Proyecto nuevo → agregar a metadata.forge.projects
│   └─ Version bump (floor(count/2) + 1)
│
├─ pattern.key similar (fuzzy >0.8) → RESOLUTION
│   ├─ Caso específico de skill existente → agregar como sub-regla
│   ├─ Variante ortogonal → skill separado
│   └─ Contradicción → mark forge:conflict, escalar a humano
│
└─ Pre-merge: backup snapshot → skills/{name}/.forge-backups/{v}.md
```

#### Rollback

```powershell
forge-rollback.ps1 -Name cross-project-hero-btn -Version 1
# Restaura snapshot, baja version en metadata
```

#### Auto-removal por desuso

Si un skill forjado no se resuelve en 14 días → auto-remove + engram log. Configurable en `~/.config/skill-forge/config.json`.

---

## 4. Taxonomía de categorías

Categorización jerárquica para `pattern.category`. Formato: `dominio/subdominio`.

```
ps/                       # PowerShell / shell scripting
  encoding                # PS5.1 encoding corruption, BOM
  match                   # -match vs -cmatch, regex alternation
  syntax                  # TDZ, positional limits, stack traps
  pipeline                # &&/||, chain operators
  performance             # slow cmdlets

svg/                      # SVG
  animation               # transform-origin, <animate> vs CSS
  geometry                # viewBox math, coordinate systems

gate/                     # Pre-flight / quality gates
  order                   # checks before decisions
  bypass                  # Paso 0 suppression
  false-positive          # regex false positives
  guardrail               # post-restore validation

agent-behavior/           # Patrones de comportamiento del agente
  over-communication      # filler, restatement, over-explaining
  premature-action        # code before understanding
  destructive-op          # delete/move without read
  overconfidence          # self-score without external audit

project-structure/        # Organización del código
  imports                 # require/import order
  naming                  # conventions, case sensitivity
  tech-debt               # TODO/FIXME accumulation

security/                 # Seguridad
  secrets                 # hardcoded credentials
  injection               # unsanitized input
  crypto                  # weak algorithms
  dependency              # outdated libs

performance/              # Performance
  bundle                  # code splitting
  n-plus-1                # N+1 queries
  cache                   # missing cache headers
  memory                  # leaks, uninitialized accumulators

ux/                       # Experiencia de usuario
  a11y                    # accesibilidad (contraste, ARIA, focus)
  responsive              # mobile-first, breakpoints
  feedback                # loading/empty/error states
  touch                   # touch targets <48px

testing/                  # Testing
  missing                 # zero coverage
  fragile                 # tightly coupled tests
  slow                    # suite >5min
  flaky                   # non-deterministic tests

ci-cd/                    # CI/CD
  build-time              # slow builds
  secret-leak             # secrets in CI logs
  deploy                  # rollback strategy missing

general/                  # Sin clasificar / misc
  workflow                # repeatable process improvements
  preference              # user preferences
  gotcha                  # tool-specific surprises
```

**Reglas de evolución de la taxonomía:**
- Tags se promueven a categoría cuando ≥3 patrones comparten el mismo tag
- `general/` es catch-all — previene parálisis por categorización
- Nuevas categorías se crean por PR a `docs/cross-project/PLAN.md`

---

## 5. Flujo de datos detallado

### 5.1 Discovery (descubrir patrón)

```
session-miner.ps1
├─ Al cierre de sesión: extrae conclusiones, bugs, fixes
├─ immune-system: si detecta error repetido → nuevo patrón
├─ dreaming: cruza sesiones → identifica patrones cross-session
└─ auto-pattern-detector.ps1: grep+runs de detection_heuristic
    │
    ▼
¿Existe ya este patrón en Pattern Store? (fuzzy match por symptom)
├─ SÍ → append occurrence, update confidence/last_seen
└─ NO → create draft (Engram scope:personal only)
```

### 5.2 Retrieval (recuperar al iniciar proyecto)

```
session-resume
├─ project-mapper: clasifica proyecto actual
├─ wisdom-classifier: expande a tech_layer + biz_type
├─ Engram mem_search(query="patterns/{biz_type}/*", all_projects=true)
│   └─ Si <3 resultados: expandir a patterns/{tech_layer}/*
├─ Rank por fórmula de score
├─ Top 10 con score ≥ 0.3 → cargar en contexto como "relevant patterns"
└─ Alertar solo si severity=CRITICAL. Resto: disponible bajo demanda.
```

### 5.3 Guard (detectar en tarea actual)

```
Pre-flight rung 0b (entre factibilidad y YAGNI)
├─ Si la tarea menciona tags de algún patrón activo:
│   └─ Ejecutar LAZY detection (grep/glob, <200ms timeout)
│       ├─ Match → BLOCK? NO. Mostrar como advertencia:
│       │   "⚠️ Este proyecto tiene el patrón P-001 (confianza 0.72).
│       │    ¿Querés ver el detalle?" → "guard show P-001"
│       └─ No match → silencio
└─ Si timeout: diferir a BATCH detection en background
```

### 5.4 Forge (promover patrón a skill)

```
Pattern con count ≥ threshold(severity)
├─ forge-pipeline.ps1
│   ├─ Generate SKILL.md from pattern data
│   ├─ Run quality gates (syntax, triggers, size, conflict, integration)
│   │   ├─ ALL PASS → register
│   │   └─ ANY FAIL → log + no-forge + notificar en próxima sesión
│   └─ mem_save(topic_key="forge/{name}")
│
└─ Resultado:
    ├─ Nuevo skill en .agents/skills/cross-project-{name}/
    ├─ Registrado en skill-graph (lazy-load)
    ├─ Registrado en AGENTS.md (router table)
    └─ Patrón actualizado: status=promoted, skill_ref=skill-name
```

### 5.5 Evolución (mantenimiento periódico)

```
dreaming / !dream
├─ Patrones con health ≤ 0 → auto-deshabilitar
├─ Skills forjados sin resolución en 14d → auto-remove
├─ Patrones con 0 ocurrencias en 90d → deprecated
├─ Patrones deprecated >180d → archived (mover a docs/cross-project/archived/)
└─ Reportar cambios en próxima sesión
```

```
!score → wisdom-stats.ps1
├─ Pattern hit rate: cargados vs aplicados
├─ False positive rate: suprimidos vs total
├─ Forge rate: patrones que llegaron a skill
└─ Tendencia: +% o -% vs semana anterior
```

---

## 6. Plan de implementación por fases

### Fase 1: HOY — Fundación

**Objetivo:** Que exista el almacén y se pueda guardar/recuperar un patrón.

| # | Tarea | Archivos | Esfuerzo |
|---|-------|----------|----------|
| 1 | Crear estructura `docs/cross-project/` | `patterns/`, `backlog/`, `README.md` | 5min |
| 2 | Migrar patrones de esta sesión a Pattern Store | 3-4 patrones a `docs/cross-project/patterns/` | 15min |
| 3 | Crear skill `cross-project-wisdom` | `.agents/skills/cross-project-wisdom/SKILL.md` | 15min |
| 4 | Modificar `session-resume` para cargar wisdom al inicio | `.agents/skills/session-resume/SKILL.md` | 10min |
| 5 | Agregar rung 0b al Pre-Flight Gate | `AGENTS.md` | 10min |
| 6 | Agregar shortcut `!wisdom` | `AGENTS.md` | 5min |
| 7 | Guardar plan en engram | `mem_save(topic_key=architecture/cross-project-plan)` | 2min |
| **Total** | **7 tareas** | **~1h** | |

### Fase 2: MAÑANA (próximas 3 sesiones) — Automatización

**Objetivo:** El sistema descubre y clasifica patrones automáticamente.

| # | Tarea | Depende de |
|---|-------|-----------|
| 1 | `scripts/wisdom-store.ps1` — guardar/migrar patrones | F1-1 |
| 2 | `scripts/wisdom-loader.ps1` — retrieval con ranking | F1-1 |
| 3 | Modificar `immune-system` para guardar en `scope: personal` | F1-1 |
| 4 | Modificar `session-miner.ps1` para extraer patrones al `!close` | F1-1 |
| 5 | `scripts/pattern-guard.ps1` — LAZY detection por grep/glob | F2-2 |
| 6 | Extender `!analisis` para inyectar wisdom en análisis | F2-5 |
| 7 | Crear skill `cross-project-forge` (pipeline manual aún) | F2-3 |
| 8 | `scripts/wisdom-stats.ps1` — hit rate y métricas | F2-2 |
| **Total** | **8 tareas** | **~3h** |

### Fase 3: PASADO (cuando haya 10+ patrones) — Evolución autónoma

**Objetivo:** El sistema promueve/elimina patrones solo.

| # | Tarea | Depende de |
|---|-------|-----------|
| 1 | `scripts/wisdom-forge.ps1` — auto-crear skills desde patrones | F2-7 |
| 2 | Forge quality gates (syntax, triggers, size, conflict) | F3-1 |
| 3 | Forge rollback (`forge-rollback.ps1`) | F3-1 |
| 4 | Auto-demotion: 90d sin hits → deprecated | F2-8 |
| 5 | Auto-removal de skills forjados no usados en 14d | F3-1 |
| 6 | Dreaming integration: `!dream` revisa wisdom store | F2-8 |
| 7 | Ciclo dedicado en CYCLE.md: "prune stale wisdom" | F3-4 |
| **Total** | **7 tareas** | **~4h** |

---

## 7. Matriz de riesgos

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|--------|-------|---------|-----------|
| R1 | **Pattern noise**: demasiados patrones irrelevantes | Alta | Medio | Auto-demotion 30d sin hit. Threshold score ≥0.3. Human-in-loop para promoción a skill. |
| R2 | **Skill bloat**: skills auto-generados degradan resolución | Media | Medio | Skills forjados van a directorio separado. Lazy-load, no auto-load. Límite de 5 skills auto-generados. |
| R3 | **False confidence**: usuario confía en patrón incorrecto | Baja | Alto | Patrones son advisory, no bloquean. Confidence score visible. Health score ≤0 → auto-deshabilitar. |
| R4 | **Pattern duplication**: mismo patrón guardado N veces | Media | Bajo | Dedup por hash de root cause. Normalize title antes de guardar. |
| R5 | **Engram drift**: archivos y Engram se desincronizan | Media | Medio | Engram es caché, archivos son verdad. Regenerar Engram desde archivos en session start. |
| R6 | **Patrones irrelevantes para bugs project-specific** | Alta | Bajo | Tech-stack tags + project-mapper fingerprint filtran. Default: ≤3 patrones por categoría. |
| R7 | **Rung 0b ralentiza pre-flight** | Media | Medio | Hard timeout 200ms para LAZY detection. Si excede → diferir a background. |

### Mapa de calor

```
Probabilidad
  ▲
ALTA  │ R1 R6 │       │       │
      │        │       │       │
MEDIA │ R4 R7  │ R2 R5 │       │
      │        │       │       │
BAJA  │        │       │ R3    │
      └────────┴───────┴───────┴────► Impacto
          BAJO    MEDIO   ALTO
```

---

## 8. Métricas de éxito

### Cuantitativas

| Métrica | Cómo se mide | Target | Fase |
|---------|-------------|--------|------|
| **Pattern hit rate** | `wisdom-stats.ps1`: patrones cargados / patrones que gatillaron acción | >20% | F2 |
| **False positive rate** | `wisdom-stats.ps1`: suprimidos / total cargados | <15% | F2 |
| **Time-to-apply** | Desde detección hasta fix (session logs) | <5min | F2 |
| **Bug recurrencia cross-project** | Mismo root cause en proyectos distintos después de documentado | 0 | F3 |
| **Pattern → skill rate** | Patrones que llegan a ≥2 proyectos y se forjan | >30% | F3 |
| **Wisdom store size** | Patrones totales en store | <50 | ongoing |

### Cualitativas

| Señal | Significa |
|-------|-----------|
| Usuario no repite un fix entre proyectos | Wisdom está funcionando |
| Usuario se refiere a patrones por ID | Wisdom está internalizado |
| Rung 0b se siente más rápido, no más lento | Carga de wisdom está bien tuneada |
| `!analisis` referencia patrones cross-project | Integración es seamless |

---

## 9. Puntos de integración

### Con Pre-Flight Gate (Ponytail Ladder)

**Estado actual:**
```
0. Factibilidad (INBYPASSABLE)
1. YAGNI
2. Stdlib
...
```

**Estado propuesto:**
```
0a. Factibilidad (INBYPASSABLE, sin cambios)
0b. Cross-Project Pattern Check (INBYPASSABLE si hay match de tags)
    ├─ Clasificar proyecto (o reusar cache de sesión)
    ├─ Cargar patrones relevantes (score ≥ 0.3, top 5)
    ├─ LAZY detection (grep+glob, <200ms timeout)
    └─ Si tarea contradice patrón conocido → ADVERTIR (no bloquear)
1. YAGNI
...
```

### Con Session Resume

Al inicio de sesión, después de cargar el contexto del proyecto:
```
1. mem_search para sesión anterior (existente)
2. wisdom-loader: patrones que matchean proyecto actual
3. Presentar: "🧠 Patrones cross-project relevantes (N): P-XXXX, P-XXXX"
4. Si severity=CRITICAL → mostrar detalle inmediato
```

### Con !analisis Mode

Antes de despachar especialistas:
```
0.5. Inyectar wisdom cross-project
     └── Cargar patrones que matchean el stack detectado
     └── Wisdom patterns se agregan a instrucciones como "gotchas conocidos"
```

### Con Immune System

Después de diagnosticar un error:
```
Si el error matchea un patrón existente en Pattern Store:
  → Append occurrence (no crear nuevo patrón)
  → Update confidence + last_seen
  → Sync a archivo en !close

Si el error es nuevo y parece cross-project:
  → Crear draft en Pattern Store
  → Si en otro proyecto aparece el mismo → promover a borrador
```

### Con el pipeline de commit

**Advisory only.** Los patrones nunca bloquean un commit. Pero:
- `security-scanner` puede incluir un check opcional contra patrones de seguridad
- Post-commit hook (opt-in): si el fix matchea un patrón conocido, auto-incrementa su contador

---

## 10. Estructura de archivos final

```
gentleman-agent-gh/
│
├── docs/
│   └── cross-project/                    ← NUEVO
│       ├── README.md                     ← qué es y cómo funciona
│       ├── PLAN.md                       ← este documento
│       ├── patterns/                     ← un .json por patrón
│       │   ├── ux/
│       │   │   ├── landing-a11y-001.json  ← hero btn contrast
│       │   │   └── landing-a11y-002.json  ← footer span contrast
│       │   ├── general/
│       │   │   └── general-gotcha-001.json ← rgb(0,0,0) vs rgba()
│       │   └── ...
│       ├── backlog/                      ← patrones propuestos sin revisar
│       └── archived/                     ← patrones obsoletos (>180d)
│
├── .agents/
│   └── skills/
│       ├── cross-project-wisdom/         ← NUEVO: skill de retrieval
│       │   └── SKILL.md
│       └── (skills existentes sin cambios)
│
├── AGENTS.md                             ← + rung 0b + !wisdom shortcut
│
└── (scripts se agregan en Fase 2)
```

### Lo que NO cambia

- `ANTI-PATTERN-CATALOG.md` — sigue siendo el catálogo project-scoped (errores dentro de este repo)
- `CYCLE.md` — solo se agrega un objetivo cross-project
- Skills existentes — no se tocan
- Engram existente — no se migra, solo se extiende su uso con `scope: personal`
- Pre-Flight Gate existente — se extiende, no se reemplaza

---

## Apéndice: Patrones seed (de esta sesión)

Estos son los primeros 3 patrones que poblarán el Pattern Store:

| ID | Nombre | Categoría | Severidad | Proyectos |
|----|--------|-----------|-----------|-----------|
| P-001 | Hero .btn accent + white text fails contrast | `ux/a11y` | high | farmacia (docs/revisiones/farmacia) |
| P-002 | Footer span accent on dark bg fails contrast | `ux/a11y` | medium | farmacia |
| P-003 | rgb(0,0,0) confundido con rgba(0,0,0,0) | `general/gotcha` | low | gentleman-agent-gh |

---

*Plan generado el 2026-07-07. 4 subagentes de investigación. Consolidado por gentleman-vMK.*
