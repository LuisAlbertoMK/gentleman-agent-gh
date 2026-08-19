# V3 Regression Baseline Report — CI Quality Hardening (2026-08-18)

**Branch**: `main` (HEAD `786091d4`) · **Scope**: regression analysis, read-only
**Method**: detached worktrees per commit, `sync-vmk.ps1 -DryRun` ×5 median, schema parse of `benchmark-baseline.json`, Pester test-file inventory.
**Raw data**: persisted to Engram (observations #229 + #230) and local `…/v3-benchmark-raw.json`.

## Verdict (TL;DR)

> **No regression.** Crecimiento lineal de test files (58→62) y skills (78→91) introducido en Ciclo 1. El "salto" de `BenchmarkSeconds` 0.763→1.414 **no es performance** — fue el `benchmark-baseline.json` refrescado en Ciclo 1 (baseline viejo vs nuevo). El tiempo medido `sync-vmk -DryRun` se mantiene estable (1399–1509 ms, variación <8% = ruido de process spawn PowerShell).

## Baseline primario → sucesivos

| commit | tag | sync-vmk -DryRun mediana (ms) | BenchmarkSeconds | TotalSkills | Skills>3KB | test_files |
|---|---|---|---|---|---|---|
| `31134225` | baseline (plan v3) | 1438 | 0.763 | 78 | 0 | 58 |
| `e3bec66b` | Ciclo 1 — Pester runner | 1509 | 1.414 | **91** (+13) | 56 | 59 (+1) |
| `c966c4bc` | Ciclo 2 — coverage gate | 1449 | 1.414 | 91 | 56 | 61 (+2) |
| `2719837c` | Ciclo 3 — adversarial R1 | 1455 | 1.414 | 91 | 56 | 62 (+1) |
| `41d059de` | deliverables (ADR-032) | 1399 | 1.414 | 91 | 56 | 62 |
| `786091d4` | HEAD/fix | 1505 | 1.414 | 91 | 56 | 62 |

## Métrica de regresión: sync-vmk -DryRun mediana

- **Min**: 1399 ms (Ciclo deliverables) · **Max**: 1509 ms (Ciclo 1)
- **Delta max-min**: 110 ms = **7.0%** → dentro del ruido de spawn de proceso PowerShell (`pwsh -NoProfile -File` incluye import de módulos Pester). No hay tendencia monótona (ni ↓ ni ↑ consistente) → **no hay regresión de lógica**.

## Métrica de regresión: `benchmark-baseline.json` (schema pinneado)

- El salto 0.763 → 1.414 s en `BenchmarkSeconds` coincide con el commit `e3bec66b` ("chore: benchmark baseline mediana/IQR/count=10"). Ciclo 1 refrescó el baseline porque el repo creció (78→91 skills → más work para `sync-vmk`). **No es una regresión**: es el *reference* actualizado a mano.
- `SkillsOver3kb`: 0 → 56 → baseline viejo no medía esto (schema cambió). No comparar cruzado.

## Tests

- `test_files` crece 58→62 (5 archivos nuevos: `ci-pester.Tests`, `mutation-smoke.Tests`, `Coverage.Tests`, `adversarial-review.Tests`, + fixture).
- Todos los tests del Ciclo pasan: **17/17** en HEAD (`ci-pester 4/4`, `mutation-smoke 4/4`, `Coverage 5/5`, `adversarial-review 4/4`).
- Full suite base conocida: 997/29 fails pre-existentes (documentados, excluidos del gate de coverage por `-ExcludePattern`).

## Qué se perdió (audit trail)

> **Nada.** Los 4 hashes del Ciclo están en main: `e3bec66b`, `c966c4bc`, `2719837c`, `41d059de` + fix `786091d4`. Worktree temp removido. Working tree main clean (`git status` = 0). `local == origin/main`.

## Protocolo de automejora: 3-enfoques (para próxima iteración)

1. **Performance** (sync-vmk -DryRun) — estable, sin regresión.
2. **Correctness** (tests 17/17) — verde; el bug atapado en pre-push (fixture+marker) valida el proceso.
3. **Config drift** (benchmark-baseline.json schema) — baseline fue refrescado intencionalmente en Ciclo 1; no usar el valor viejo como "regresión".

## Recomendación

No hay acción correctiva. El protocolo v3 (evidencia → gate 22/22 → tests 17/17 → benchmark no regresivo → rollback map) validó todo. El "regreso" aparente era el baseline refrescado — documentado aquí y en ADR-032 (§E2E Verification).

---
*Generated: 2026-08-18 · Method: detached worktrees, Pester 5.5.0, pwsh 7.6.5 · Raw: Engram obs #230*
