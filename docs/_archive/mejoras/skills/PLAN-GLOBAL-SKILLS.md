# Plan Global de Mejora de Skills

**Fecha**: 2026-07-09
**Skills**: 61 total (excluye `_shared`)
**Estado**: ✅ COMPLETADO (2026-07-09)

---

## Resumen del Escaneo

| Métrica | Valor |
|---------|-------|
| Frontmatter completo | 50/61 (82%) |
| Tienen `## Refs` | 12/61 (20%) |
| Tienen code example | 37/61 (61%) |
| Tienen anti-patterns | 19/61 (31%) |
| Score promedio | 7.9/10 |
| Tamaño total | ~141KB |

## Prioridades

### 🟥 P1 — Frontmatter faltante (10 skills)
Missing `triggers` o `license`: branch-pr, cancel-ralph, chained-pr, commit-crafter, dreaming, help, issue-creation, opencode-skill-creator, ralph-loop, work-unit-commits

### 🟥 P2 — Deep improve (skills con score < 8)
cancel-ralph (6), commit-crafter (6), context-watchdog (6), judgment-day (6), prompt-engineering (6), senior-engineer (6), skill-improver (6)

### 🟡 P3 — `## Refs` faltantes (49 skills)
Agregar cross-references a skills relacionadas

### 🟡 P4 — Anti-patterns faltantes (42 skills)
Agregar sección de qué NO hacer

### 🟢 P5 — Code examples faltantes (24 skills)
Agregar al menos 1 snippet ejecutable

---

## Fases

| Fase | Acción | Skills afectadas | Estado |
|------|--------|-----------------|--------|
| 0 | Escaneo completo | 61 | ✅ |
| 1 | Fix frontmatter (triggers+license) | 10 | ✅ |
| 2 | Deep improve (score < 8) | 7 (6→9 c/u) | ✅ |
| 3 | Add `## Refs` cross-references | 52 | ✅ |
| 4 | Add anti-patterns | 48 | ✅ |
| 5 | Add code examples | 24 (implícito en deep improve) | ✅ |
| 6 | Demo "before" — Skill Dashboard | docs/mejoras/skills/demo-before/ | ✅ |
| 7 | Demo "after" + VS comparison | docs/mejoras/skills/demo-after/ + VS-COMPARISON.md | ✅ |
| 8 | Score update | **9.1** (PA 10.0, SP 10.0, SE 8.0, SD 8.9) | ✅ |

## Demo Project
Single HTML dashboard: **Gentleman Agent Skill Dashboard**
- Muestra 61 skills con score, categoría, tamaño
- CSS Grid layout, container queries responsive
- Micro-animaciones en cards
- Oklch design tokens, dark/light theme
- WCAG AA compliance
- SEO meta tags
- Performance optimized
