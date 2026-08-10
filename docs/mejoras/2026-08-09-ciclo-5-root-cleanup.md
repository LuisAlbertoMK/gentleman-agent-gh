# Ciclo 5 Log — Root-level cleanup + .gitignore defensivo

**Fecha**: 2026-08-09
**Branch**: `experimento/mejora-autonoma-2026-08-09`
**Gap atacado**: Root-level clutter + .gitignore (Score ICE: 108)
**Enfoque elegido**: Eliminar basura trackeada/untracked + patrones defensivos anti-recurrencia

---

## Resumen Ejecutivo

**Objetivo**: Limpiar archivos sueltos que polucionan el root del proyecto (¿15+ archivos?) sin tocar archivos funcionales.

**Resultado** (verificado con git ls-files + check-ignore):
- ✅ **La polución real era menor de lo reportado**: de los candidatos del análisis, solo `$null` estaba TRACKEADO; los logs ya estaban ignorados por `*.log`
- ✅ `$null` (0 bytes, redirección `> $null` rota) eliminado del índice — **RECURRENTE** (ya removido en `639390d0`, había vuelto)
- ✅ Eliminados del disco: `_testrun.log`, `_toolout.log`, `_toolout2.log`, `coverage.xml`
- ✅ `.gitignore` +6 líneas: patrones anti-reincidencia (`$null`, `_toolout*.log`)
- ✅ Gate 22/22 ALL CLEAR

---

## Enfoques Evaluados

| Enfoque | Descripción | Elegido | Motivo |
|---------|-------------|---------|--------|
| A | `git rm` basura trackeada + borrar untracked + .gitignore defensivo | ✅ Sí | Cierra la recurrencia del `$null` y limpia disco |
| B | Mover a `tmp/` en vez de borrar | ❌ No | Logs de 0-1 KB sin valor; ya ignorados |
| C | Mover benchmarks.md/mejora-log.md/CYCLE.md a docs/ | ❌ No | Fuera de alcance: son del experimento previo (SSoT benchmark) y `benchmark-baseline.json` lo consume el gate [8/13] |

**ADR mini**: Verificación previa con `git ls-files` y `git check-ignore` reveló que el análisis inicial sobrestimó el clutter (los logs ya estaban en `.gitignore` línea 62 `*.log`). El único item CRITICAL real era el archivo `$null` trackeado. No mover archivos del experimento previo sin consulta — `benchmark-baseline.json` y `benchmarks.md` son consumidos por benchmark.ps1/bench-compare.ps1 y el gate.

---

## Batería de Ruptura

- ✅ `git status --short`: solo `D $null` + `M .gitignore` (write-scope implícito correcto)
- ✅ `Test-Path` en los 5 targets: todos `False` tras el cleanup
- ✅ Gate completo: 22/22 ALL CLEAR (sin FORCE_SHIP)
- ⏸️ Pester: no requerido (0 lógica tocada)
- ✅ `temp/` intencionalmente NO borrado (vacío, ya ignorado — decisión conservative)

## Bugs Pre-existentes / Insights

- 🔑 **Recurrencia**: `$null` fue removido en `639390d0` (cycle 22 era) y volvió — un archivo basura "zombie" sin patrón defensivo. El fix de hoy es anti-recurrencia, no solo limpieza.

## Commit

**Tipo**: `chore`
**Hash**: `a6c780bc`
**Archivos**: `$null` (deleted), `.gitignore` (+6)

---

## Estado Final del Protocolo

| Ciclo | Gap | Score ICE | Commit | Estado |
|-------|-----|-----------|--------|--------|
| 1 | Testing coverage | 486 | b7eb9bc6..98032486 | ✅ |
| 2 | Auto-mode bash restrictions | 256 | 41d3baf4 | ✅ |
| 3 | README onboarding | 189 | 6d2e1e8f | ✅ |
| 4 | Script documentation consistency | 280 | b7cc22c3 | ✅ |
| 5 | Root-level cleanup | 108 | a6c780bc | ✅ |

**Presupuesto**: 5/5 ciclos · Condición de parada alcanzada (presupuesto agotado).