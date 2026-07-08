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
├── backlog/           # Patrones pendientes de clasificar
└── PLAN.md            # Diseño completo del sistema
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
4. **Engram personal**: búsqueda rápida cross-sesión
5. **Pattern Guard** (Fase 2): detección automática desde cambios en código

## Cómo contribuir un patrón nuevo

1. Creá `docs/cross-project/backlog/<nombre>.json` con el formato de pattern
2. En la próxima session review, se clasifica y migra a `patterns/`
3. Si el patrón se repite 3+ veces → considerar forjar skill

## Fases

| Fase | Estado | Qué incluye |
|------|--------|-------------|
| F1 · HOY | ✅ Implementada | Estructura, 3 patrones seed, skill, rung 0b, `!wisdom` |
| F2 · MAÑANA | 🔲 Pendiente | Scripts de store/load/guard, Pattern Guard automatizado |
| F3 · PASADO | 🔲 Pendiente | Auto-forja de skills, democión, dreaming integration |
