# Engineering Practices Analysis — gentleman-agent-gh

**Fecha**: 2026-07-21
**Especialistas**: Architecture, Testing, CI/CD, Tech Debt, DX
**Total findings**: 67 → consolidados a **top 15 por riesgo**

---

## Resumen Ejecutivo

El proyecto tiene una **arquitectura madura (7.5/10)** con separación de concerns disciplinada, aislamiento de agentes excelente, y documentación arquitectónica sobresaliente. Sin embargo, tiene **deuda técnica significativa** en 3 áreas críticas:

1. **DRY violation masiva** — 29% de opencode.json es el mismo bloque de permisos copiado 22 veces
2. **Testing insuficiente** — 84% de scripts sin tests, sin integración, sin E2E
3. **Self-inflation** — Score 9.1 vs real 7.3, mejoras auto-declaradas sin verificación externa

---

## Tabla de Síntesis (Top 15)

| # | Finding | Consenso | Riesgo | Dim | Archivos | Recomendación |
|---|---------|----------|--------|-----|----------|---------------|
| 1 | **opencode.json: 29% duplicado** — El mismo bloque de permisos (~35 líneas) se copia en 22 agentes. Agregar un deny rule = 22 edits. Drift inevitable. | UNANIMOUS (Arch+Debt) | **CRITICAL** | Arch | `opencode.json` (2346 líneas, 681 son boilerplate) | Extract permission templates + generator script o `$ref` composition |
| 2 | **~10% test coverage** — 8 scripts con tests de 80+ totales. Scripts destructivos (backup, restore, close-session) sin tests. | MAJORITY (Test+Debt) | **CRITICAL** | Testing | `scripts/tests/` (11 files) vs `scripts/*.ps1` (80+) | TDD para nuevos scripts; priorizar scripts destructivos |
| 3 | **Self-inflated score** — .project.json dice 9.1, bias-adjusted es 7.3. Gap 1.95pt documentado pero el score principal sigue siendo el inflado. | MAJORITY (Debt+DX) | **HIGH** | Debt | `.project.json:5-6` | Mostrar bias_adjusted como score principal |
| 4 | **CONTRIBUTING.md hidden from GitHub** — Está en `docs/`, no en root. GitHub no lo detecta para PR/issue templates. | MAJORITY (DX+Docs) | **HIGH** | DX | `docs/CONTRIBUTING.md` (existe, no encontrado) | Copiar/symlink a root |
| 5 | **No breaking-change protocol** — 22 agents + 79 skills sin deprecation policy. Users de global config pueden romperse silenciosamente. | MAJORITY (DX+Arch) | **HIGH** | DX | `PROTOCOL.md`, `CONTRIBUTING.md` | Crear `docs/VERSIONING.md` con semver para skills |
| 6 | **Flat scripts/ directory (88 files)** — Sin subdirectorios por concern. `analyze-page.js`, `backup.ps1`, `run-tests.ps1` al mismo nivel. | UNANIMOUS (Arch+Debt) | **HIGH** | Arch | `scripts/` (88 entries) | Agrupar: `scripts/analysis/`, `scripts/quality/`, `scripts/session/`, `scripts/setup/` |
| 7 | **pssa-gate.ps1 unreadable** — 85 líneas comprimidas en single-line blocks. Machine-optimized, not human-optimized. | UNANIMOUS (Debt) | **HIGH** | Debt | `scripts/pssa-gate.ps1:12-85` | Reformat para mantenibilidad |
| 8 | **Dual pre-commit systems** — `.githooks/pre-commit` (261 líneas shell) + `.pre-commit-config.yaml` (57 líneas framework). Overlapping concerns. | MAJORITY (CI/CD+Arch) | **HIGH** | CI/CD | `.githooks/pre-commit` + `.pre-commit-config.yaml` | Consolidar en un solo sistema |
| 9 | **No ADR (Architecture Decision Records)** — Decisiones dispersas en PROTOCOL.md, AGENTS.md, skill changelogs, CYCLE.md. Sin template formal. | UNANIMOUS (Arch) | **MEDIUM** | Arch | `docs/` (no `adr/`) | Crear `docs/adr/` con template lightweight |
| 10 | **Scripts/lib underdeveloped** — Solo 4 módulos compartidos para 88+ scripts. Duplicación de boilerplate (error handling, JSON parsing). | MAJORITY (Arch+Debt) | **MEDIUM** | Arch | `scripts/lib/` (4 files) | Auditar top 20 scripts, extraer a 10-12 lib modules |
| 11 | **Score depth over-engineered** — 42 sub-dimensions con diminishing returns. SD score es 8.8/10 (el más bajo no-CA). | MAJORITY (Debt+Data) | **MEDIUM** | Debt | `scripts/lib/score-dims.ps1` (673 lines) | Auditar si las 42 son accionables; cortar a 25-30 |
| 12 | **Inconsistent code style** — score-auto.ps1 beautifully formatted vs pssa-gate.ps1 compressed garbage vs run-improvement-cycle.ps1 in between. | UNANIMOUS (Debt) | **MEDIUM** | Debt | `scripts/*.ps1` | Establecer estándares: no single-line multi-statement, max 100-char |
| 13 | **Cycle Activity stalled** — CA dimension at 1.0/10. Inter counter 3/30. Next cycle = TBD. Self-improvement cycle has stalled. | MAJORITY (Debt+Data) | **MEDIUM** | Debt | `.project.json:20`, `CYCLE.md:11` | Resumir o acknowledge maintenance mode |
| 14 | **CI tests Windows-only** — Pester tests solo en `windows-latest`. Sin cross-platform test validation. | UNANIMOUS (CI/CD) | **MEDIUM** | CI/CD | `quality-gate.yml:148-155` | Agregar Linux test job o containerizar |
| 15 | **No CI caching** — Sin `actions/cache` para pip, npm, pre-commit environments. Cada run reinstala todo. | UNANIMOUS (CI/CD) | **MEDIUM** | CI/CD | `quality-gate.yml` | Agregar `actions/cache` para `~/.cache/pre-commit` |

---

## Engineering Maturity by Dimension

| Dimension | Score | Assessment |
|-----------|-------|------------|
| **Architecture** | 7.5/10 | Advanced — DRY violation critical, but separation of concerns excellent |
| **Testing** | 2.0/5 (CMM) | Emerging — pockets of strong practice, 84% untested |
| **CI/CD** | 2.5/5 | Above average — multi-stage gate, but no caching, no cross-platform tests |
| **Tech Debt** | 6/10 | Managed but growing — 23 anti-patterns documented, but self-inflated scores |
| **DX** | 7.5/10 | High — comment-based help, clear QUICKSTART, but fragmented docs |
| **Security** | 8/10 | Strong — adversarial breaker, PSSA gate, permission tiers |
| **Documentation** | 7/10 | Good — ARCHITECTURE.md exemplary, but CONTRIBUTING hidden, no ADRs |
| **Self-Improvement** | 5/10 | Stalled — 27 cycles completed, but CA=1.0, next=TBD |

---

## Cross-Specialist Consensus

| Consenso | Findings | Descripción |
|----------|----------|-------------|
| **UNANIMOUS** | #1, #6, #7, #9, #12, #14, #15 | Todos los especialistas coinciden |
| **MAJORITY** | #2, #3, #4, #5, #8, #10, #11, #13 | ≥50% coinciden |
| **SPLIT** | — | Ningún finding es split |

---

## Matriz de Riesgo

```
                    ALTO IMPACTO
                         │
    ┌────────────────────┼────────────────────┐
    │ #1 DRY violation   │ #5 No versioning   │
    │ #2 10% coverage    │ #6 Flat scripts/   │
    │                    │ #7 Unreadable code │
    │   CRITICAL (fix    │   HIGH (fix en     │
    │   primero)         │   este ciclo)      │
    ├────────────────────┼────────────────────┤
    │ #3 Inflated score  │ #8 Dual pre-commit │
    │ #4 Hidden Contrib  │ #10 Thin lib/      │
    │                    │ #11 Over-engineered│
    │   HIGH (fix cuando │   MEDIUM (backlog) │
    │   haya tiempo)     │                    │
    └────────────────────┼────────────────────┘
                         │
                    BAJO IMPACTO
```

---

## Recomendaciones por Fase

### Fase 1: Arquitectura (esta semana)
1. **#1** — Extract permission templates de opencode.json (DRY violation crítico)
2. **#6** — Reorganizar scripts/ en subdirectorios
3. **#7** — Reformat pssa-gate.ps1

### Fase 2: Testing (próximo ciclo)
4. **#2** — TDD para scripts destructivos (backup, restore, close-session)
5. **#14** — Agregar Linux test job en CI

### Fase 3: DX (ciclos 28-30)
6. **#4** — Mover CONTRIBUTING.md a root
7. **#5** — Crear docs/VERSIONING.md
8. **#9** — Crear docs/adr/

### Fase 4: Optimization (ciclos 30+)
9. **#11** — Audit score depth (42 → 25-30 sub-dims)
10. **#12** — Code formatting standards
11. **#15** — CI caching

---

## Bright Spots (lo que está bien)

| Area | What | Evidence |
|------|------|----------|
| **Architecture docs** | `docs/ARCHITECTURE.md` has component maps, ASCII diagrams, data flows — rare and exemplary | `docs/ARCHITECTURE.md:1-301` |
| **Agent isolation** | Read-only agents literally cannot write files. Builder ≠ Evaluator enforced at permission level | `opencode.json:671-727` |
| **Skill system** | 79 skills with frontmatter deps, trigger resolution, `_shared/` convention — clean extensibility | `.agents/skills/_shared/SKILL.md` |
| **Anti-pattern catalog** | 23 well-documented patterns with root cause, fix, prevention — genuine institutional memory | `ANTI-PATTERN-CATALOG.md:1-53` |
| **Script help** | Comment-based help (.SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE) on key scripts | `close-session.ps1:2-25` |
| **Security posture** | PSSA gate, secrets scan, permission tiers, adversarial breaker — above average for this project type | `.pre-commit-config.yaml`, `opencode.json` |

---

## Overall Assessment

**7.0/10 — Mature infrastructure, emerging engineering practices.**

This project has **senior-level architectural thinking** that's rare in AI agent configurations. The separation of concerns, permission model, and documentation are genuinely impressive. The self-improvement cycle (27 cycles) has produced real value: 23 anti-patterns, cross-platform scripts, consistent conventions.

The critical gap is the **DRY violation in opencode.json** — 29% of a 2346-line file is identical boilerplate. This is the architectural equivalent of a god object, not in logic but in configuration. The fix is straightforward: extract permission templates.

The secondary gap is **testing** — 84% of scripts have zero tests, and the ones that exist show strong practice (boundary analysis, security-conscious fixtures). The project would benefit more from running its own improvement cycle than from building more infrastructure to run it.

**The self-inflated score (9.1 vs 7.3) is the most insidious issue** — it's documented but still presented as primary. A project that values honesty should show its real score, not its aspirational one.

---

*Generado por analysis-mode v4.4 — 5 especialistas, 8 dimensiones, 67 findings → 15 consolidados*
