# Cross-Project Wisdom System

> Patrones, decisiones, y lecciones que trascienden un solo proyecto.
> Sistema diseñado para que cada sesión no arranque de cero.

## Estructura

```
docs/cross-project/
├── README.md          # Esta guía
├── patterns/          # Patrones migrados (source of truth)
│   ├── ux-a11y-hero-btn-contrast.json
│   ├── ux-a11y-footer-span-color.json
│   └── css-rgb-black-vs-transparent.json
├── backlog/           # Patrones pendientes de clasificar (vacíos — migrados)
├── PLAN.md            # Diseño completo del sistema
└── scripts/           # F2+F3: store/loader/guard/forge/demote/stats
```

## ¿Qué es un patrón?

Un **patrón** es una lección técnica que se aprendió en un proyecto y que podría ser relevante en otro. No es código reusable — es **conocimiento reusable**.

Cada patrón en `patterns/` tiene:

| Campo | Qué es |
|-------|--------|
| `id` | `dominio/subdominio/nombre-corto` |
| `domain` | `ux`, `css`, `ps`, `security`, `performance` |
| `severity` | `CRITICAL`, `HIGH`, `MEDIUM`, `LOW` |
| `confidence` | Cuán seguro estamos del patrón (0.0 - 1.0) |
| `context` | Dónde y cuándo se descubrió |
| `signal` | Cómo detectar que este patrón aplica |
| `rule` | La lección en sí |
| `evidence` | URLs, archivos, commits que lo respaldan |
| `hits` | Cuántas veces se encontró (para `LOW` → forja automática) |

## Ciclo de vida del patrón

```
→ seed (manual) → active (consultable) → confirmed (3+ proyectos) → forged (skill auto-generada)
```

- **Seed**: patron añadido manualmente
- **Active**: consultado por `cross-project-wisdom` skill
- **Confirmed**: visto en ≥3 contextos distintos → prioridad alta
- **Forged**: maduro para convertirse en skill OpenCode o regla en AGENTS.md

## Integración con el sistema

1. **Rung 0b** en Pre-Flight Gate: cross-check cruzado entre factibilidad y YAGNI
2. **`!wisdom`**: shortcut para cargar patrones relevantes al contexto
3. **session-resume**: carga patrones de alta prioridad al inicio de sesión
4. **Engram scope:personal**: búsqueda rápida cross-sesión + guardado automático
5. **Pattern Guard** (F2): detección LAZY desde cambios en código (`pattern-guard.ps1`)
6. **Wisdom Store** (F2): migración y validación de patrones (`wisdom-store.ps1`)
7. **Wisdom Stats** (F2): métricas de uso y distribución (`wisdom-stats.ps1`)
8. **Wisdom Forge** (F3): auto-forja de skills al superar thresholds (`wisdom-forge.ps1`)
9. **Wisdom Demote** (F3): ciclo de vida — demotion/remove/archive (`wisdom-demote.ps1`)
10. **!analisis** (F2): inyección de wisdom en análisis multi-agente

## Cómo contribuir un patrón nuevo

1. Creá `docs/cross-project/backlog/<nombre>.json` con el formato de pattern
2. Migralo con: `scripts/wisdom-store.ps1 -MigrateBacklog`
3. Auto-detectá en código existente con: `scripts/pattern-guard.ps1 -Mode BATCH`
4. Si el patrón acumula hits → se forja solo vía `wisdom-forge.ps1`

## Fases

| Fase | Estado | Qué incluye |
|------|--------|-------------|
| F1 · HOY | ✅ Implementada | Estructura, 3 patrones seed, skill, rung 0b, `!wisdom` |
| F2 · MAÑANA | ✅ Implementada | Store/loader/guard/stats + Pattern Guard + immune-system scope:personal + `!analisis` wisdom injection |
| F3 · PASADO | ✅ Implementada | Forge pipeline (9 quality gates), demote/remove/archive, dreaming integration, rollback |
