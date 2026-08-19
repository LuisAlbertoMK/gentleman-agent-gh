# Plan: PS5/PS7 Compatibilidad para gentleman-vmk — 2026-08-19

**Protocol**: `docs/protocolos/protocolo_mejora_autonoma_v3.md` §0-§2 · **Mode**: auto · **Fecha**: 2026-08-19
**Rama**: `experimento/ps5-ps7-compat-gentleman-vmk-2026-08-19` · **Base**: `2f961acf`
**Investigación**: `docs/mejoras/2026-08-19-ps5-ps7-compat-gentleman-vmk-investigacion.md`

## 0. Gap

`**requires -Version 7` en 90+ scripts + `@args` (PS7.1+) en shortcuts + `$IsLinux/$IsMacOS` (PS7+) en platform.ps1 impide ejecutar `gentleman-vmk` y setup scripts en Windows PowerShell 5.1 (default en Windows).** El `.cmd` shortcut funciona, pero el `.ps1` no, y los setup scripts ni siquiera cargan.

## Scope Lock

```
IN:  scripts/lib/platform.ps1         — PS5 compat shim $Is* + #requires 5.1
     scripts/lib/json-utils.ps1        — #requires 5.1 (PSSerializer funciona en PS3+)
     scripts/lib/template-detection.ps1 — #requires 5.1 (no PS7 features)
     scripts/setup-machine.ps1         — #requires 5.1, @args→$args, $Is* fix
     scripts/setup-install.ps1         — #requires 5.1
     scripts/gentleman-init.ps1        — #requires 5.1, @args→$args
     scripts/use-gentleman.ps1         — #requires 5.1
     scripts/sync-vmk.ps1              — #requires 5.1, $Is* via platform shim
     scripts/sync-all.ps1              — $Is* fix line 39 (via platform shim)
     scripts/tests/powershell-equiv.Tests.ps1 — actualizar test 2 & 3 para permitir libs 5.1
     scripts/tests/ps5-compat.Tests.ps1       — NUEVO: valida shim, @args→$args, #requires
     scripts/gentleman-vmk.bat                — NUEVO: wrapper CMD auto-detect PS
OUT: todo lo demás (skills, opencode.json, otros scripts no-critical-path)
```

## 3 Enfoques

| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** (Shim PS5) | Compat-shim `$Is*` en platform.ps1; bajar `#requires`; `@args`→`$args` | Funciona en PS5 SIN PS7 | Update test de compat |
| **B** (Redirect-only) | Bajar `#requires`; redirect a pwsh; `@args`→`$args` | Patrón probado (sync-all) | Falla si PS7 no instalado (problema del usuario) |
| **C** (Dual-mode) | A: libs PS5-compat; B: entry-points redirect opcional; `.bat` wrapper | Máxima compat; siempre funciona | Más archivos |

**Ganador**: **C** — libs compatibles PS5 + redirect opcional en entry-points + `.bat` wrapper.

## DoD
- [ ] platform.ps1: `#requires -Version 5.1` + `$IsLinux`/`$IsMacOS`/`$IsWindows` shim funciona
- [ ] json-utils.ps1, template-detection.ps1: `#requires -Version 5.1`
- [ ] `@args` → `$args` en setup-machine.ps1:118 + gentleman-init.ps1:17
- [ ] Entry-points (`setup-machine`, `setup-install`, `gentleman-init`, `use-gentleman`, `sync-vmk`): `#requires -Version 5.1`
- [ ] sync-all.ps1:39 `$Is*` usa el shim
- [ ] `gentleman-vmk.bat` creado (wrapper CMD, auto-detect PS5/PS7)
- [ ] powershell-compat.Tests.ps1 actualizado (permite libs 5.1)
- [ ] ps5-compat.Tests.ps1 nuevo: 4/4 tests pass
- [ ] Pester: 0 NEW failures (baseline preservado)
- [ ] ADR-039 escrito
- [ ] mejora-log.md actualizado

## Baseline
- Pester: 683* pass / 0 fail (baseline del experimento anterior)
- Gate: 14/14
- Score: 9.3/10
- `#requires -Version 7` en 90+ scripts, `#requires -Version 5.1` en 6 scripts
