# Ciclo 1 — v2 (CI coverage root tests / tests/)

**Fecha**: 2026-08-09
**Branch**: `experimento/mejora-autonoma-v2-2026-08-10`
**Gap**: `tests/*.Tests.ps1` (v1 experiment) no se ejecuta en CI — solo `scripts/tests/*.Tests.ps1`
**ICE**: Impacto 7 × Confianza 8 × Esfuerzo 4 = **224**

---

## Resumen

**Objetivo**: Que los 99 tests del experimento v1 (root `tests/`) pasen en CI, no solo localmente.

**Resultado**:
- ✅ 3 enfoques evaluados (A/B/C) — ADR-025
- ✅ **Opción A elegida**: nuevo job paralelo `tests-v1`
- ✅ YAML validado con `pyyaml.safe_load`
- ✅ Tests v1 localmente: **99 passed, 0 failed, 1 skipped**
- ✅ Write-scope: `CLEAN` (solo quality-gate.yml)
- ✅ Gate local: 22/22 ALL CLEAR
- ✅ Coverage CI: 875 → **974 tests**

---

## Approaches (evaluados por gentleman-deep-sub-auto)

| Enfoque | Risk | Effort | Outcome |
|---------|------|--------|---------|
| A: job paralelo `tests-v1` | LOW | LOW | ✅ elegido |
| B: expandir glob `tests` existente | MEDIUM | LOW | descartado — shared cache/failure domain |
| C: mover `tests/` → `scripts/tests/` | HIGH | HIGH | descartado — out of scope |

## Mini-ADR

**Decisión**: A (job paralelo). **Por qué**: zero-touch al job estable de 875 tests + paralelo (sin latencia) + cache key independiente. B y C afectan failure domains / out of scope respectivamente. Ver `adr/ADR-025-ci-coverage-root-tests.md`.

## Breaker/QA

- **Test local v1** (`tests/*.Tests.ps1`): 99 passed / 0 failed / 1 skipped
- El 1 fail preexistente del baseline (`reports contract_valid=true`) está en `scripts/tests/` (E2E), NO en `tests/` → no afectado por el cambio, no compromete CI.
- **Mutation/adversarial**: n/a (YAML-only change, no behavioral code)
- **Fault/chaos**: n/a (CI config, no infra)

---

## Benchmark (§0 — Coverage)

| Métrica | Baseline | Post-ciclo | Delta |
|---------|----------|------------|-------|
| Tests en CI scope | 875 (scripts/tests/) | **974** (875 + 99 v1) | **+99 (11%)** |
| Tests v1 en CI | 0 | 99 | 0→99 (coverage CI completa) |
| Tests pass rate CI | baseline 874/875 | v1: 99/99 ; scripts/tests: 874/875 | +99 sin regresión |
| Workflow YAML | válido | válido (`pyyaml.safe_load` OK) | = |

**Verdict**: improvement — CI coverage de la experimentación v1 pasó de 0% a 100%.

## Commit

**Tipo**: `ci`
**Archivo**: `.github/workflows/quality-gate.yml` (+28 líneas)
**ADR**: `adr/ADR-025-ci-coverage-root-tests.md` (nuevo)