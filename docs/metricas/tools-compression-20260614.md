# Tools + Compression — Batch 2

> **Date**: 2026-06-14
> **Scope**: Tool scripts + skill compression
> **Objective**: Setup rg/sg/gh toolchain, benchmark, compress skills ≥5%

## Before

| Métrica | Valor |
|---------|-------|
| ensure-tools.ps1 | Does not exist |
| token-count.ps1 | Does not exist |
| bench-file-io.ps1 | Does not exist |
| rg benchmark data | None |
| File I/O benchmark data | None |
| development-mode tokens | 1421 |
| accessibility tokens | 1008 |

## After

| Métrica | Valor | Δ |
|---------|-------|---|
| ensure-tools.ps1 | Created — 3/3 tools verified ✅ | 🆕 |
| token-count.ps1 | Created — ~4 chars/token heuristic ✅ | 🆕 |
| bench-file-io.ps1 | Created — 3 methods × N runs ✅ | 🆕 |
| rg avg search time | 157ms (literal 169, regex 141, ctx 162) | 📊 Baseline |
| I/O: Get-Content | 40ms | 📊 Baseline |
| I/O: ReadAllText | 9ms | 📊 Baseline |
| I/O: StreamReader | 5.9ms | 📊 Baseline |
| development-mode tokens | 976 (−445, −31.3%) | ✅ ≥5% target met |
| accessibility tokens | 892 (−116, −11.5%) | ✅ ≥5% target met |

## Verificación

| Check | Status |
|-------|--------|
| ensure-tools.ps1 syntax | ✅ 3/3 parse passes |
| ensure-tools.ps1 execution | ✅ rg/sg/gh all OK |
| token-count.ps1 execution | ✅ counts match manual calc |
| bench-file-io.ps1 execution | ✅ all 3 methods measurable |
| dev-mode integrity | ✅ all 5 ENTER steps, EXIT, VERIFY intact |
| a11y integrity | ✅ all WCAG criteria preserved |

## Lecciones

1. **rg v15.1.0 con PCRE2+AVX2**: aprovechar `-P` para regex, es igual de rápido que literal.
2. **StreamReader**: 6.7× más rápido que Get-Content en archivos <10KB. Para scripts frecuentes, usar .NET directo.
3. **Compresión skills**: tablas largas y comentarios redundantes son los mayores contribuyentes de tokens. Priorizar esos.
