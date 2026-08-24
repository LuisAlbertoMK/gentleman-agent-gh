# Análisis TDD/Testing — gentleman-agent-gh

**Fecha**: 2026-07-28
**Trigger**: `!analisis` con 4 subagentes especializados
**Especialistas**: Security, Infra/CI, Architecture, Testing
**Scope**: Cobertura de tests, gates de seguridad, enforcement de TDD, integración CI/CD

---

## Resumen Ejecutivo

El proyecto tiene **13 archivos de test** (166 `It` blocks, 239 assertions, ~16% cobertura por archivo). Pero **4 scripts críticos** — incluyendo los gates de seguridad para subagentes y el gate de auditoría de sesión — tienen **cero tests conductuales**. El pipeline SDD tiene arquitectura TDD estricta pero **nunca se activó en ningún proyecto real**.

---

## Tabla de Síntesis

| # | Finding | Consenso | Riesgo | Dim | Subagente | Recomendación |
|---|---------|----------|--------|-----|-----------|---------------|
| 1 | **`validate-write-scope.ps1` sin tests** — El regex de glob→pattern es artesanal y define el aislamiento de subagentes. Falso negativo = bypass de seguridad. | UNANIMOUS (Security+Testing) | **CRITICAL** | Security | Security | Tests conductuales para el regex matching con casos borde (paths anidados, chars especiales, overlapping) |
| 2 | **`close-session.ps1` audit gate sin tests** — `needsAudit` (L64-80) controla si protege archivos críticos. Sin tests = bypass de auditoría. | UNANIMOUS (Security+Testing) | **CRITICAL** | Security | Security | Tests para `needsAudit`, protected-files matching, session-miner integration |
| 3 | **`destructive-scripts.Tests.ps1` engañoso** — Solo verifica *presencia* de WhatIf/Force/DryRun/try-catch, no su *correctitud*. | UNANIMOUS (Testing+Security) | **CRITICAL** | Testing | Testing | Tests conductuales por script; el meta-test es complementario, no sustituto |
| 4 | **`strict_tdd: true` en 0 proyectos** — Pipeline SDD puede exigir TDD estricto (3 leyes, tabla de evidencia, 5 gates) pero nadie lo activó. | UNANIMOUS (Architecture+Testing) | **HIGH** | Architecture | Architecture | Activar en proyecto raíz: `sdd init --strict-tdd` |
| 5 | **Pre-commit hook no ejecuta tests** — TDD gate existe como skill pero `.githooks/pre-commit` tiene 0 test execution. | UNANIMOUS (Infra+Security) | **HIGH** | Infra | Infra | Agregar `Invoke-Pester` al hook entre steps [1] y [2] |
| 6 | **Cero `Mock` de Pester** — 13 archivos usan regex para extraer funciones del source. Frágil y comentado como limitación. | MAJORITY (Testing+Architecture) | **MEDIUM** | Testing | Testing | Migrar a `Mock` + `InModuleScope` en los scripts más críticos |
| 7 | **Cero `-CodeCoverage`** — Ni runner local ni CI producen reportes. Sin visibilidad de qué falta. | MAJORITY (Testing+Infra) | **MEDIUM** | Infra | Testing | Agregar `-CodeCoverage` a `run-tests.ps1` |
| 8 | **`restore.ps1` y `forge-rollback.ps1` destructivos sin tests** — `git checkout -- .` y `Remove-Item -Recurse -Force` sin cobertura conductual. | UNANIMOUS (Security+Testing) | **CRITICAL** | Security | Security | Tests de integración con temp repos y mock de filesystem |

---

## Delta vs Análisis Previo (2026-07-21)

El análisis de Julio 21 documentó el finding **#2 (~10% test coverage)** como CRITICAL. Mi verificación confirma y **agrega 3 hallazgos CRITICAL nuevos**:

| Estado | Finding previo | Mi verificación |
|--------|---------------|-----------------|
| ✅ Confirmado | #2: ~10% coverage | ~16% real, pero `destructive-scripts.Tests.ps1` infla la percepción |
| 🔴 Nuevo (A) | No mencionado | `validate-write-scope.ps1` — 0 tests, bypass de seguridad |
| 🔴 Nuevo (B) | No mencionado | `close-session.ps1` audit gate — 0 tests conductuales |
| 🔴 Nuevo (C) | No mencionado | `destructive-scripts.Tests.ps1` engañoso — solo verifica presencia |
| 🟡 Nuevo (D) | No mencionado | `strict_tdd: true` en 0 proyectos |
| 🟡 Nuevo (E) | No mencionado | Pre-commit no ejecuta tests |
| 🟢 Mejorado | #1 DRY (opencode.json) | Resuelto en esta sesión — permisos simplificados 21/22 agents |

---

## Recomendaciones Priorizadas

| # | Acción | Impacto | Dependencia |
|---|--------|---------|-------------|
| 1 | Tests para `validate-write-scope.ps1` (regex gate) | 🔴 Cierra bypass de seguridad | Ninguna |
| 2 | Tests para `close-session.ps1` (audit gate) | 🔴 Cierra bypass de auditoría | Ninguna |
| 3 | Tests conductuales para `restore.ps1` + `forge-rollback.ps1` | 🔴 Previene pérdida de datos | Ninguna |
| 4 | `strict_tdd: true` en proyecto raíz | 🟡 SDD exige TDD con evidencia | SDD init |
| 5 | `Invoke-Pester` en `.githooks/pre-commit` | 🟡 TDD automático local | Ninguna |
| 6 | `-CodeCoverage` en runner de tests | 🟡 Visibilidad de gaps | Ninguna |
| 7 | Migrar a `Mock`/`InModuleScope` en tests críticos | 🟢 Tests más mantenibles | Refactor de scripts |

---

## Matriz de Riesgo

```
CRITICAL ■■■■  (4 findings: validate-write-scope, close-session, destructive-ps1 engañoso, restore/forge-rollback)
HIGH     ■■     (2 findings: strict_tdd 0 proyectos, pre-commit sin tests)
MEDIUM   ■■     (2 findings: 0 Mock, 0 CodeCoverage)
```

---

## Engram Persistence

Engram MCP no disponible en este entorno. Findings documentados en `docs/mejoras/2026-07-28-tdd-testing-analysis.md`.

## Trend Analysis

Primer análisis focalizado en TDD/testing. Los análisis previos (Jul 13, 14, 18, 21, 24) cubrían ingeniería general. Este es el primer análisis multi-agente específico de testing con 4 subagentes especializados.

---

*Generado por análisis-mode con 4 subagentes: security, infra, architecture, testing*
