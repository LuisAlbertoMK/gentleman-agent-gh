# Agent Lanes — Risk Classification

## Concepto

Clasificar tareas de AI por nivel de autonomía requerida.

## Lane Definitions

### Lane GREEN — Free Autonomy

```
Tareas que AI puede hacer sin revisión:
- Refactoring (sin change de comportamiento)
- Test generation
- Documentación
- Bug fixes en files conocidos
- Type fixes
- Formatting
- Dependency updates menores
```

**Regla**: Si rompe → revertrend y re-run.

### Lane YELLOW — Propose First

```
Tareas que requieren propuesta antes de ejecutar:
- Nuevas funcionalidades
- Cambios de API
- Integraciones internas
- Schema changes
- Config changes
```

**Regla**: AI propone → human revisa → proceed/reject.

### Lane RED — Requires Approval

```
Tareas que requieren approval explícito:
- Security changes
- Breaking changes
- Datos sensibles
- Deployments a producción
- Rollbacks
- Changes en billing/payments
```

**Regla**: Approval por escrito antes de action.

---

## Lane Classification Guide

| Factor | GREEN | YELLOW | RED |
|--------|-------|--------|-----|
| Risk de data loss | None | Partial | Full |
| Rollback fácil | Yes | Partial | No |
| Impact en users | None | Limited | All |
| Reversible | Yes | Conditional | No |
| Security touch | No | Maybe | Yes |

## Workflow

```
1. AI receives task
        │
        ▼
2. Classify in lane
        │
   ┌────┼────┐
   ▼         ▼
GREEN    YELLOW/RED
   │         │
   ▼         ▼
EXECUTE   PROPOSE → APPROVE → EXECUTE
```

## Example Classifications

| Task | Lane | Porqué |
|------|------|--------|
| Fix typo in README | GREEN | Sin riesgo |
| Add new endpoint | YELLOW | Nueva API |
| Fix security vulnerability | RED | Security-critical |
| Rename function | GREEN | Refactor seguro |
| Migrate database schema | RED | Breaking change |
| Add logging | GREEN | Non-breaking |
| Change auth logic | RED | Security-related |
| Performance optimization | YELLOW | Puede introducir bugs |
