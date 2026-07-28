# Meta-Análisis: Orchestrator Self-Awareness Failure

**Fecha**: 2026-07-28
**Especialistas**: Knowledge Retrieval · Protocol Compliance · Information Quality · Discoverability UX · Systemic Fix
**Total findings**: 8 → consolidados top 8 por riesgo
**Trigger**: `!analisis` — usuario detectó que orquestador respondió con ~50% conocimiento existente que no buscó

---

## Resumen Ejecutivo

El orquestador falló en un patrón predecible: ante una pregunta abierta ("¿qué te falta?"), respondió desde conocimiento paramétrico (training data + contexto inmediato) sin buscar evidencia documentada existente en el propio proyecto. El resultado: ~50% de lo dicho ya existía documentado y era discoverable, ~30% eran ideas genuinamente nuevas no validadas, y ~20% era especulación sin sustento.

**El problema no es de capacidad técnica sino de protocolo**: las herramientas existen (Engram, ctx_search, codebase-memory, 9 análisis previos en `docs/mejoras/`) pero no hay un gate que obligue al orquestador a consultarlas antes de responder preguntas analíticas.

---

## Tabla de Síntesis (Top 8)

| # | Finding | Consenso | Riesgo | Dim | Archivos | Recomendación |
|---|---------|----------|--------|-----|----------|---------------|
| 1 | **No pre-answer evidence gate** — orquestador responde sin buscar documentación existente. Tools existen (engram, ctx_search) pero ningún workflow las activa para preguntas analíticas | UNANIMOUS | **CRÍTICO** | Architecture | `gentleman-vMK.md`, `_core-behavior-gp.md` | Hard gate: antes de responder gaps/análisis → `glob docs/mejoras/*.md` + `ctx_search("analysis:")` + `mem_search("analysis:")` |
| 2 | **"Verify before agree" + "Default-FAIL" ignorados** — ~20% especulación sin tool output que la respalde. Dos protocolos explícitos violados | UNANIMOUS | **CRÍTICO** | Protocol | `AGENTS.md:16`, `PROTOCOL.md:78` | No nueva regla — reforzar existing. Agregar auto-check post-respuesta: "¿cada claim tiene tool output?" |
| 3 | **`docs/mejoras/` es un sink** — 9 análisis escritos pero nunca leídos por el orquestador. Sin índice, sin referencias cruzadas desde protocolos | UNANIMOUS | **ALTO** | DX | `docs/mejoras/*.md` | Agregar `docs/mejoras/README.md` con índice + tabla de contenidos |
| 4 | **Calibración de confianza falló** — claims verificables (6/6 correctos) y especulación presentados con mismo peso epistémico | MAJORITY | **ALTO** | Data | Todos los prompts | Obligar `confidence: high/medium/low` en outputs de análisis |
| 5 | **`analysis-mode` ya resuelve el problema pero solo en `!analisis`** — Phase 4 del skill compara con análisis previos, pero no se auto-triggerea | UNANIMOUS | **ALTO** | Arch | `.agents/skills/analysis-mode/SKILL.md` | Auto-trigger `analysis-mode` para preguntas de gaps/"qué falta" |
| 6 | **Open question exception desactiva pipeline preventivo** — `_core-behavior-gp.md` permite respuesta directa para open questions, saltando el pipeline de análisis | MAJORITY | **MEDIO** | Protocol | `_core-behavior-gp.md` | Limitar exception: solo para preguntas factuales simples, no para análisis |
| 7 | **3 skills describen proactive search (engram-protocol, workflow-optimizer, session-resume) pero ninguna enforce** — adherencia voluntaria, no obligatoria | MAJORITY | **MEDIO** | DX | 3 skill files | Consolidar en 1 skill con hard gate en `gentleman-vMK.md` |
| 8 | **Nombres homogéneos en `docs/mejoras/`** — 5/8 archivos siguen patrón `YYYY-MM-DD-gentleman-agent-gh-analisis.md`, imposible distinguir contenido sin abrirlos | UNANIMOUS | **BAJO** | DX | `docs/mejoras/*.md` | Incluir keyword de dominio en filename (ej: `*-retrieval-analysis.md`) |

---

## Matriz de Riesgo

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

---

## Recomendaciones por Fase

### Fase 1: Crítico — Implementar ahora

**#1 — Hard gate en `gentleman-vMK.md`**

Agregar en el prompt del orquestador, ANTES de la sección "Routing":

```yaml
## Pre-Answer Evidence Gate (MANDATORY for gap/analysis questions)

Before answering "what's missing", "qué falta", "gaps", "needs improvement":
1. glob `docs/mejoras/*.md` — list existing analyses
2. `ctx_search(queries: ["analysis:<project>", "<topic> gaps", "<topic> improvement"])`
3. `mem_search(query: "analysis:<project>")`
4. Cross-reference: IF finding exists → cite file:line. IF novel → flag as `confidence: unvalidated`
5. Never present speculation as fact — use explicit confidence markers
```

Esfuerzo: Bajo (cambio de prompt). Impacto: Elimina el failure mode raíz.

**#2 — Reforzar "Default-FAIL"**

En `PROTOCOL.md`, agregar al Pre-Flight Gate:
```
0c. Knowledge Check: ¿Este tema ya se analizó antes? → `ctx_search("analysis:<project>")`
     Si existe análisis previo → leerlo antes de responder.
```

---

### Fase 2: Alto — Este sprint

**#3 — Índice en `docs/mejoras/`**

Crear `docs/mejoras/README.md` con:
- Tabla: Fecha | Archivo | Dominio | Hallazgos clave | Estado
- Referencia cruzada: qué finding de qué análisis sigue abierto

**#4 — Confidence markers en outputs**

Todo output de análisis del orquestador debe incluir:
```yaml
confidence: high | medium | low | unvalidated
evidence: file:line reference or "No tool output — speculative"
```

**#5 — Auto-trigger analysis-mode**

En `_core-behavior-gp.md`:
```
## Analytical question detection
If user asks about gaps, completeness, "what's missing", or self-evaluation:
→ Auto-load `analysis-mode` skill OR run lightweight: `glob docs/mejoras/*.md` + `ctx_search`
→ Cite before answering
```

---

### Fase 3: Medio — Próximo ciclo

**#6 — Limitar open question exception**
**#7 — Consolidar proactive search en 1 skill**
**#8 — Renombrar análisis con keywords de dominio**

---

## Hallazgos por Dimensión

### 🔒 Security (self)
| Severidad | Count | Highlights |
|-----------|-------|------------|
| N/A | 1 | Failure mode no tiene implicaciones de seguridad |

### ⚡ Performance (self)
| Severidad | Count | Highlights |
|-----------|-------|------------|
| MEDIO | 1 | ~3K tokens en especulación no verificada. Costo de oportunidad: duplicación de esfuerzo usuario |

### 🎨 UX (Especialista #4)
| Severidad | Count | Highlights |
|-----------|-------|------------|
| FAIL | 1 | Conocimiento existe pero indescubrible. Directorio sink. |

### 🏗️ Infra (Especialista #1)
| Severidad | Count | Highlights |
|-----------|-------|------------|
| FAIL | 1 | Tools existen (engram, ctx_search) pero desacopladas del protocolo |

### 📊 Data Quality (Especialista #3)
| Severidad | Count | Highlights |
|-----------|-------|------------|
| FLAG | 1 | Precisión factual correcta (6/6) pero calibración de confianza falló |

### 🏛️ Architecture (self)
| Severidad | Count | Highlights |
|-----------|-------|------------|
| FAIL | 1 | Orquestador no siguió su propia arquitectura de routing. Violó Builder ≠ Orquestador |

### 📝 DX/Docs (Especialista #4)
| Severidad | Count | Highlights |
|-----------|-------|------------|
| FAIL | 1 | `docs/mejoras/` sin índice. 6 referencias en todo el codebase, todas de escritura |

### 💼 Business (self)
| Severidad | Count | Highlights |
|-----------|-------|------------|
| MEDIO | 1 | Impacto: retrabajo. No catastrófico pero erosiona confianza |

---

## Consenso de Especialistas

| Consenso | Findings | Descripción |
|----------|----------|-------------|
| **UNANIMOUS** | #1, #2, #3, #5, #8 | Todos los especialistas coinciden |
| **MAJORITY** | #4, #6, #7 | ≥50% coinciden |

---

## Bright Spots (lo que está bien)

| Area | What | Evidence |
|------|------|----------|
| **Infra de retrieval** | Engram, ctx_search, codebase-memory, context-mode MCP — todo instalado y funcional | `opencode.json`, tools disponibles |
| **Auto-conciencia del proyecto** | El proyecto ya documentó su propio anti-patrón de "Overconfidence in self-score" en ANTI-PATTERN-CATALOG.md | `ANTI-PATTERN-CATALOG.md:26` |
| **Skills preventivos** | `analysis-mode` Phase 4 ya resuelve el problema (comparar con análisis previos) | `.agents/skills/analysis-mode/SKILL.md:55-64` |
| **Protocolos base** | "Verify before agree" y "Default-FAIL" existen — el problema es enforcement | `AGENTS.md:16`, `PROTOCOL.md:78` |
| **Precisión factual** | 6/6 claims sobre infraestructura existente eran correctos | Specialist #3 |

---

## Trend Analysis

**No previous analysis for this type (orchestrator meta-analysis) — this is the baseline.**

El proyecto tiene 3 análisis previos de su propia arquitectura (reliability, engineering, deep analysis en julio 2026) pero ninguno analiza el comportamiento del orquestador como emisor de información. Este es el primer análisis de self-awareness del sistema.

---

## Engram Persistence

- **Observation ID**: Pendiente de confirmación post-mem_save
- **topic_key**: `analysis/gentleman-agent-gh`
- **Timestamp**: 2026-07-28T16:55:00Z
- **Nota**: Primer análisis de meta-comportamiento del orquestador. Sin baseline previo.

---

## Conclusión

**3.5/10 — Mecanismos existen, enforcement es nulo.**

El proyecto tiene la infraestructura para prevenir este failure mode:
- ✅ Tools de retrieval (Engram, ctx_search, glob)
- ✅ Skills que describen búsqueda proactiva (engram-protocol, workflow-optimizer)
- ✅ Análisis previos documentados (9 en `docs/mejoras/`)
- ✅ Protocolos base ("Verify before agree", "Default-FAIL")

Pero **nada obliga al orquestador a usarlos** antes de responder. Es como tener extintores pero sin detector de humo — el equipo está, pero nada activa su uso.

**La solución más efectiva y más barata**: agregar 10 líneas al prompt `gentleman-vMK.md` (el que el orquestador SIEMPRE carga) con un "Pre-Answer Evidence Gate" que fuerce `glob + ctx_search + mem_search` antes de responder preguntas analíticas.

**Costo**: ~30 minutos de edición de prompt. **Impacto**: elimina el failure mode raíz de raíz.

---

*Generado por analysis-mode v4.6 — 5 especialistas, 8 dimensiones, 8 findings consolidados*
*Trigger: `!analisis` — autoconciencia del orquestador*
