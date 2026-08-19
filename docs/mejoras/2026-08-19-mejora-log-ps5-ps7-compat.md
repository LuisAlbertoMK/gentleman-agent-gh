# Mejora Log — PS5.1/PS7 Dual Compatibility for gentleman-vmk

**Fecha**: 2026-08-19
**Rama**: `experimento/ps5-ps7-compat-gentleman-vmk-2026-08-19`
**ADR**: [ADR-039](adr/ADR-039-ps5-ps7-compat-gentleman-vmk.md)
**Estado**: ✅ Implementado + Tests verdes

## Resumen

El setup path de `gentleman-vMK` ahora funciona en **PowerShell 5.1** (nativo en
Windows, sin permisos de admin) **y** **PowerShell 7** (pwsh). Se eliminaron
 todas las características que requerían PS 7+ del path crítico.

## Cambios

### Scripts modificados (lowered `#requires -Version 7` → `5.1`)

| Archivo | Cambio |
|---|---|
| `scripts/lib/platform.ps1` | `#requires -Version 5.1` + shim polyfill `$IsLinux`/`$IsMacOS`/`$IsWindows` via `RuntimeInformation::IsOSPlatform()` con guardas `Test-Path Variable:\` |
| `scripts/lib/json-utils.ps1` | `#requires -Version 5.1` |
| `scripts/lib/template-detection.ps1` | `#requires -Version 5.1` |
| `scripts/setup-machine.ps1` | `#requires -Version 5.1`, `@args`→`$args` en template de shortcut, install de `.bat` desde `scripts/gentleman-vmk.bat` |
| `scripts/setup-install.ps1` | `#requires -Version 5.1` |
| `scripts/gentleman-init.ps1` | `#requires -Version 5.1`, `@args`→`$args` |
| `scripts/use-gentleman.ps1` | `#requires -Version 5.1` |
| `scripts/sync-vmk.ps1` | `#requires -Version 5.1` |
| `scripts/sync-all.ps1` | `#requires -Version 5.1` |

### Archivos nuevos

| Archivo | Propósito |
|---|---|
| `scripts/gentleman-vmk.bat` | CMD wrapper: `pwsh.exe` → `powershell.exe` → `opencode` fallback. Usage: `gentleman-vmk "task"` |
| `scripts/tests/ps5-compat.Tests.ps1` | 12 tests de compatibilidad PS5/7 |

### Tests modificados

| Archivo | Cambio |
|---|---|
| `scripts/tests/powershell-compat.Tests.ps1` | T2: permite `#requires -Version 5.1` en libs |

## Resultados de tests

### Nuevos tests (ps5-compat.Tests.ps1)
12/12 pass ✅

1. T1: platform.ps1 `#requires -Version 5.1`
2. T2: platform.ps1 contiene shim `$Is*`
3. T3: shim usa `if (-not (Test-Path Variable:\...))` guards
4. T4: dot-source en job limpio define `$Is*` + `Get-GlobalConfigDir` funciona
5. T5: 6 scripts críticos declaran `#requires -Version 5.1`
6. T6: 3 libs críticos declaran `#requires -Version 5.1`
7. T7: ningún `@args` en scripts críticos
8. T8: template de shortcut usa `$args`
9. T9: `gentleman-init.ps1` forwards `$args`
10. T10: `gentleman-vmk.bat` existe
11. T11: `.bat` tiene patrón `pwsh`+`powershell` fallback
12. T12: `setup-machine.ps1` instala shortcut desde `.bat`

### Tests afectados (suite completa de cambios)
```
Total: 53, Passed: 51, Failed: 2 (pre-existentes)
```
- `powershell-compat.Tests.ps1`: 3/3 ✅
- `sync-vmk.Tests.ps1`: 3/3 ✅
- `sync-vmk-full-agents.Tests.ps1`: 3/3 ✅
- `setup-machine.Tests.ps1`: 4/4 ✅
- `ps5-compat.Tests.ps1`: 12/12 ✅
- `json-utils.Tests.ps1`: all pass ✅
- `use-gentleman.Tests.ps1`: 18/20 ✅ (2 pre-existing template-map drift failures)

## Verificación de baseline (git stash)

Se confirmó que los 2 failures de `use-gentleman.Tests.ps1` son **pre-existentes**:
- Baseline (stash): 18 pass, 2 fail
- Post-change: 18 pass, 2 fail (same 2)
- 0 regresiones introducidos.

## Write-scope validation

```
[INFO] Validate-WriteScope: 10 clean files (our modifications)
[VIOLATION] 6 pre-existing files from prior sessions (NOT our work):
  - scripts/babyagi-loop.ps1, delegation-registry.ps1, monitor-subagent.ps1,
    post-delegation-check.ps1, docs/mejoras/mejora-log.md, rollback-map.md
```

## Notas de implementación

- `@args` → `$args`: `$args` funciona desde PS 2.0+. El operador `@args`
  (splatting) es PS 7.1+. En el template de shortcut, `$args` se pasa como
  argumento a `opencode --agent gentleman-vMK`.
- `$PSScriptRoot` en Pester 5: en file-scope puede ser `$null`. Usar
  `BeforeAll { $repoRoot = Split-Path $PSScriptRoot -Parent }` dentro de cada
  `Describe` block.
- El shim de platform.ps1 usa `[System.Runtime.InteropServices.RuntimeInformation]`
  que está disponible en .NET Framework 4.0+ (PS 5.1) y .NET 6+ (PS 7).

## Mejoras futuras (out of scope)

- Consolidar todos los `#requires -Version 5.1` con un helper central
- Considerar un instalador `.exe` wrapper para usuarios no técnicos
