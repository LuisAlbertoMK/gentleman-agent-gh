# Mejora Autónoma v2 — Baseline

**Fecha**: 2026-08-10 05:26
**Branch**: xperimento/mejora-autonoma-v2-2026-08-10
**Base**: main (7b0f6a8a)

## Métricas (§0 spec)

| Métrica | Baseline v2 | Umbral | Status |
|---------|-------------|--------|--------|
| E2E suite pass/fail | **874 pass / 1 fail** (875 total, 44 files) | 100% pass | ⚠️ 1 bug preexistente |
| Bundle opencode.json | **72,983 B** | ≤ 98,304 (ADR-007) | OK |
| Agentes configurados | 49 (16 sub) | — | — |
| Skills >3KB | **7** (sdd-*) | 0 | ❌ |
| E2E test files (CI scope) | 44 | — | — |

## Bugs preexistentes (§3.5: se corrigen antes de continuar)

1.reports contract_valid=true for well-formed output (E2E) — **NO corregido todavía**: es un contract-validation test inside scripts/tests/ que falla. Registrado para el cycle que integre tests/.

## Notas

- Baseline E2E actualizado: el análisis v1 (2026-08-02) registraba 669 pass/7 fail; la suite ha mejorado a 874/1 (7 fallas previas fueron corregidas entre tanto). Baseline vigente: 874 pass / 1 fail.
- El directorio `tests/` contiene 46 archivos `.Tests.ps1` (de la v1) que NO son ejecutados por CI (`scripts/tests/*.Tests.ps1` es el scope de calidad-gate.yml) → cobertura CI/reporting gap.
