#requires -Version 7
<#
.SYNOPSIS
    Remove deprecated '*-semi' agents from the global OpenCode config (opencodec.json).

.DESCRIPTION
    Per ADR-033 (simplify permission modes to manual|auto only), the legacy
    gentleman-*-semi agents defined in scripts/opencode-config/semi-agents.json
    are removed from the global OpenCode config to prevent them from appearing
    in the agent selector.

    ⚠️ USAGE: Run THIS SCRIPT in the session that OWNS the writable
    opencodec.json (usually the user's primary OpenCode session):

        pwsh -File scripts/remove-semi-agents.ps1            # default: $env:USERPROFILE\.config\opencode\opencodec.json
        pwsh -File scripts/remove-semi-agents.ps1 -DryRun    # preview only, no writes

    WHY A SEPARATE SCRIPT: opencodec.json lives in the global OpenCode config
    dir (~/.config/opencode/), which is outside the workspace write-scope. A
    dedicated idempotent script lets the user apply the deprecation cleanup
    from their own session where the file is writable.

.LINK
    adr/ADR-033-eliminar-modo-semi-manual-auto.md
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = $null,
    [switch]$DryRun
,
    [switch]$Quiet,
    [switch]$Json)
Set-StrictMode -Version Latest

# --- Resolve the global opencodec.json path (auto-discover candidates) ---
# OpenCode may store it in XDG-style ~/.config/opencode, %APPDATA%, or %LOCALAPPDATA%.
# Some filesystems expose a "ghost" entry (Get-ChildItem shows it but Test-Path/Get-Content
# fail — e.g. WSL interop stale inode, broken junction, unmounted volume). We probe every
# candidate directory AND validate the file is READABLE, skipping ghosts.
$candidatePaths = @(
    "$env:USERPROFILE\.config\opencode\opencodec.json",
    "$env:APPDATA\opencode\opencodec.json",
    "$env:LOCALAPPDATA\opencode\opencodec.json",
    "$env:USERPROFILE\.opencode\opencodec.json"
)
if (-not $ConfigPath) {
    foreach ($p in $candidatePaths) {
        $parent = Split-Path $p -Parent
        if (Test-Path -LiteralPath $p -PathType Leaf -ErrorAction Stop) {
            try {
                $null = Get-Content -LiteralPath $p -Raw -TotalCount 1 -ErrorAction Stop
                $ConfigPath = $p; break
            } catch {
                Write-Warning "Ghost file detected (listed but unreadable): $p — skipping."
                # Show whether the parent dir is accessible
                if (Test-Path -LiteralPath $parent -PathType Container -ErrorAction SilentlyContinue) {
                    $child = Get-ChildItem -LiteralPath $parent -Force -Filter "opencodec.json" -ErrorAction SilentlyContinue
                    if ($child) { Write-Warning "  Parent dir lists it but it cannot be opened — likely WSL interop ghost or stale inode." }
                }
            }
        }
    }
}
if (-not $ConfigPath) {
    $probeReport = $candidatePaths | ForEach-Object { "  $_ (exists=$(Test-Path $_ -ErrorAction SilentlyContinue))" }
    Write-Error "Could not locate a READABLE opencodec.json. Probed these candidates:`n$($probeReport -join "`n")`nRun this script from a PowerShell session with full access to your user profile."
    exit 1
}

# Agents declared in scripts/opencode-config/semi-agents.json (SSOT for semi agents)
$semiAgents = @(
    'gentleman-deep-semi',
    'gentleman-quick-semi',
    'gentleman-codex-semi',
    'gentleman-implementer-semi',
    'gentleman-aem-semi',
    'gentleman-vMK-semi'
)

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    Write-Error "Config not found: $ConfigPath. Run this from the session where opencodec.json lives."
    exit 1
}

# Backup
$backup = "$ConfigPath.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
if ($DryRun) {
    Write-Host "[DRY RUN] Would back up $ConfigPath → $backup"
} else {
    Copy-Item -LiteralPath $ConfigPath -Destination $backup -Force
    Write-Host "Backup created: $backup"
}

# Load + validate JSON
$content = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8
try {
    $cfg = $content | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "opencodec.json is not valid JSON — aborting (backup already made). $_"
    exit 1
}

if (-not $cfg.PSObject.Properties.Name.Contains('agent')) {
    Write-Host "No 'agent' block found — nothing to remove."
    exit 0
}

$removed = @()
$skipped = @()
foreach ($name in $semiAgents) {
    $prop = $cfg.agent.PSObject.Properties[$name]
    if ($null -ne $prop) {
        if ($DryRun) {
            Write-Host "[DRY RUN] Would remove agent: $name"
        } else {
            $cfg.agent.PSObject.Properties.Remove($name)
            Write-Host "Removed agent: $name"
        }
        $removed += $name
    } else {
        $skipped += $name
    }
}

# Re-serialize preserving key order (agent section stays intact)
if ($DryRun) {
    Write-Host "[DRY RUN] Would write updated config back to $ConfigPath"
    Write-Host "[DRY RUN] Would also remove semi-agents.json template (optional): scripts/opencode-config/semi-agents.json"
    exit 0
}

# Write back
$out = $cfg | ConvertTo-Json -Depth 25
Set-Content -LiteralPath $ConfigPath -Value $out -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Removed: $($removed.Count) agents → $($removed -join ', ')"
if ($skipped.Count) { Write-Host "Skipped (not present): $($skipped -join ', ')" }
Write-Host "Backup: $backup"
Write-Host "Done."
