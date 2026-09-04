<# 
.SYNOPSIS
  Freeze / unfreeze opencode model configs (read-only guard + sentinel).

.DESCRIPTION
  Manages a filesystem-level freeze for model assignments:
    - Global config: opencode.jsonc
    - SSoT: scripts/lib/opencode-base.json
    - Sentinel: .model-cache.frozen
  Freeze sets +R on both configs and writes the sentinel with date + per-model counts.
  Unfreeze clears +R and renames the sentinel to .model-cache.unfrozen for audit.
  Status reports sentinel existence, IsReadOnly per file, per-model counts, and JSON parseability.
  Idempotent and re-runnable. Supports -WhatIf / -Confirm via SupportsShouldProcess.
  PowerShell 5.1 compatible, ASCII only.

.PARAMETER Action
  Freeze | Unfreeze | Status (default Status).

.PARAMETER Quiet
  Machine-readable JSON output (Status) or suppressed host output (Freeze/Unfreeze).

.EXAMPLE
  powershell -File scripts\freeze-models.ps1 -Action Status
  powershell -File scripts\freeze-models.ps1 -Action Freeze
  powershell -File scripts\freeze-models.ps1 -Action Unfreeze
  powershell -File scripts\freeze-models.ps1 -Action Freeze -WhatIf
  powershell -File scripts\freeze-models.ps1 -Action Status -Quiet

.NOTES
  Sentinel is written with Set-Content -Encoding UTF8. On PowerShell 5.1 this adds a BOM,
  which is acceptable for a plain-text sentinel (documented). JSON files are never rewritten.
  Freeze does NOT block regenerate-opencode.ps1 logically; that script will fail on write
  when files are +R, which is the intended enforcement (feature, not bug).
  See also: scripts/regenerate-opencode.ps1
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet("Freeze","Unfreeze","Status")]
    [string]$Action = "Status",
    [switch]$Quiet
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Resolve paths relative to this script ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir -or -not (Test-Path -LiteralPath $scriptDir)) {
    $scriptDir = $PSScriptRoot
}
$globalRoot = Split-Path -Parent $scriptDir
# Fallback if layout is unexpected
if (-not (Test-Path -LiteralPath (Join-Path $globalRoot "opencode.jsonc"))) {
    # Try resolving via .. from scriptDir
    try { $globalRoot = (Resolve-Path -LiteralPath (Join-Path $scriptDir "..")).Path } catch {}
}

$jsoncPath = Join-Path $globalRoot "opencode.jsonc"
$basePath = Join-Path $globalRoot "scripts\lib\opencode-base.json"
$sentinelPath = Join-Path $globalRoot ".model-cache.frozen"
$unfrozenPath = Join-Path $globalRoot ".model-cache.unfrozen"

function Get-ModelCounts {
    param([string]$Path)
    $result = [ordered]@{
        exists = $false
        total = 0
        byModel = @{}
        error = $null
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        $result.error = "File not found"
        return $result
    }
    $result.exists = $true
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        $matches = [regex]::Matches($raw, '"model"\s*:\s*"([^"]+)"')
        $result.total = $matches.Count
        $groups = @{}
        foreach ($m in $matches) {
            $id = $m.Groups[1].Value
            if (-not $groups.ContainsKey($id)) { $groups[$id] = 0 }
            $groups[$id] += 1
        }
        $result.byModel = $groups
    } catch {
        $result.error = $_.Exception.Message
    }
    return $result
}

function Get-ReadOnlyFlag {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        return $item.IsReadOnly
    } catch { return $null }
}

function Test-JsonParseable {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        $null = $raw | ConvertFrom-Json -ErrorAction Stop
        return $true
    } catch { return $false }
}

function Get-SentinelExists {
    return (Test-Path -LiteralPath $sentinelPath)
}

# --- Gather status (used by all actions) ---
$jsoncCounts = Get-ModelCounts -Path $jsoncPath
$baseCounts = Get-ModelCounts -Path $basePath
$jsoncRO = Get-ReadOnlyFlag -Path $jsoncPath
$baseRO = Get-ReadOnlyFlag -Path $basePath
$sentinelExists = Get-SentinelExists
$jsoncParseable = Test-JsonParseable -Path $jsoncPath
$baseParseable = Test-JsonParseable -Path $basePath

if ($Action -eq "Status") {
    $statusObj = [ordered]@{
        timestamp = (Get-Date -Format "o")
        action = "Status"
        sentinel = [ordered]@{
            path = $sentinelPath
            exists = $sentinelExists
            unfrozenPath = $unfrozenPath
            unfrozenExists = (Test-Path -LiteralPath $unfrozenPath)
        }
        files = [ordered]@{
            opencodeJsonc = [ordered]@{
                path = $jsoncPath
                exists = (Test-Path -LiteralPath $jsoncPath)
                isReadOnly = $jsoncRO
                parseable = $jsoncParseable
                totalModels = $jsoncCounts.total
                byModel = $jsoncCounts.byModel
                error = $jsoncCounts.error
            }
            opencodeBase = [ordered]@{
                path = $basePath
                exists = (Test-Path -LiteralPath $basePath)
                isReadOnly = $baseRO
                parseable = $baseParseable
                totalModels = $baseCounts.total
                byModel = $baseCounts.byModel
                error = $baseCounts.error
            }
        }
        frozen = ($sentinelExists -and $jsoncRO -eq $true -and $baseRO -eq $true)
    }

    if ($Quiet) {
        $statusObj | ConvertTo-Json -Depth 6 | Write-Output
    } else {
        Write-Output "=== freeze-models Status ==="
        if ($sentinelExists) {
            Write-Output "Sentinel: EXISTS  $sentinelPath"
            try {
                $sentContent = Get-Content -LiteralPath $sentinelPath -Raw -ErrorAction SilentlyContinue
                if ($sentContent) {
                    $firstLine = ($sentContent -split "`r?`n")[0]
                    Write-Output "  First line: $firstLine"
                }
            } catch {}
        } else {
            Write-Output "Sentinel: MISSING $sentinelPath"
            if (Test-Path -LiteralPath $unfrozenPath) {
                Write-Output "  Unfrozen marker exists: $unfrozenPath"
            }
        }
        $roTextJsonc = if ($jsoncRO -eq $true) { "READONLY (+R)" } elseif ($jsoncRO -eq $false) { "writable (-R)" } else { "unknown/missing" }
        $roTextBase = if ($baseRO -eq $true) { "READONLY (+R)" } elseif ($baseRO -eq $false) { "writable (-R)" } else { "unknown/missing" }
        Write-Output "opencode.jsonc: $roTextJsonc  parseable=$jsoncParseable  models=$($jsoncCounts.total)"
        foreach ($k in ($jsoncCounts.byModel.Keys | Sort-Object)) {
            Write-Output "  $k : $($jsoncCounts.byModel[$k])"
        }
        if ($jsoncCounts.error) { Write-Output "  error: $($jsoncCounts.error)" }
        Write-Output "opencode-base.json: $roTextBase  parseable=$baseParseable  models=$($baseCounts.total)"
        foreach ($k in ($baseCounts.byModel.Keys | Sort-Object)) {
            Write-Output "  $k : $($baseCounts.byModel[$k])"
        }
        if ($baseCounts.error) { Write-Output "  error: $($baseCounts.error)" }
        $frozenText = if ($statusObj.frozen) { "FROZEN" } else { "NOT FROZEN" }
        Write-Output "Overall: $frozenText"
        Write-Output "Hint: Freeze -> powershell -File scripts\freeze-models.ps1 -Action Freeze"
        Write-Output "      Unfreeze -> powershell -File scripts\freeze-models.ps1 -Action Unfreeze"
    }
    exit 0
}

if ($Action -eq "Freeze") {
    # Build sentinel content
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $nowIso = Get-Date -Format "o"
    $lines = @()
    $lines += "Frozen $now by freeze-models.ps1"
    $lines += "Timestamp: $nowIso"
    $lines += " Sentinel: $sentinelPath"
    $lines += ""
    $lines += "Counts opencode.jsonc: $($jsoncCounts.total) model entries"
    if ($jsoncCounts.byModel.Count -gt 0) {
        foreach ($k in ($jsoncCounts.byModel.Keys | Sort-Object)) {
            $lines += "  $k : $($jsoncCounts.byModel[$k])"
        }
    } else {
        $lines += "  (no models found or file missing)"
    }
    $lines += " parseable: $jsoncParseable"
    $lines += ""
    $lines += "Counts opencode-base.json: $($baseCounts.total) model entries"
    if ($baseCounts.byModel.Count -gt 0) {
        foreach ($k in ($baseCounts.byModel.Keys | Sort-Object)) {
            $lines += "  $k : $($baseCounts.byModel[$k])"
        }
    } else {
        $lines += "  (no models found or file missing)"
    }
    $lines += " parseable: $baseParseable"
    $lines += ""
    $lines += "To unfreeze: powershell -File scripts\freeze-models.ps1 -Action Unfreeze"
    $lines += "Manual alt: attrib -R `"$jsoncPath`" ; attrib -R `"$basePath`" ; move `"$sentinelPath`" `"$unfrozenPath`""
    $lines += "Note: Sentinel written with Set-Content -Encoding UTF8 (PS 5.1 adds BOM, acceptable for sentinel)."
    $lines += "Freeze enforcement is filesystem read-only (+R); regenerate-opencode.ps1 -Yes will fail while frozen (by design)."

    if ($PSCmdlet.ShouldProcess($sentinelPath, "Write frozen sentinel")) {
        # Ensure parent exists
        $parentDir = Split-Path -Parent $sentinelPath
        if (-not (Test-Path -LiteralPath $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        # If sentinel was previously read-only, clear it first so we can overwrite
        if (Test-Path -LiteralPath $sentinelPath) {
            try {
                $sItem = Get-Item -LiteralPath $sentinelPath -ErrorAction SilentlyContinue
                if ($sItem -and $sItem.IsReadOnly) {
                    Set-ItemProperty -LiteralPath $sentinelPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
                }
            } catch {}
        }
        Set-Content -LiteralPath $sentinelPath -Value ($lines -join [Environment]::NewLine) -Encoding UTF8
        if (-not $Quiet) { Write-Output "[freeze] Sentinel written: $sentinelPath" }
    }

    foreach ($pair in @(@{ Path = $jsoncPath; Label = "opencode.jsonc" }, @{ Path = $basePath; Label = "opencode-base.json" })) {
        $p = $pair.Path
        $label = $pair.Label
        if (-not (Test-Path -LiteralPath $p)) {
            if (-not $Quiet) { Write-Warning "[freeze] Skip $label : not found $p" }
            continue
        }
        if ($PSCmdlet.ShouldProcess($p, "Set read-only (+R)")) {
            try {
                Set-ItemProperty -LiteralPath $p -Name IsReadOnly -Value $true -ErrorAction Stop
                if (-not $Quiet) { Write-Output "[freeze] +R $label : $p" }
            } catch {
                Write-Warning "[freeze] Failed to set +R on $label : $($_.Exception.Message)"
            }
        }
    }

    if (-not $Quiet) {
        Write-Output "[freeze] Done. Verify with: powershell -File scripts\freeze-models.ps1 -Action Status"
    } else {
        $out = [ordered]@{
            action = "Freeze"
            timestamp = (Get-Date -Format "o")
            sentinel = $sentinelPath
            files = @($jsoncPath, $basePath)
            counts = [ordered]@{ opencodeJsonc = $jsoncCounts.total; opencodeBase = $baseCounts.total }
        }
        $out | ConvertTo-Json -Depth 4 | Write-Output
    }
    exit 0
}

if ($Action -eq "Unfreeze") {
    foreach ($pair in @(@{ Path = $jsoncPath; Label = "opencode.jsonc" }, @{ Path = $basePath; Label = "opencode-base.json" })) {
        $p = $pair.Path
        $label = $pair.Label
        if (-not (Test-Path -LiteralPath $p)) {
            if (-not $Quiet) { Write-Warning "[unfreeze] Skip $label : not found $p" }
            continue
        }
        if ($PSCmdlet.ShouldProcess($p, "Clear read-only (-R)")) {
            try {
                Set-ItemProperty -LiteralPath $p -Name IsReadOnly -Value $false -ErrorAction Stop
                if (-not $Quiet) { Write-Output "[unfreeze] -R $label : $p" }
            } catch {
                Write-Warning "[unfreeze] Failed to clear -R on $label : $($_.Exception.Message)"
            }
        }
    }

    if (Test-Path -LiteralPath $sentinelPath) {
        if ($PSCmdlet.ShouldProcess($sentinelPath, "Rename sentinel to .model-cache.unfrozen for audit")) {
            # Clear read-only on sentinel if needed before move
            try {
                $sItem = Get-Item -LiteralPath $sentinelPath -ErrorAction SilentlyContinue
                if ($sItem -and $sItem.IsReadOnly) {
                    Set-ItemProperty -LiteralPath $sentinelPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
                }
            } catch {}
            $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $nowIso = Get-Date -Format "o"
            # Move to unfrozen
            try {
                Move-Item -LiteralPath $sentinelPath -Destination $unfrozenPath -Force -ErrorAction Stop
                if (-not $Quiet) { Write-Output "[unfreeze] Renamed sentinel -> $unfrozenPath" }
            } catch {
                Write-Warning "[unfreeze] Move failed, trying copy+remove: $($_.Exception.Message)"
                try {
                    Copy-Item -LiteralPath $sentinelPath -Destination $unfrozenPath -Force -ErrorAction Stop
                    Remove-Item -LiteralPath $sentinelPath -Force -ErrorAction Stop
                } catch {
                    Write-Warning "[unfreeze] Failed to rename sentinel: $($_.Exception.Message)"
                }
            }
            # Append/overwrite unfrozen marker
            try {
                $origContent = ""
                if (Test-Path -LiteralPath $unfrozenPath) {
                    $origContent = Get-Content -LiteralPath $unfrozenPath -Raw -ErrorAction SilentlyContinue
                }
                $marker = @()
                $marker += "UNFROZEN $now by freeze-models.ps1"
                $marker += "Timestamp: $nowIso"
                $marker += "Previous sentinel was: $sentinelPath"
                $marker += "Files set writable (-R): $jsoncPath , $basePath"
                $marker += "To refreeze: powershell -File scripts\freeze-models.ps1 -Action Freeze"
                $marker += ""
                $marker += "--- Previous frozen content ---"
                $marker += $origContent
                Set-Content -LiteralPath $unfrozenPath -Value ($marker -join [Environment]::NewLine) -Encoding UTF8
            } catch {
                Write-Warning "[unfreeze] Failed to write unfrozen marker: $($_.Exception.Message)"
            }
        }
    } else {
        if (-not $Quiet) { Write-Output "[unfreeze] No sentinel found at $sentinelPath (already unfrozen or never frozen)" }
        # Still ensure unfrozen marker exists for audit if we cleared +R
        if (-not (Test-Path -LiteralPath $unfrozenPath)) {
            if ($PSCmdlet.ShouldProcess($unfrozenPath, "Create unfrozen audit marker")) {
                $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $nowIso = Get-Date -Format "o"
                $linesU = @()
                $linesU += "UNFROZEN $now by freeze-models.ps1 (no prior sentinel)"
                $linesU += "Timestamp: $nowIso"
                $linesU += "Files set writable (-R): $jsoncPath , $basePath"
                $linesU += "To refreeze: powershell -File scripts\freeze-models.ps1 -Action Freeze"
                Set-Content -LiteralPath $unfrozenPath -Value ($linesU -join [Environment]::NewLine) -Encoding UTF8
            }
        }
    }

    if (-not $Quiet) {
        Write-Output "[unfreeze] Done. Verify with: powershell -File scripts\freeze-models.ps1 -Action Status"
    } else {
        $out = [ordered]@{ action = "Unfreeze"; timestamp = (Get-Date -Format "o"); sentinelRenamedTo = $unfrozenPath; files = @($jsoncPath, $basePath) }
        $out | ConvertTo-Json -Depth 4 | Write-Output
    }
    exit 0
}
