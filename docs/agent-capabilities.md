# Gentleman Agents — Capacidades

> Qué maneja cada agente, cuándo usar cada uno.

## gentleman-vMK (primary)

**Modelo**: big-pickle  
**Rol**: Senior Architect Mentor

Es el agente por defecto, el que estás usando ahora mismo. Orquestador principal que:
- Decide qué otros agentes invocar según la tarea
- Tiene la personalidad completa + skills + engram + protocolos
- Hace de todo: debug, arquitectura, review, commit, etc.

**Usalo para**: TODO — es el default. Solo derivá a otro cuando necesités un enfoque específico.

---

## gentleman-deep (`deep`)

**Modelo**: opencode/nemotron-3-ultra-free  
**Rol**: Deep Reasoning Specialist

**Brilla en**:
- Análisis profundo de código (dependencias ocultas, side effects)
- Debugging complejo (bugs intermitentes, race conditions, memory leaks)
- Refactors multi-file con impacto arquitectónico
- Trade-off analysis entre 3+ opciones
- Design docs y decisiones de arquitectura

**No usarlo para**:
- Edits rápidos de 1 archivo
- Tareas repetitivas mecánicas
- Commits o PRs simples

**Cuándo delegar**: cuando el problema no es obvio, cuando precisás pensar antes de codear.

---

## gentleman-codex (`codex`)

**Modelo**: opencode/deepseek-v4-flash-free  
**Rol**: Code Generation Specialist

**Brilla en**:
- Escribir código nuevo (scripts, handlers, endpoints)
- Tool calling y APIs externas
- Scripts de PowerShell, Bash, Python
- Refactors mecánicos (renombrar, extraer, mover)
- Implementación rápida de features bien especificadas

**No usarlo para**:
- Decisiones arquitectónicas
- Debugging que requiere entender el sistema completo
- Code review profundo

**Cuándo delegar**: cuando ya sabés QUÉ hacer y solo necesitás que alguien lo escriba.

---

## gentleman-quick (`quick`)

**Modelo**: opencode/mimo-v2.5-free  
**Rol**: Fast Executor

**Brilla en**:
- Edits localizados de 1-2 archivos
- Fixes rápidos (typos, bugs chicos, ajustes de estilo)
- Tareas repetitivas (cambiar imports, renombrar variables)
- One-shot commands sin mucha explicación
- Exploración superficial del codebase

**No usarlo para**:
- Refactors que tocan 5+ archivos
- Decisiones de diseño
- Investigación profunda

**Cuándo delegar**: cuando es un "hacé este cambio chico y listo".

---

## SDD Subagents

Son **10 subagentes ocultos** del pipeline SDD (`sdd-*`). No se usan directo — los orquesta `gentleman-vMK` o `sdd-orchestrator`. Cada uno ejecuta una fase específica:

| Subagente | Fase |
|-----------|------|
| sdd-init | Bootstrap del proyecto |
| sdd-explore | Investigación del codebase |
| sdd-propose | Crear propuesta de cambio |
| sdd-design | Diseño técnico |
| sdd-spec | Especificaciones G/W/T |
| sdd-tasks | Breakdown en tareas |
| sdd-apply | Implementación |
| sdd-verify | Verificación contra specs |
| sdd-archive | Archivo y rollback |
| sdd-onboard | Onboarding guiado del ciclo SDD |

---

## Routing automático via skill-graph.ps1

El script `scripts/skill-graph.ps1` ahora incluye **routing automático** basado en el `Effort` de cada skill:

- **`low`** → `gentleman-quick`: tareas simples, localizadas, mecánicas
- **`medium`** → `gentleman-codex`: generación de código, implementación estándar
- **`high`** → `gentleman-deep`: razonamiento complejo, arquitectura, análisis profundo

Si una tarea matchea skills de distintos niveles, se recomienda el agente del nivel **más alto** entre todas las skills matcheadas.

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

## Resumen rápido

| Tarea | Agente | Routing |
|-------|--------|---------|
| Debug complejo | `deep` | Effort high |
| Decisión de arquitectura | `deep` | Effort high |
| Escribir código nuevo | `codex` | Effort medium |
| Feature bien especificada | `codex` | Effort medium |
| Fix chico / typo | `quick` | Effort low |
| Renombrar / refactor mecánico | `quick` o `codex` | Effort low/medium |
| No sabés qué hacer | `vMK` (default) | — |
| SDD pipeline | `vMK` orquesta subagentes | Effort medium |
