# Proposal: Hook pre-commit sin bash — shebang absoluto a sh.exe existente

**Problem**: `.githooks/pre-commit:1` declara `#!/bin/sh`, pero el host no tiene
`C:\Program Files\Git\usr\bin\sh.exe` (verificado: `Test-Path` → `False`).
Git-for-Windows resuelve `/bin/sh` contra `usr/bin` (montaje MSYS) → el spawn del
intérprete falla → `git commit` aborta el hook → obliga a `--no-verify`
(quality gate de 21+ checks salteado). `git config core.hooksPath` = `.githooks`
(`.git/config`, verificado por `git config --list --show-origin`).

## Diagnóstico (evidencia con file:line + confidence)

### 1. Qué invoca el hook y cómo propaga exit code — confidence: HIGH
- `.githooks/pre-commit:23` → `exec "$GATE_BIN" --hook` (fast path, Go gate
  `bin/gate.exe` — existe en disco, verificado `True`).
- `.githooks/pre-commit:27-42` → si hay toolchain Go + `cmd/gate/main.go`
  (existe, verificado `True`), compila y `exec "$BUILD_OUT" --hook` (`:40`).
- `.githooks/pre-commit:46-50` → fallback `exec pwsh ... -File
  "$REPO_ROOT/.githooks/pre-commit-gate.ps1"` (`:47`); si no hay pwsh,
  `echo ERROR` + `exit 1` (`:49-50`).
- Las 3 rutas usan `exec` (reemplazo de proceso) → el exit code del gate ES el
  exit code del hook. Git no pasa args a `pre-commit` (ninguna línea del hook
  consume `$1`/`$@`) y bloquea el commit con exit ≠ 0. Conclusión: el cuerpo del
  hook está sano; el único punto de falla es la línea 1 (spawn del intérprete).

### 2. Mapa de intérpretes del host — confidence: HIGH (existencia), MEDIUM (spawn)
| Ruta | Existe | Nota |
|------|--------|------|
| `C:\Program Files\Git\usr\bin\sh.exe` (`/bin/sh`) | `False` | causa raíz |
| `C:\Program Files\Git\usr\bin\bash.exe` | `False` | tampoco existe |
| `C:\Program Files\Git\usr\bin\dash.exe` | `True` | detalle de install, no usar (frágil) |
| `C:\Program Files\Git\bin\sh.exe` | `True` | launcher Git-for-Windows 2.55.0.windows.3 |
| `C:\Program Files\Git\bin\bash.exe` | `True` | ídem |
| `C:\Program Files\PowerShell\7\pwsh.exe` | `False` | el ejemplo clásico NO aplica aquí |
| Store `...\Microsoft.PowerShell_7.6.5.0_x64__8wekyb3d8bbwe\pwsh.exe` | `True` | versionado (cambia con cada update) |
| `C:\Users\MK\AppData\Local\Microsoft\WindowsApps\pwsh.exe` (alias) | `True` | user-scoped, reparse point |
| `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe` | `True` | PS 5.1 — DESCARTADO (ver §3) |

### 3. Gate PS7-only — confidence: HIGH (skill ps-compat, regla 1)
- `.githooks/pre-commit-gate.ps1:2` → `#requires -Version 7`.
- `.githooks/pre-commit-gate.ps1:11` → operador `??` (sintaxis PS7-only).
- Per ps-compat: script con `#requires -Version 7` + `??` NO corre en PS 5.1 →
  shebang a `powershell.exe` (5.1) queda excluido. El gate además exige pwsh en
  su propio fallback (`.githooks/pre-commit:46`), consistente con PS7-only.

### 4. `#!/usr/bin/env` — confidence: HIGH (no viable)
`usr/bin` existe como dir pero sin `sh`/`bash`/`env`-target útil para este hook;
`env` resolvería contra un `PATH` MSYS incompleto en esta install recortada.
Descartado.

## Shebang propuesto (cambio de 1 línea, fase Apply)

```sh
#!C:/Program Files/Git/bin/sh.exe
```

Resto del cuerpo del hook SIN cambios (sintaxis `sh` intacta: `$(...)`, `case`,
`exec` — todo válido para este `sh.exe`).

**Por qué este y no los otros:**
- `bin/sh.exe` existe hoy, es parte estable de toda install Git-for-Windows
  (no user-scoped, no versionado en la ruta) y mantiene el cuerpo `sh` + la
  cadena `exec` (propagación de exit code ya probada por diseño).
- Vía pwsh (`#!.../pwsh.exe -File`) obligaría a REESCRIBIR todo el cuerpo a
  PowerShell (un `sh`-body no parsea bajo pwsh) + el único pwsh disponible es
  Store (alias user-scoped `MK`, dir versionado `7.6.5.0`) → I/R peor. Evaluado
  y rechazado como ruta primaria.
- Riesgo conocido (confidence MEDIUM): paths con espacios en `#!`. Git parsea el
  shebang y hace spawn directo del intérprete; la forma absoluta Windows con
  slashes es la soportada, pero el espacio en `Program Files` debe validarse
  empíricamente. Fallback listo: forma corta 8.3
  `#!C:/PROGRA~1/Git/bin/sh.exe` (misma fase Apply, 1 línea).

## In Scope
1. Cambiar línea 1 de `.githooks/pre-commit` al shebang propuesto (fase Apply).
2. Si el test real falla por el espacio en la ruta, usar el fallback 8.3.
3. Nuevo hook-body (si se elige vía pwsh) debe cumplir ps-compat: `#requires`,
   sin `&&`/`||`, `Join-Path` con params nombrados, ASCII/UTF8.

## Out of Scope
- Cuerpo del hook más allá de la línea 1 (salvo rewrite si se opta pwsh).
- `.githooks/pre-commit-gate.ps1`, `bin/gate.exe`, `cmd/gate/` (sanos).
- Reinstalar/reparar Git-for-Windows a nivel máquina.
- CYCLE.md, BITACORA.md, `.project.json`, scripts (prohibido tocar).

## I/R (Impacto/Riesgo)
| Candidato | Impacto | Riesgo | I/R | Veredicto |
|-----------|---------|--------|-----|-----------|
| `#!C:/Program Files/Git/bin/sh.exe` | 3 (desbloquea gate en cada commit) | 1 (1 línea, mismo lenguaje) | 3.0 | PRIMARIO |
| Fallback `#!C:/PROGRA~1/Git/bin/sh.exe` | 3 | 1 | 3.0 | Contingencia |
| Rewrite vía pwsh Store | 3 | 3 (rewrite + ruta user-scoped) | 1.0 | Rechazado |
| `powershell.exe` 5.1 | 0 (gate PS7-only no corre) | — | 0 | Excluido |
| Reparar Git a nivel máquina | 3 | 3 (fuera del repo) | 1.0 | No proposto |

## Rollback Plan (1 archivo, <1 min)
`git checkout -- .githooks/pre-commit` + verificar con `git config core.hooksPath`.

## Success Criteria (Done)
- [ ] Un `git commit` REAL dispara el hook (sin `--no-verify`) y pasa cuando el
      gate está verde; bloquea (exit ≠ 0) cuando el gate falla.
- [ ] `git config core.hooksPath` sigue en `.githooks`.
- [ ] Ningún otro archivo modificado por el fix (solo `.githooks/pre-commit`).

## Fast Path vs Full SDD
**FAST PATH (SDD-Quick)** — 1 línea, 1 archivo, codebase conocido, sin
schema/auth/API/deps. Propose (este doc) → Apply → Verify.

---

**Change**: 2026-09-08-hook-pwsh-no-bash
**Location**: `docs/sdd/proposals/2026-09-08-hook-pwsh-no-bash.md`
- **Intent**: Desbloquear `git commit` sin `--no-verify` fijando el spawn del hook
- **Scope**: 1 línea (shebang) en Apply, 0 cambios en esta fase
- **Approach**: SDD-Quick; primario `bin/sh.exe` absoluto, fallback 8.3
- **Risk**: Low (I/R 3.0, rollback 1 archivo, verificación con commit real)
Ready for sdd-apply (SDD-Quick).

## Revision 2
Stub bin/ refutado empíricamente: forward a usr/bin recortado sin sh.exe.
Shebang actual `#!C:/Program Files/Git/usr/bin/dash.exe`, body-level exit 0 + gate 5/5 ALL CLEAR.
Spawn vía git pendiente de test: este commit corre el hook sin --no-verify.
Si git parte la ruta con espacio, fallback 8.3 `C:/PROGRA~1/Git/usr/bin/dash.exe`.
Evidencia definitiva = output del hook durante este commit.
