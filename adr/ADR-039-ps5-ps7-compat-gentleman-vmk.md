# ADR-039: PS5.1/PS7 Dual Compatibility for gentleman-vmk

- **Date**: 2026-08-19
- **Status**: Accepted
- **Deciders**: gentler, architect
- **Tags**: compatibility, powershell, gentleman-vmk, ps5.1

## Context

The gentleman-vmk agent setup path must work on **Windows PowerShell 5.1** (native on
Windows, no admin required) **and** **PowerShell 7** (pwsh). Prior to this ADR, several
scripts in the setup path used PS7+ or PS7.1+ features:

- `@args` splatting operator (introduced in PS 7.1) — used in `setup-machine.ps1`
  and `gentleman-init.ps1`
- `#requires -Version 7` — declared on 9 scripts + 3 lib files
- `$IsLinux` / `$IsMacOS` / `$IsWindows` automatic variables (PS 6+ only) — assumed
  present in `platform.ps1` with no PS 5.1 fallback

On Windows where only PS 5.1 is available (common in enterprise environments), the
setup path fails immediately because the `#requires` guard rejects the script.

## Research Summary

Five web searches were conducted (see
`docs/mejoras/2026-08-19-ps5-ps7-compat-gentleman-vmk-investigacion.md`):

1. **PowerShell 5.1 vs 7.x feature differences** — confirmed `@args` is PS 7.1+,
   `$Is*` variables are PS 6+, `RuntimeInformation::IsOSPlatform()` works on both.
2. **Installing PowerShell 7** — `winget install Microsoft.PowerShell` is the
   recommended path, but must not be a hard requirement for enterprise users.
3. **Migrating from PS 5.1 to 7** — `$PSVersionTable.PSEdition` = `'Desktop'`
   reliably identifies Windows PowerShell 5.1.
4. **Running PS 5 and 7 in parallel** — both can coexist; `pwsh.exe` and
   `powershell.exe` can be called side-by-side.
5. **PS 5.1 `Set-StrictMode` and `$Is*`** — confirmed that `$Is*` variables are
   truly absent (null) under PS 5.1; `Test-Path Variable:\Is*` returns `$false`.

## Decision

**Lower the compatibility floor to PowerShell 5.1** for the gentleman-vmk setup
path. This is the lowest common denominator that works everywhere Windows ships.

### Concrete changes

| Category | Before | After |
|---|---|---|
| `#requires` version | `5.1` on some, `7` on others | **All `5.1`** |
| Argument forwarding | `@args` (PS 7.1+) in `setup-machine.ps1` + `gentleman-init.ps1` | **`$args`** (works PS 2.0+) |
| `$Is*` variables | Assumed present (PS 6+) | **Shim in `platform.ps1`** using `RuntimeInformation::IsOSPlatform()` + `PSEdition` guard |
| Entry-point wrapper | `opencode --agent gentleman-vMK` (requires PS 5.1+ to find it) | **New `gentleman-vmk.bat`** — CMD wrapper with 3-tier fallback: `pwsh.exe` → `powershell.exe` → `opencode` direct |

### The platform.ps1 shim

```powershell
if (-not (Test-Path Variable:\IsWindows)) {
    $IsWindows = $PSVersionTable.PSEdition -eq 'Desktop' -or
                 [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
                     [System.Runtime.InteropServices.OSPlatform]::Windows)
}
# Same pattern for $IsLinux, $IsMacOS
```

The `Test-Path Variable:\Is*` guard ensures we do NOT clobber the real PS 7 automatic
variables when running on PS 7+ — the shim is a no-op there.

### The gentleman-vmk.bat wrapper

```
where pwsh.exe  →  if found:  pwsh.exe … "opencode --agent gentleman-vMK %*"
where powershell.exe  →  fallback:  powershell.exe … "opencode --agent gentleman-vMK %*"
where opencode  →  last resort:  opencode --agent gentleman-vMK %*
```

This lets users invoke `gentleman-vmk "task"` from CMD (which is always available on
Windows) without thinking about which PowerShell version they have.

### Scope lock

Only these files were modified. The DoD checklist must all pass before commit:

1. ✅ `platform.ps1` shim — `#requires -Version 5.1` + `$Is*` polyfill with guards
2. ✅ `lib/json-utils.ps1` — `#requires -Version 5.1`
3. ✅ `lib/template-detection.ps1` — `#requires -Version 5.1`
4. ✅ Entry-point scripts — `#requires -Version 5.1`
5. ✅ `@args` → `$args` in `setup-machine.ps1` + `gentleman-init.ps1`
6. ✅ `gentleman-vmk.bat` created with auto-detect pattern
7. ✅ Tests updated/created — 0 new failures (2 pre-existing failures confirmed via `git stash` baseline)

## Consequences

- **Positive**: The setup path works on bare Windows machines with only PS 5.1,
  no admin rights needed. Users with PS 7 still get full features via `pwsh.exe`
  auto-detection in the `.bat` wrapper.
- **Positive**: The `.bat` wrapper means CMD users can launch `gentleman-vMK
  "task"` without opening PowerShell at all.
- **Risk**: None — all changes are backward-compatible. PS 7 behavior is
  unchanged (shim guards are no-ops; `$args` works on all versions).
- **Risk**: The `.bat` wrapper uses `%*` for argument passing, which handles
  quotes imperfectly for very complex arguments. Acceptable for the
  agent-launch use case.

## Related ADRs

- ADR-033: Mode deprecation (auto fallback in switch-mode) — this ADR is
  orthogonal; the mode system works regardless of PS version.
- ADR-034: Cross-ref integrity — pre-existing analysis work; not affected.

## Test evidence

```
Affected tests: 53 total, 51 passed, 2 failed
Pre-existing failures: 2 (use-gentleman.Tests.ps1 — template-map drift JS↔PS)
0 new failures introduced by this change.
```
