# Gentleman Agents â€” Capacidades

> QuÃ© maneja cada agente, cuÃ¡ndo usar cada uno.

## gentleman-vMK (primary)

**Modelo**: big-pickle
**Rol**: Senior Architect Mentor

Es el agente por defecto, el que estÃ¡s usando ahora mismo. Orquestador principal que:
- Decide quÃ© otros agentes invocar segÃºn la tarea
- Tiene la personalidad completa + skills + engram + protocolos
- Hace de todo: debug, arquitectura, review, commit, etc.

**Usalo para**: TODO â€” es el default. Solo derivÃ¡ a otro cuando necesitÃ©s un enfoque especÃ­fico.

---

## gentleman-deep (`deep`)

**Modelo**: opencode/nemotron-3-ultra-free
**Rol**: Deep Reasoning Specialist

**Brilla en**:
- AnÃ¡lisis profundo de cÃ³digo (dependencias ocultas, side effects)
- Debugging complejo (bugs intermitentes, race conditions, memory leaks)
- Refactors multi-file con impacto arquitectÃ³nico
- Trade-off analysis entre 3+ opciones
- Design docs y decisiones de arquitectura

**No usarlo para**:
- Edits rÃ¡pidos de 1 archivo
- Tareas repetitivas mecÃ¡nicas
- Commits o PRs simples

**CuÃ¡ndo delegar**: cuando el problema no es obvio, cuando precisÃ¡s pensar antes de codear.

---

## gentleman-codex (`codex`)

**Modelo**: opencode/deepseek-v4-flash-free
**Rol**: Code Generation Specialist

**Brilla en**:
- Escribir cÃ³digo nuevo (scripts, handlers, endpoints)
- Tool calling y APIs externas
- Scripts de PowerShell, Bash, Python
- Refactors mecÃ¡nicos (renombrar, extraer, mover)
- ImplementaciÃ³n rÃ¡pida de features bien especificadas

**No usarlo para**:
- Decisiones arquitectÃ³nicas
- Debugging que requiere entender el sistema completo
- Code review profundo

**CuÃ¡ndo delegar**: cuando ya sabÃ©s QUÃ‰ hacer y solo necesitÃ¡s que alguien lo escriba.

---

## gentleman-quick (`quick`)

**Modelo**: opencode/mimo-v2.5-free
**Rol**: Fast Executor

**Brilla en**:
- Edits localizados de 1-2 archivos
- Fixes rÃ¡pidos (typos, bugs chicos, ajustes de estilo)
- Tareas repetitivas (cambiar imports, renombrar variables)
- One-shot commands sin mucha explicaciÃ³n
- ExploraciÃ³n superficial del codebase

**No usarlo para**:
- Refactors que tocan 5+ archivos
- Decisiones de diseÃ±o
- InvestigaciÃ³n profunda

**CuÃ¡ndo delegar**: cuando es un "hacÃ© este cambio chico y listo".

---

## SDD Subagents

Son **10 subagentes ocultos** del pipeline SDD (`sdd-*`). No se usan directo â€” los orquesta `gentleman-vMK` o `sdd-orchestrator`. Cada uno ejecuta una fase especÃ­fica:

| Subagente | Fase |
|-----------|------|
| sdd-init | Bootstrap del proyecto |
| sdd-explore | InvestigaciÃ³n del codebase |
| sdd-propose | Crear propuesta de cambio |
| sdd-design | DiseÃ±o tÃ©cnico |
| sdd-spec | Especificaciones G/W/T |
| sdd-tasks | Breakdown en tareas |
| sdd-apply | ImplementaciÃ³n |
| sdd-verify | VerificaciÃ³n contra specs |
| sdd-archive | Archivo y rollback |
| sdd-onboard | Onboarding guiado del ciclo SDD |

---

## Routing automÃ¡tico via skill-graph.ps1

El script `scripts/skill-graph.ps1` ahora incluye **routing automÃ¡tico** basado en el `Effort` de cada skill:

- **`low`** â†’ `gentleman-quick`: tareas simples, localizadas, mecÃ¡nicas
- **`medium`** â†’ `gentleman-codex`: generaciÃ³n de cÃ³digo, implementaciÃ³n estÃ¡ndar
- **`high`** â†’ `gentleman-deep`: razonamiento complejo, arquitectura, anÃ¡lisis profundo

Si una tarea matchea skills de distintos niveles, se recomienda el agente del nivel **mÃ¡s alto** entre todas las skills matcheadas.

```powershell
# Recomendar agente para scripting
.\scripts\skill-graph.ps1 -Task "security audit" -RecommendAgent
> gentleman-deep

# Ver routing en output completo
.\scripts\skill-graph.ps1 -Task "commit changes"
# Muestra: Agent: gentleman-codex | Effort: medium

# Formato JSON incluye agent_recommendation
.\scripts\skill-graph.ps1 -Task "refactor" -Format Json
# { agent_recommendation: { agent: "...", effort: "...", reason: "..." }, skills: [...] }
```

## Resumen rÃ¡pido

| Tarea | Agente | Routing |
|-------|--------|---------|
| Debug complejo | `deep` | Effort high |
| DecisiÃ³n de arquitectura | `deep` | Effort high |
| Escribir cÃ³digo nuevo | `codex` | Effort medium |
| Feature bien especificada | `codex` | Effort medium |
| Fix chico / typo | `quick` | Effort low |
| Renombrar / refactor mecÃ¡nico | `quick` o `codex` | Effort low/medium |
| No sabÃ©s quÃ© hacer | `vMK` (default) | â€” |
| SDD pipeline | `vMK` orquesta subagentes | Effort medium |
