# Decision Portfolio

> Documento fusionado que consolida 3 decisiones arquitectónicas del proyecto.
> Los originales de model-router-verdict y corrections-r2-patch se preservan en `docs/archive/`;
> gentleman-portable.md fue fusionado al 100% y eliminado.
>
> Origen | Tamaño | Tema
> --- | --- | ---
> `docs/archive/model-router-verdict.md` | 3.5KB | Ruteo de modelos: Big Pickle, DeepSeek, MiMo
> `docs/archive/corrections-r2-patch.md` | 16.8KB | 26 correcciones factuales a research docs

---

# Gentleman-vMK Portable — Corrección de Herencia

> **Fecha**: 2026-06-15
> **Problema**: El project `AGENTS.md` heredaba de un path absoluto (`C:\Users\MK\.config\opencode\AGENTS.md`), haciendo que el agente `gentleman-vMK` dependiera de un usuario específico. En cualquier otra máquina o con otro usuario, el agente perdía su personalidad, reglas y protocolos.

## Síntomas

- `AGENTS.md` del proyecto tenía solo 23 líneas con una sección `## Inheritance` apuntando a `C:\Users\MK\.config\opencode\AGENTS.md`
- Skills y paths hardcodeados a `C:\Users\MK\...` en múltiples archivos
- El agente `gentleman` en `opencode.json` global tenía `"tools": {"edit": true, "write": true}` — restringía TODOS los demás tools
- Al clonar el repo en otra máquina o con otro usuario, el agente no tenía instrucciones

## Archivos Modificados

| Archivo | Cambio |
|---------|--------|
| `AGENTS.md` (raíz del proyecto) | Se copió TODO el contenido inline (Rules, Personality, Pre-Flight, Engram protocol, Agent protocol) — ahora es self-contained (338 líneas) |
| `.gitignore` | `C:\Users\MK\.config\opencode\` → `$env:USERPROFILE\.config\opencode\` |
| `~/.config/opencode/AGENTS.md` | Paths hardcodeados `C:\Users\LuisOrozco\...` → portables: `{file:ANTI-PATTERN-CATALOG.md}` (relativo), `$env:TEMP\opencode\` |
| `~/.config/opencode/opencode.json` | Se agregó `gentleman-vMK` como primary agent con `{file:AGENTS.md}`, `permission { edit: allow, write: allow }` |

## Qué se eliminó

- **Sección `## Inheritance`**: Ya no existe. No se hereda de ningún archivo global.
- **Paths absolutos**: Todos los `C:\Users\MK\...` y `C:\Users\LuisOrozco\...` en archivos de configuración activa fueron reemplazados.

## Lo que NO se tocó

`CHANGELOG.md`, `BITACORA.md`, `docs/metricas/`, `docs/decisions/bitacora.md` — son registros históricos.

## Cómo replicar en una máquina nueva

Ver `docs/operations/agent-capabilities.md` para instrucciones actualizadas.

## Dato clave

El agente `gentleman` VIEJO tenía `"tools": {"edit": true, "write": true}` que bloqueaba bash, read, delegate, etc. El nuevo `gentleman-vMK` usa `"permission"` — permite todos los tools por defecto.

---

# Model Router — Veredicto y Workflow

> Resumen del análisis cruzado de `opencode-free-specialities-v3.md` + `v3(1).md`
> Generado: Jun 20, 2026 | Agente: Big Pickle

## Diagnóstico

### v3 (original)
- **Contradicción frontal**: tabla Frontend decía Big Pickle, sección decía DeepSeek
- Sin fallbacks explícitos
- Conclusión no alineada con el cuerpo del doc

### v3(1) (complemento)
- **Corrige contradicciones**: unifica DeepSeek como 🥇 en 6/7 áreas
- **Añade fallback chains**: cada disciplina tiene 🥈 con trigger condicional

### Gaps remanentes
- North Mini Code en risk table sin use case
- Sin tertiary fallback (si Flash Y MiMo caen)
- Sin health-check de disponibilidad de trial models
- Debugging, data analysis, documentación, DevOps, seguridad no cubiertos
- Benchmarks sin fuentes

## Workflow

### Context Gate
```
contexto > 200K → manejo DIRECTO (solo Big Pickle puede)
contexto ≤ 200K → evaluar routing
```

### Security Gate (SIEMPRE primero)
```
tarea con credenciales/datos sensibles? → manejo DIRECTO
tarea recurrente/cron? → manejo DIRECTO
```

### Routing Table (resumen)
- UI/UX, React, Frontend (<100K), E2E Testing, Performance, Syntax/Linting → DeepSeek Flash
- SEO, Content, Metadata → MiMo
- Architecture, Codebase Audit >150K, Code Review, Full Feature, Recurrentes → **Big Pickle directo**

### Fallback Chain Universal
DeepSeek V4 Flash (trial) → MiMo-V2.5 (trial) → Big Pickle (estable, fondo de cadena)

## Implementación
- [x] Skill `opencode-model-router` creado con el decision tree
- [x] Registro en SKILLS-INDEX.md
- [ ] Health-check de disponibilidad de trial models

---

# Corrections Patch — Ronda 2

> Correcciones factuales a research docs, verificadas por Ronda 1 de validación.

## Resumen (26 correcciones)

| Prioridad | Count |
|-----------|-------|
| **Critical** | 3 — Qwen3.5-35B no existe, VRAM formula incorrecta, KV cache GQA ~8× overstatement |
| **High** | 5 — LangGraph, CrewAI, AutoGen overhead, Spec decode caveat, ACON latency omitted |
| **Medium** | 6 — Get-Content, LLMLingua context, LightAgent deps, Hermes category, confidence tags, citations |
| **Low** | 2 — Star ratings footnote, Qwen3-14B verification ✅ |
| **New sections needed** | 10 — profiling, PS patterns, Bun guide, etc. |

## Correcciones Críticas

**C1. Qwen3.5-35B — model does not exist**
- File: `research/token-context.md` (antes `docs/research/optimization/token-context-optimization.md`)
- Qwen3 series no incluye 35B. Sizes reales: 0.5B, 1.7B, 4B, 8B, 14B, 32B, 110B, 235B.

**C2. VRAM formula — flat 1.2x multiplier incorrect**
- File: `research/ram-optimization.md` (antes `docs/research/optimization/ram-cpu-gpu-optimization.md`)
- Replaced by context-dependent formula. At 128K+, KV cache > weights para 70B.

**C3. KV Cache table for 70B ignores GQA — ~8x overstatement**
- File: `research/token-context.md`
- Modern 70B models (Llama 3, Qwen 2.5) usan GQA con 8 KV heads, no 64.

Para la lista completa de las 26 correcciones, ver `docs/archive/corrections-r2-patch.md`.

---

## Archivos referenciados en este documento

| Referencia | Ruta actual |
|---|---|
| Estándar de calidad | `docs/operations/quality-standard.md` |
| Bitácora del proyecto | `docs/decisions/bitacora.md` |
| Evidencia de scoring | `docs/metrics/` |
| Skill de ruteo de modelos | `.agents/skills/opencode-model-router/SKILL.md` |
