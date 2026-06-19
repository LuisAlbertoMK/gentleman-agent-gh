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

## Resumen rápido

| Tarea | Agente |
|-------|--------|
| Debug complejo | `deep` |
| Decisión de arquitectura | `deep` |
| Escribir código nuevo | `codex` |
| Feature bien especificada | `codex` |
| Fix chico / typo | `quick` |
| Renombrar / refactor mecánico | `quick` o `codex` |
| No sabés qué hacer | `vMK` (default) |
| SDD pipeline | `vMK` orquesta subagentes |
