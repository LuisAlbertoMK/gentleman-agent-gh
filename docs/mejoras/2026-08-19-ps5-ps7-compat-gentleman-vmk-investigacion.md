# Investigación: Compatibilidad PowerShell 5.1 ↔ 7 para gentleman-vmk

> **Protocol**: `docs/protocolos/protocolo_mejora_autonoma_v3.md` §0 · **Mode**: auto · **Fecha**: 2026-08-19
> **Web searches**: 5+ (Microsoft Learn, StackOverflow, GitHub, PS Docs) · confidence: high

## 1. Problema

Windows nativo incluye **PowerShell 5.1** (`powershell.exe`). **PowerShell 7** (`pwsh.exe`) es opcional — se instala side-by-side pero NO reemplaza a PS5.1. Los scripts de `gentleman-agent-gh` usan `#requires -Version 7` y features exclusivas de PS7, impidiendo ejecución nativa en PS5.1.

## 2. Web Research Findings (5 searches)

### Search 1: "PowerShell 5 vs PowerShell 7 compatibility differences breaking changes Windows"
**Fuente**: [Microsoft Learn — Differences from Windows PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/whats-new/differences-from-windows-powershell)
**Hallazgos clave**:
- PS 5.1 = .NET Framework 4.x · PS 7 = .NET Core/.NET 5+ (cross-platform)
- `$IsLinux`, `$IsMacOS`, `$IsWindows` → **introducidos en PS 6.0**, NO existen en PS 5.1
- `@args` splatting → **introducido en PS 7.1**, NO en PS 5.1
- `??` (null-coalescing) y `??=` → **PS 7+**, NO en PS 5.1
- `&&` / `||` operadores lógicos en pipeline → **PS 7+**, NO en PS 5.1
- Cmdlets removidos: `Get-WmiObject`, `Invoke-WmiMethod`, `Export-Counter`, etc.
- `Set-StrictMode -Version Latest` funciona en PS5.1 pero = `-Version 2.0` (diferente de PS7)

### Search 2: "Install PowerShell 7 on Windows side-by-side"
**Fuente**: [Microsoft Learn — Install PowerShell 7 on Windows](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)
**Hallazgos clave**:
- PS 7 instala a `$Env:ProgramFiles\PowerShell\7` — **NO reemplaza** PS 5.1
- `$env:PATH` incluye la carpeta de PS 7, pero `powershell.exe` sigue apuntando a PS 5.1
- `pwsh.exe` es el ejecutable de PS 7; `powershell.exe` es PS 5.1
- **Conflicto común**: scripts con `#requires -Version 7` fallan silenciosamente en PS 5.1 con "script requiere PowerShell 7.0 o posterior"

### Search 3: "Migrating from Windows PowerShell 5.1 to PowerShell 7"
**Fuente**: [Microsoft Learn — Migrating from PowerShell 5.1](https://learn.microsoft.com/en-us/powershell/scripting/whats-new/migrating-from-windows-powershell-51-to-powershell-7)
**Hallazgos clave**:
- `$PSVersionTable.PSEdition` = `'Desktop'` en PS 5.1, `'Core'` en PS 7+
- **Técnica PS5-compatible para detectar OS**: `$PSVersionTable.PSEdition -eq 'Desktop'` implica Windows (PS5.1 solo en Windows)
- `[System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform()` funciona en ambos (ya usado en setup-machine.ps1 L221-222)
- `about_Windows_PowerShell_Compatibility` — PS 7 puede cargar módulos de PS 5.1 via WinPSCompat (solo Windows, proceso background)

### Search 4: "PowerShell 5.1 and PowerShell 7 parallel install side-by-side execution conflicts resolution"
**Fuente**: [MS Docs + GitHub roboflow/computer-vision-skills commit](https://github.com/roboflow/computer-vision-skills/commit/4918652)
**Hallazgos clave**:
- **Patrón de compatibilidad real probado en producción**:
  ```powershell
  function Test-RfWindows {
      if ($PSVersionTable.PSEdition -eq 'Desktop') { return $true }
      return [bool]$IsWindows
  }
  ```
- El problema: `$IsWindows` es `$null` en PS 5.1 → condiciones `if ($IsWindows)` fallan → **todos los branches se saltan** → comportamiento impredecible
- **Solución**: siempre usar `$PSVersionTable.PSEdition -eq 'Desktop'` como shortcut para Windows en PS 5.1

### Search 5: "PowerShell 5.1 Set-StrictMode ConvertTo-Json depth parameter differences"
**Fuente**: [Microsoft Learn — Set-StrictMode](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode), [ConvertTo-Json PS 5.1](https://github.com/MicrosoftDocs/PowerShell-Docs)
**Hallazgos clave**:
- `Set-StrictMode -Version Latest` en PS 5.1 = versión 2.0 (más permisivo que PS 7 `Latest`)
- `ConvertTo-Json -Depth` default = 2 en ambos; en PS 5.1 el max es 100, en PS 7 sigue siendo 100
- `[System.Management.Automation.PSSerializer]::Serialize/Deserialize` → **disponible desde PS 3.0**, funciona en PS 5.1 ✅
- `[regex]::Replace` con scriptblock → funciona en PS 5.1 ✅
- `Get-Content -Raw` → disponible desde PS 5.0 (no PS 3) ✅
- `Add-Member -NotePropertyName` → disponible desde PS 3.0 ✅
- `using namespace` → PS 5.1 (funciona) ✅

### Search 6 (bonus): "PowerShell 5.1 $args vs @args splatting"
**Fuente**: [Microsoft Learn — about_Splatting](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting)
**Hallazgos clave**:
- `@args` (splatting de parámetros de función) → **PS 7.1+ exclusive**
- `$args` → disponible desde PS 1.0, funciona en ambos versiones
- En funciones avanzadas (con `[CmdletBinding()]`), `$args` no existe, pero `@args` sí en PS 7.1+
- Para scripts no-avanzados (script-level), `$args` funciona en PS 5.1 y PS 7

## 3. Impacto en gentleman-agent-gh

### Archivos críticos para `gentleman-vmk` (path de setup → shortcut):

| Archivo | `#requires` | PS7-only features | Impacto PS5 |
|---|---|---|---|
| `scripts/lib/platform.ps1` | 7 | `$IsLinux`, `$IsMacOS` | ❌ No carga |
| `scripts/lib/json-utils.ps1` | 7 | Ninguno (PSSerializer, regex) | ❌ No carga |
| `scripts/lib/template-detection.ps1` | 7 | Ninguno (hashtable, regex) | ❌ No carga |
| `scripts/setup-machine.ps1` | 7 | `@args` (L118 shortcut), `$Is*` (L57) | ❌ No ejecuta |
| `scripts/setup-install.ps1` | 7 | Ninguno (wrapper) | ❌ No ejecuta |
| `scripts/gentleman-init.ps1` | 7 | `@args` (L17) | ❌ No ejecuta |
| `scripts/use-gentleman.ps1` | 7 | `$Is*` vía platform.ps1 | ❌ No ejecuta |
| `scripts/sync-vmk.ps1` | 7 | Ninguno directo, usa platform.ps1 | ❌ No ejecuta |
| `scripts/sync-all.ps1` | 7 | `$Is*` (L39), pero YA tiene redirect PS5→PS7 | ⚠️ Redirect funciona si pwsh instalado |

### Patrón de redirect PS5→PS7 (ya implementado en sync-all.ps1 L28-51):
```powershell
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh = Find-Pwsh  # usa Get-Command pwsh
    if ($pwsh) {
        & $pwsh.Source @params  # re-ejecuta en PS7
        exit $LASTEXITCODE
    }
    Write-Error "Requiere PowerShell 7+"
    exit 1
}
```
Este patrón funciona pero **requiere que PS7 esté instalado**.

### El problema del shortcut `gentleman-vmk.ps1`:
- `setup-machine.ps1:118` genera un `.ps1` con `opencode --agent gentleman-vMK @args`
- `@args` es PS7.1+ → **el shortcut .ps1 no funciona en PS 5.1**
- El `.cmd` funciona siempre (`%*` es CMD syntax)

## 4. Estrategia de fix (3 enfoques)

| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** (Shim PS5) | Añadir compat-shim `$Is*` en platform.ps1; bajar `#requires` a 5.1; `@args`→`$args` | Funciona en PS5 SIN necesidad de PS7; máxima portabilidad | Más archivos tocar; actualizar test de compat |
| **B** (Redirect-only) | Bajar `#requires` a 5.1; redirect a pwsh (como sync-all.ps1); fix `@args`→`$args` | Patrón ya probado en sync-all; menos cambios en libs | Si PS7 no está instalado → falla (el problema del usuario) |
| **C** (Dual-mode estratégico) | A: libs compatibles con PS5 (shim `$Is*`); B: entry-points con redirect opcional a PS7 si disponible; create `.bat` wrapper | Máxima compatibilidad; siempre funciona; `.cmd`/`.bat` siempre disponible | Más archivos; complejidad moderada |

**Ganador**: **C** — combina A (libs PS5-compat) + B (entry-points con redirect) + `.bat` wrapper. Si PS7 está instalado → redirect a PS7; si no → ejecuta nativo en PS5.1. El shortcut `.cmd` siempre funciona.

## 5. Especificación técnica de fixes

1. **`platform.ps1`**: `#requires -Version 5.1` + shim:
   ```powershell
   if (-not (Get-Variable IsLinux -ValueOnly -ErrorAction SilentlyContinue)) {
       $IsLinux = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)
       $IsMacOS = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)
       $IsWindows = $PSVersionTable.PSEdition -eq 'Desktop' -or [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
   }
   ```
2. **`json-utils.ps1`**: `#requires -Version 5.1` (PSSerializer funciona en PS3+)
3. **`template-detection.ps1`**: `#requires -Version 5.1` (no PS7 features)
4. **Shortcut template** (`setup-machine.ps1:118`): `@args` → `$args`
5. **Entry-point scripts**: `#requires -Version 5.1` en setup-machine, setup-install, gentleman-init, use-gentleman, sync-vmk
6. **`gentleman-init.ps1`**: `@args` → `$args`
7. **`sync-all.ps1:39`**: usa `$IsLinux`/`$IsMacOS` del shim de platform.ps1 (funciona después del fix #1)
8. **`gentleman-vmk.bat`**: wrapper CMD auto-detect PS (como sync-all.bat)
9. **Test**: `powershell-compat.Tests.ps1` actualizar para permitir libs 5.1; nuevo `ps5-compat.Tests.ps1`
