#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
  Sync 1..N projects from a single manifest — one-shot bulk gentleman-ize.
.DESCRIPTION
  Wrapper around bin/sync.exe (Go binary). Reads a projects.json manifest and
  syncs every listed project using update-all. When the Go binary is unavailable,
  falls back to calling scripts/use-gentleman.ps1 per-project (slower).

  Manifest format:
    { "version":1, "chainRoot":".", "defaultMode":"chain-wins",
      "projects":[{"path":"../mi-api","defaultAgent":"gentleman-vMK"}] }

.PARAMETER Manifest
  Path to projects.json manifest file. Default: ./projects.json

.PARAMETER Mode
  Merge strategy: chain-wins (default) or project-wins.

.PARAMETER DryRun
  Report what would be done without writing files.

.PARAMETER Json
  Output JSON report for agent consumption.

.PARAMETER Quiet
  Minimal output.

.PARAMETER Yes
  Non-interactive — skip confirmation prompts.

.PARAMETER AddProject
  Append a project to the manifest before syncing. Relative path resolved
  against the manifest's chainRoot.

.EXAMPLE
  .\scripts\sync-n-projects.ps1
  Sync all projects from ./projects.json.

.EXAMPLE
  .\scripts\sync-n-projects.ps1 -Manifest ../mi-org/projects.json -Mode project-wins

.EXAMPLE
  .\scripts\sync-n-projects.ps1 -AddProject ../nuevo-svc -DryRun
#>
param(
    [string]$Manifest = "./projects.json",
    [ValidateSet("chain-wins","project-wins")]
    [string]$Mode = "chain-wins",
    [switch]$DryRun,
    [switch]$Json,
    [switch]$Quiet,
    [switch]$Yes,
    [string]$AddProject
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Cross-platform helpers ──────────────────────────────────────────────
. (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")

# ── PowerShell version check — graceful redirect ──────────────────────
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh = Find-Pwsh
    if ($pwsh) {
        Write-Warning "PowerShell $($PSVersionTable.PSVersion) no es compatible."
        Write-Warning "Redirigiendo a $($pwsh.Name)..."
        $params = @("-NoLogo", "-NoProfile", "-File", $PSCommandPath)
        if ($Manifest -ne "./projects.json") { $params += "-Manifest"; $params += $Manifest }
        if ($Mode -ne "chain-wins")          { $params += "-Mode";     $params += $Mode }
        if ($DryRun) { $params += "-DryRun" }
        if ($Json)   { $params += "-Json" }
        if ($Quiet)  { $params += "-Quiet" }
        if ($Yes)    { $params += "-Yes" }
        if ($AddProject) { $params += "-AddProject"; $params += $AddProject }
        & $pwsh.Source $params
        exit $LASTEXITCODE
    }
    $installHint = if ($IsLinux -or $IsMacOS) {
        "  Instalá pwsh: https://docs.microsoft.com/powershell/scripting/install/installing-powershell"
    } else {
        "  winget install Microsoft.PowerShell"
    }
    Write-Error "╔══════════════════════════════════════════════════════╗"
    Write-Error "║  Requiere PowerShell 7+                              ║"
    Write-Error "║  Versión actual: $($PSVersionTable.PSVersion)                      ║"
    Write-Error "║  Usá sync-all.bat o instalá pwsh:                     ║"
    Write-Error $installHint
    Write-Error "╚══════════════════════════════════════════════════════╝"
    exit 1
}

$repoRoot = Split-Path $PSScriptRoot -Parent

# ── Resolve manifest ──────────────────────────────────────────────────
$manifestPath = [System.IO.Path]::GetFullPath($Manifest)
if (-not (Test-Path $manifestPath -PathType Leaf)) {
    # Fallback: resolve relative to repo root (CWD may not match process CWD)
    $manifestPath = Join-Path $repoRoot $Manifest
}
if (-not (Test-Path $manifestPath -PathType Leaf)) {
    Write-Error "Manifest not found: $manifestPath"
    exit 1
}

try {
    $manifestObj = Get-Content $manifestPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Failed to parse manifest as JSON: $($_.Exception.Message)"
    exit 1
}
if ($manifestObj.version -ne 1) {
    Write-Error "Invalid manifest: expected version 1, got '$($manifestObj.version)'"
    exit 1
}
if ($null -eq $manifestObj.projects -or $manifestObj.projects -isnot [System.Array] -or $manifestObj.projects.Count -eq 0) {
    Write-Error "Invalid manifest: 'projects' must be a non-empty array"
    exit 1
}
$invalidPaths = $manifestObj.projects | Where-Object { -not $_.path -or $_.path -match '^\s*$' }
if ($invalidPaths) {
    Write-Error "Invalid manifest: each project must have a non-empty 'path'"
    exit 1
}
# E7/E8 perf-ciclo37-clusterA (C35A/E7 memo + E8 precomputado): manifestDir se
# calcula 1 vez aqui; AddProject y el loop fallback lo reusan (antes: Split-Path
# por proyecto).
$manifestDir = Split-Path $manifestPath -Parent
# F1v2 anchor: manifestDirFull still computed for the sibling-escape audit
# warning. FullPath normalizes `..`/separators; trailing-sep StartsWith
# rejects `/root-evil` style prefix siblings (same style as Join-PathSafe).
$manifestDirFull = [System.IO.Path]::GetFullPath($manifestDir)
$manifestSep = [System.IO.Path]::DirectorySeparatorChar
$addEscapeDetail = $null
# F1v2 protected-location gate (replaces F1 manifestDir FAIL): the manifest IS
# the operator allowlist, so sibling layout (../x) is by-design. Only FAIL
# (no throw) when the resolved target is a protected location: a drive root
# ([IO.Path]::GetPathRoot($t) -eq $t, e.g. D:\ C:\) or inside SystemRoot,
# SystemRoot\System32, ProgramFiles, ProgramFiles(x86). OrdinalIgnoreCase.
function Test-ProtectedLocation {
    param([string]$Full)
    if ([string]::IsNullOrEmpty($Full)) { return $false }
    try { if ([IO.Path]::GetPathRoot($Full) -eq $Full) { return $true } } catch { }
    $protected = @()
    if ($env:SystemRoot) {
        $protected += [System.IO.Path]::GetFullPath($env:SystemRoot)
        $protected += [System.IO.Path]::GetFullPath((Join-Path $env:SystemRoot "System32"))
    }
    if (${env:ProgramFiles}) { $protected += [System.IO.Path]::GetFullPath(${env:ProgramFiles}) }
    if (${env:ProgramFiles(x86)}) { $protected += [System.IO.Path]::GetFullPath(${env:ProgramFiles(x86)}) }
    foreach ($p in $protected) {
        if ($Full -eq $p) { return $true }
        if ($Full.StartsWith($p + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
        if ($Full.Equals($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

# ── Add project (optional) ───────────────────────────────────────────
if ($AddProject) {
    # Resolve relative to manifest directory first (CWD may diverge)
    $addPath = Join-Path $manifestDir $AddProject
    if (-not (Test-Path $addPath)) {
        $addPath = [System.IO.Path]::GetFullPath($AddProject)
    }
    # F1v2 confinement: FAIL (no abort) only on protected locations.
    $addFull = [System.IO.Path]::GetFullPath($addPath)
    $addEscapes = -not ($addFull.StartsWith($manifestDirFull + $manifestSep, [System.StringComparison]::OrdinalIgnoreCase) -or $addFull -eq $manifestDirFull)
    $addProtected = Test-ProtectedLocation $addFull
    # Normalize existing entries against manifest dir to avoid absolute-vs-relative false negatives
    $existing = $manifestObj.projects | Where-Object {
        $resolved = if ([System.IO.Path]::IsPathRooted($_.path)) { $_.path } else { Join-Path $manifestDir $_.path }
        ([System.IO.Path]::GetFullPath($resolved)) -eq ([System.IO.Path]::GetFullPath($addPath))
    }
    if ($addProtected) {
        # F1v2+F3: record FAIL (visible even under -Quiet) and skip the add —
        # the bulk sync below still runs. $results is recorded later (it is
        # initialized after this block); the warning is emitted now.
        # F3-purity: warnings surface on stdout on PS7 console hosts, so emit
        # only in text mode — under -Json the FAIL already lives in $results.
        if (-not $Json) { Write-Warning "add ${AddProject}: FAIL — protected location: $addPath" }
        $addEscapeDetail = "protected location: $addPath"
    } else {
        if ($addEscapes) {
            # Sibling layout is by-design (manifest is the allowlist): audit
            # warning only, then continue normal (OK/WOULD según exista).
            if (-not $Json) { Write-Warning "add ${AddProject}: target outside manifest root (sibling layout, manifest is allowlist): $addFull" }
        }
        if ($existing) {
        if (-not $Quiet) { Write-Output "[skip] $addPath already in manifest" }
    } else {
        $manifestObj.projects += @{ path = $addPath; defaultAgent = "gentleman-vMK" }
        if (-not $DryRun) {
            # Atomic rewrite: write to temp then move — prevents half-written manifests.
            # Unique temp name to avoid collisions between concurrent runs.
            $tmpDir = Split-Path $manifestPath -Parent
            $tmpPath = Join-Path $tmpDir "sync-n-projects.$([IO.Path]::GetRandomFileName()).tmp"
            try {
                $manifestObj | ConvertTo-Json -Depth 10 | Set-Content $tmpPath -Encoding UTF8
                Move-Item -Path $tmpPath -Destination $manifestPath -Force
            } catch {
                if (Test-Path $tmpPath) { Remove-Item $tmpPath -Force -ErrorAction SilentlyContinue }
                Write-Error "Failed to write manifest (atomic rewrite failed): $($_.Exception.Message)"
                exit 1
            }
            if (-not $Quiet) { Write-Output "[ok] Added $addPath to manifest" }
        } else {
            if (-not $Quiet) { Write-Output "[dry-run] Would add $addPath to manifest" }
        }
    }
    }
}

# ── Resolve binary ────────────────────────────────────────────────────
$binDir = Join-Path $repoRoot "bin"
if ($IsLinux -or $IsMacOS) {
    $syncExe = Join-Path $binDir "sync"
} else {
    $syncExe = Join-Path $binDir "sync.exe"
}
$useBinary = $false

if (Test-Path $syncExe -PathType Leaf) {
    $useBinary = $true
} elseif ($IsLinux -or $IsMacOS) {
    $alt = Join-Path $binDir "sync"
    if (Test-Path $alt -PathType Leaf) {
        $syncExe = $alt
        $useBinary = $true
    }
}

# ── Results collection ────────────────────────────────────────────────
$results = [System.Collections.Generic.List[object]]::new()
$hasDrift = $false
if ($addEscapeDetail) {
    $results.Add(@{ step = "add $AddProject"; status = "FAIL"; detail = $addEscapeDetail })
    $hasDrift = $true
}

if ($useBinary) {
    # ── Binary path: update-all --manifest ──────────────────────────────
    $binArgs = @("update-all", "--manifest", $manifestPath, "--mode", $Mode)
    if ($DryRun) { $binArgs += "--dry-run" }
    if ($Json)   { $binArgs += "--json" }

    # F3-purity (pre-existing): keep stdout JSON-clean in binary+Json mode.
    if (-not $Quiet -and -not $Json) { Write-Host "Using sync binary: $syncExe" -ForegroundColor DarkGray }

    # Binary handshake: verify the binary is functional before trusting it with data.
    # bin/ is an artifact of the local operator (trusted-operator model) — not vendored code.
    try {
        $null = & $syncExe --help 2>&1
        if ($LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }
    } catch {
        Write-Warning "Binary handshake failed ($syncExe --help): $($_.Exception.Message)"
        Write-Warning "Falling back to use-gentleman.ps1 (slower)"
        $useBinary = $false
    }
}

if ($useBinary) {
    if ($PSCmdlet.ShouldProcess($manifestPath, "sync update-all")) {
        try {
            # v1 limitation: no async timeout — a hung binary blocks the wrapper.
            # PS 5.1 compat: Start-ThreadJob not available; jobs add complexity.
            if ($Json) {
                # Stderr to temp file so it doesn't corrupt JSON on stdout
                $errFile = [IO.Path]::GetTempFileName()
                try {
                    $out = & $syncExe @binArgs 2>$errFile
                    $stderr = if (Test-Path $errFile) { Get-Content $errFile -Raw } else { '' }
                    if ($stderr -and $stderr.Trim()) { Write-Host $stderr.Trim() -ForegroundColor DarkYellow }
                } finally {
                    if (Test-Path $errFile) { Remove-Item $errFile -Force -ErrorAction SilentlyContinue }
                }
            } else {
                # Text mode: stderr visible is useful for diagnostics
                $out = & $syncExe @binArgs 2>&1
            }
            # $LASTEXITCODE: 0=ok, nonzero=fail/drift (never null after calling a native exe)
            # Note: use-gentleman.ps1 errors via throw (caught by try/catch above);
            # this check covers native binaries only.
            if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) { $hasDrift = $true }
            $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
            Write-Output $out
            $results.Add(@{ step = "update-all"; status = if ($exitCode -eq 0) { "OK" } else { "FAIL" }; detail = "exit $exitCode" })
        } catch {
            $results.Add(@{ step = "update-all"; status = "FAIL"; detail = $_.Exception.Message })
            $hasDrift = $true
        }
    }
} else {
    # ── Fallback path: use-gentleman.ps1 per project ────────────────────
    # F3-purity (pre-existing): Write-Host pollutes stdout, so stay silent
    # under -Json — JSON consumers parse stdout strictly.
    if (-not $Quiet -and -not $Json) {
        Write-Host "[warn] sync binary not found — falling back to use-gentleman.ps1 (slower)" -ForegroundColor Yellow
    }

    $useGentleman = Join-Path (Join-Path $repoRoot "scripts") "use-gentleman.ps1"
    if (-not (Test-Path $useGentleman -PathType Leaf)) {
        Write-Error "Fallback script not found: $useGentleman"
        exit 1
    }

    foreach ($proj in $manifestObj.projects) {
        $projPath = $proj.path
        $agent = if ($proj.defaultAgent) { $proj.defaultAgent } else { "gentleman-vMK" }

        $step = "sync $projPath"
        if ($PSCmdlet.ShouldProcess($projPath, "use-gentleman")) {
            try {
                # Resolve path inside try so a bad entry doesn't abort the bulk
                # IsPathRooted guard: absolute paths used as-is, relative joined with manifest dir
                if ([System.IO.Path]::IsPathRooted($projPath)) {
                    $targetDir = [System.IO.Path]::GetFullPath($projPath)
                } else {
                    # E8: $manifestDir precomputado (era Split-Path por proyecto)
                    $targetDir = [System.IO.Path]::GetFullPath(
                        (Join-Path $manifestDir $projPath)
                    )
                }
                # F1v2 confinement: FAIL (no throw — bulk continues) only on
                # protected locations. Sibling escape is by-design (manifest is
                # the allowlist): audit warning, then normal flow.
                $loopEscapes = -not ($targetDir.StartsWith($manifestDirFull + $manifestSep, [System.StringComparison]::OrdinalIgnoreCase) -or $targetDir -eq $manifestDirFull)
                if (Test-ProtectedLocation $targetDir) {
                    $results.Add(@{ step = $step; status = "FAIL"; detail = "protected location: $projPath" })
                    if (-not $Json) { Write-Warning "${step}: FAIL — protected location: $projPath" }
                    $hasDrift = $true
                    continue
                }
                if ($loopEscapes) {
                    if (-not $Json) { Write-Warning "${step}: target outside manifest root (sibling layout, manifest is allowlist): $targetDir" }
                }
                if (-not (Test-Path $targetDir -PathType Container)) {
                    if ($DryRun) {
                        $results.Add(@{ step = $step; status = "OK"; detail = "WOULD sync $targetDir (target missing - would create)" })
                    } else {
                        $results.Add(@{ step = $step; status = "FAIL"; detail = "target missing: $targetDir" })
                        if (-not $Json) { Write-Warning "${step}: FAIL — target missing: $targetDir" }
                        $hasDrift = $true
                    }
                } else {
                    $guArgs = @{ TargetDir = $targetDir; DefaultAgent = $agent }
                    if ($DryRun) { $guArgs.DryRun = $true }
                    if ($Yes) { $guArgs.Yes = $true }
                    # E9 perf-ciclo37-clusterA (C35A/E9 Quiet bulk): en -Quiet se
                    # silencia la salida por proyecto; el resumen final ya esta
                    # condicionado a -not $Quiet (linea Output).
                    # F2 stale-guard: use-gentleman.ps1 is a script, not a native
                    # exe, so it never sets $LASTEXITCODE itself — reset it or a
                    # leftover native exit code from the caller session fakes a FAIL.
                    $global:LASTEXITCODE = 0
                    if ($Json -or $Quiet) { $null = & $useGentleman @guArgs 6>$null } else { & $useGentleman @guArgs }
                    # NOTE: use-gentleman.ps1 is a script, not a native exe, so it
                    # never sets $LASTEXITCODE (unset until a native command runs).
                    # Under Set-StrictMode reading it unset throws — guard it.
                    $guExit = if (Test-Path variable:LASTEXITCODE) { $LASTEXITCODE } else { $null }
                    if ($null -ne $guExit -and $guExit -ne 0) {
                        $results.Add(@{ step = $step; status = "FAIL"; detail = "use-gentleman exit $LASTEXITCODE" })
                        if (-not $Json) { Write-Warning "${step}: FAIL — use-gentleman exit $LASTEXITCODE" }
                        $hasDrift = $true
                    } else {
                        $results.Add(@{ step = $step; status = "OK"; detail = $targetDir })
                    }
                }
            } catch {
                $results.Add(@{ step = $step; status = "FAIL"; detail = $_.Exception.Message })
                if (-not $Json) { Write-Warning "${step}: FAIL — $($_.Exception.Message)" }
                $hasDrift = $true
            }
        } else {
            $results.Add(@{ step = $step; status = "SKIP"; detail = "ShouldProcess declined" })
        }
    }
}

# ── Output ────────────────────────────────────────────────────────────
if ($Json) {
    # When binary+Json, skip wrapper — the binary already emitted its own JSON.
    # The wrapper only applies for fallback (text) mode or when binary produced no JSON.
    if ($useBinary) {
        # Binary already wrote JSON to stdout — nothing more to do.
    } else {
        ConvertTo-Json @{
            timestamp  = (Get-Date -Format "o")
            manifest   = $manifestPath
            mode       = $Mode
            binaryUsed = $false
            dryRun     = [bool]$DryRun
            projects   = $manifestObj.projects.Count
            results    = $results
            success    = (-not $hasDrift)
        } -Depth 3
    }
} elseif (-not $Quiet) {
    Write-Output "`n═══════ SYNC-N-PROJECTS COMPLETE ═══════"
    Write-Output "  Manifest : $manifestPath"
    Write-Output "  Projects : $($manifestObj.projects.Count)"
    Write-Output "  Mode     : $Mode"
    Write-Output "  Binary   : $(if ($useBinary) { $syncExe } else { 'fallback (use-gentleman.ps1)' })"
    Write-Output "─────────────────────────────────────────"
    foreach ($r in $results) {
        $icon = switch ($r.status) { "OK" { "✅" } "SKIP" { "⏭️" } "FAIL" { "❌" } default { "❓" } }
        Write-Output "$icon $($r.step): $($r.detail)"
    }
    if ($hasDrift) { Write-Output "`n⚠️  Some projects failed or drifted — check output above" }
    Write-Output "═══════════════════════════════════════════"
}

# Exit: 0=ok, 2=fail/drift (binary never returns 1; use-gentleman.ps1 errors via throw → catch → FAIL status)
$exitCode = if ($hasDrift) { 2 } else { 0 }
exit $exitCode
