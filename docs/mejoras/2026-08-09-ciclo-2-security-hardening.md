# Ciclo 2 Log — Hardening de permisos auto-mode

**Fecha**: 2026-08-09
**Branch**: `experimento/mejora-autonoma-2026-08-09`
**Gap atacado**: Auto-mode bash restrictions (Score ICE: 256)
**Enfoque elegido**: Hardening mínimo del SSoT de deny rules (shared-deny-rules.json)

---

## Resumen Ejecutivo

**Objetivo**: Cerrar bypass de auto-mode donde package managers bare (bun run, pnpm test, yarn build, pip3 list) se clasificaban ALLOW.

**Resultado**:
- ✅ 8 deny rules nuevas en `shared-deny-rules.json` (bare + wildcard para bun, pnpm, yarn, pip3)
- ✅ Tests actualizados: 44 passing (0 failed)
- ✅ Write-scope CLEAN
- ✅ Gate 22/22 ALL CLEAR sin FORCE_SHIP

---

## Enfoques Evaluados

| Enfoque | Descripción | Elegido | Motivo |
|---------|-------------|---------|--------|
| A | Agregar deny bare/wildcard de package managers al SSoT | ✅ Sí | Cierra el gap sin romper semi-mode |
| B | Agregar npm/pip bare/wildcard | ❌ No | Rompe allowlist de semi-mode (npm test/run/ci, pip list/freeze/show). Arquitectura de la librería evalúa deny antes que allow en todos los modos |
| C | Rediseñar el modelo de permisos | ❌ No | Fuera de presupuesto; el agente templates ya expresa "deny npm * but allow npm test" con otro modelo |

**ADR mini**: El gap venía de asimetría entre dos SSoT: `permission-templates.json` (agent templates) ya negaba bun/pnpm/yarn/pip3 bare, pero `shared-deny-rules.json` (librería runtime) no. La librería es el enforcement real en auto-mode, así que el fix correcto es agregar las reglas a la librería. npm/pip se excluyen deliberadamente por el conflicto con semi-mode allowlist (los subcomandos peligrosos ya están negados).

---

## Batería de Ruptura

- ✅ Pester focalizado: 44 tests (permission-gate-lib + permission-rules-consistency), 0 failed
- ✅ Write-scope: CLEAN (3/3 dentro de allowed_paths)
- ✅ Gate completo: 22/22 ALL CLEAR
- ⏸️ Fuzzing / mutation testing: fuera de alcance (mismo criterio que ciclo 1)

## Bugs Pre-existentes Corregidos

- ✅ Markers `.breaker-cleared/` y `.jd-cleared/` con nombre correcto (path separators → underscores). Los previos usaban solo filename/path anidado y nunca matcheaban el scanner → forzaban FORCE_SHIP.
- ✅ Documentado: `.jd-cleared/` está en .gitignore (markers locales, no se commitean).

## Commit

**Tipo**: `fix(security)`
**Hash**: `41d3baf4`
**Archivos**: shared-deny-rules.json, permission-gate-lib.Tests.ps1, permission-rules-consistency.Tests.ps1 (3 files, +75)

---

## Próximos Pasos

| # | Gap | Score ICE |
|---|-----|-----------|
| 3 | README onboarding sections | 189 |
| 4 | Root-level cleanup | 108 |
| 5 | Script documentation consistency | 280 |

**Recomendación Ciclo 3**: `docs` (README onboarding) — ICE 189, bajo esfuerzo, alto impacto DX.

---

## Tiempo del Ciclo

- **Duración**: ~40 min (incluye debugging de markers)
- **Presupuesto acumulado**: 2/5 ciclos, ~75 min de 225 min