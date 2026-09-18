<#
.SYNOPSIS
    Switch between Zen (free) and Go (contributor) model profiles for opencode.json.
.DESCRIPTION
    Applies model overlays from profile JSON files to opencode.json agent.<name>.model fields.
    Uses sidecar marker (.opencode-profile) to track current profile.
    Never modifies the SSoT chain — only touches agent.<name>.model per overlay mapping.
.PARAMETER Profile
    Target profile: 'zen' (free) or 'go' (contributor).
.PARAMETER Status
    Show current active profile without making changes.
.PARAMETER Help
    Show this help message.
.PARAMETER Force
    Skip dirty-tree pre-flight check and proceed anyway.
.PARAMETER DryRun
    List changes without writing to opencode.json.
.PARAMETER Quiet
    Suppress informational output.
.PARAMETER Json
    Output results as JSON instead of text.
.EXAMPLE
    .\switch-profile.ps1 -Status
    .\switch-profile.ps1 -Profile go -DryRun -Json
    .\switch-profile.ps1 -Profile zen -Force
#>
#Requires -Version 7

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [ValidateSet('zen', 'go')]
    [string]$Profile,

    [switch]$Status,

    [switch]$Help,

    [switch]$Force,

    [switch]$DryRun,

    [switch]$Quiet,

    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Resolve project root ---
function Get-GentlemanProjectRoot {
    $root = $env:GENTLEMAN_AGENT_ROOT
    if ($root -and (Test-Path $root)) { return $root }
    # Fallback: walk up from script location
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if (-not $scriptDir) { $scriptDir = $PSScriptRoot }
    $candidate = $scriptDir
    while ($candidate -and $candidate -ne (Split-Path -Qualifier $candidate)) {
        if (Test-Path (Join-Path $candidate 'opencode.json')) { return $candidate }
        $candidate = Split-Path -Parent $candidate
    }
    throw "Cannot resolve gentleman project root. Set GENTLEMAN_AGENT_ROOT or run from repo."
}

$ProjectRoot = Get-GentlemanProjectRoot
$OpencodeJsonPath = Join-Path $ProjectRoot 'opencode.json'
$MarkerPath = Join-Path $ProjectRoot '.opencode-profile'
$ProfilesDir = Join-Path $ProjectRoot 'scripts' 'opencode-configs'
$GoProfilePath = Join-Path $ProfilesDir 'profile-go.json'
$ZenProfilePath = Join-Path $ProfilesDir 'profile-zen.json'

# --- Profile file map ---
$ProfileFiles = @{
    'go'  = $GoProfilePath
    'zen' = $ZenProfilePath
}

# --- Expected counts per profile ---
$ExpectedCounts = @{
    'go'  = 17   # 12 deepseek→contributor + 5 mimo→contributor
    'zen' = 19   # 14 go-paid→free + 5 already-free (kept for consistency) + 2 qwen→free
}

# --- Help ---
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Definition -Full
    return
}

# --- Status ---
if ($Status) {
    $currentProfile = 'unknown'
    if (Test-Path $MarkerPath) {
        $markerContent = (Get-Content $MarkerPath -Raw).Trim()
        if ($markerContent -in @('zen', 'go')) {
            $currentProfile = $markerContent
        }
    }
    # Fallback: audit current opencode.json counts
    if ($currentProfile -eq 'unknown' -and (Test-Path $OpencodeJsonPath)) {
        try {
            $config = Get-Content $OpencodeJsonPath -Raw | ConvertFrom-Json
            $agentKeys = @($config.agent.PSObject.Properties.Name)
            $subagentKeys = $agentKeys | Where-Object { $_ -match '-sub(-auto)?$' }
            $freeCount = ($subagentKeys | Where-Object {
                $model = $config.agent.$_.model
                $model -and $model -match 'contributor-free$'
            }).Count
            $total = $subagentKeys.Count
            if ($freeCount -ge 19) { $currentProfile = 'zen' }
            elseif ($freeCount -le 5) { $currentProfile = 'go' }
        } catch { }
    }
    if ($Json) {
        @{ profile = $currentProfile; marker_exists = (Test-Path $MarkerPath) } | ConvertTo-Json -Compress
    } else {
        if ($currentProfile -eq 'unknown') {
            Write-Host "Current profile: UNKNOWN (no sidecar marker, could not audit)" -ForegroundColor Yellow
        } else {
            Write-Host "Current profile: $currentProfile" -ForegroundColor Green
        }
    }
    return
}

# --- Require Profile if not Status/Help ---
if (-not $Profile) {
    throw "Parameter -Profile is required. Use -Profile zen or -Profile go. See -Help."
}

# --- Pre-flight checks ---
# 1. Profile overlay exists
$overlayPath = $ProfileFiles[$Profile]
if (-not (Test-Path $overlayPath)) {
    throw "Profile overlay not found: $overlayPath"
}

# 2. opencode.json exists
if (-not (Test-Path $OpencodeJsonPath)) {
    throw "opencode.json not found at: $OpencodeJsonPath"
}

# 3. JSON parseable
try {
    $config = Get-Content $OpencodeJsonPath -Raw | ConvertFrom-Json
} catch {
    throw "opencode.json is not valid JSON: $_"
}

# 4. Dirty tree check
if (-not $Force) {
    $gitStatus = & git -C $ProjectRoot status --porcelain opencode.json 2>&1
    $gitStatusStr = if ($gitStatus -is [string]) { $gitStatus } elseif ($gitStatus -is [System.Management.Automation.ErrorRecord]) { '' } else { "$gitStatus" }
    if ($gitStatusStr -and $gitStatusStr.Trim()) {
        throw "opencode.json is dirty in git. Use -Force to override, or stash/commit first."
    }
}

# --- Idempotency: detect current profile ---
$currentProfile = 'unknown'
if (Test-Path $MarkerPath) {
    $markerContent = (Get-Content $MarkerPath -Raw).Trim()
    if ($markerContent -in @('zen', 'go')) {
        $currentProfile = $markerContent
    }
}
if ($currentProfile -eq $Profile -and -not $Force) {
    if ($Quiet) { return }
    if ($Json) {
        @{ profile = $Profile; changed = @(); counts = @{}; backup = $null; dry_run = $DryRun.IsPresent; message = "Already on profile '$Profile'" } | ConvertTo-Json -Compress
    } else {
        Write-Host "Already on profile '$Profile'. No changes needed. Use -Force to re-apply." -ForegroundColor Cyan
    }
    return
}

# --- Load overlay ---
$overlay = Get-Content $overlayPath -Raw | ConvertFrom-Json
$mapping = $overlay.mapping

# --- Build change list ---
$changes = @()
$agentProps = $config.agent.PSObject.Properties
foreach ($prop in $agentProps) {
    $agentName = $prop.Name
    $agentObj = $prop.Value
    if ($mapping.PSObject.Properties[$agentName]) {
        $newModel = $mapping.$agentName
        $oldModel = $agentObj.model
        if ($oldModel -ne $newModel) {
            $changes += [PSCustomObject]@{
                agent = $agentName
                from  = $oldModel
                to    = $newModel
            }
        }
    }
}

# --- DryRun ---
if ($DryRun) {
    if ($Json) {
        @{
            profile  = $Profile
            changed  = $changes
            counts   = @{ expected = $ExpectedCounts[$Profile]; actual = $changes.Count }
            backup   = $null
            dry_run  = $true
            message  = "Dry run — no changes written"
        } | ConvertTo-Json -Depth 5
    } else {
        Write-Host "`n=== Dry Run: Profile '$Profile' ===" -ForegroundColor Cyan
        Write-Host "Changes that would be applied ($($changes.Count) agents):" -ForegroundColor Yellow
        foreach ($c in $changes) {
            Write-Host "  $($c.agent): $($c.from) → $($c.to)" -ForegroundColor White
        }
        Write-Host "`nExpected total changes: $($ExpectedCounts[$Profile])" -ForegroundColor Gray
    }
    return
}

# --- Backup ---
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupName = "opencode.json.bak-$Profile-$timestamp"
$backupPath = Join-Path $ProjectRoot $backupName

# --- Apply changes via ShouldProcess ---
if ($PSCmdlet.ShouldProcess($OpencodeJsonPath, "Apply $Profile profile ($($changes.Count) model overrides)")) {
    # Create backup
    Copy-Item -LiteralPath $OpencodeJsonPath -Destination $backupPath -Force
    if (-not $Quiet) {
        Write-Host "Backup: $backupName" -ForegroundColor Gray
    }

    # Apply model overrides
    foreach ($change in $changes) {
        $config.agent.($change.agent).model = $change.to
    }

    # Write back
    $config | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OpencodeJsonPath -Encoding UTF8

    # Post-write validation
    try {
        $verify = Get-Content $OpencodeJsonPath -Raw | ConvertFrom-Json
        $verifyAgentKeys = @($verify.agent.PSObject.Properties.Name)
        $verifySubagentKeys = $verifyAgentKeys | Where-Object { $_ -match '-sub(-auto)?$' }
        $verifyFreeCount = ($verifySubagentKeys | Where-Object {
            $m = $verify.agent.$_.model
            $m -and $m -match 'contributor-free$'
        }).Count
        if ($Profile -eq 'zen' -and $verifyFreeCount -lt 19) {
            Write-Warning "Post-write validation: expected >= 19 zen-free agents, found $verifyFreeCount"
        }
    } catch {
        Write-Warning "Post-write JSON validation failed: $_"
    }

    # Write sidecar marker
    $Profile | Set-Content -LiteralPath $MarkerPath -Encoding UTF8 -Force

    if ($Json) {
        @{
            profile  = $Profile
            changed  = $changes
            counts   = @{ expected = $ExpectedCounts[$Profile]; actual = $changes.Count }
            backup   = $backupName
            dry_run  = $false
            message  = "Applied profile '$Profile' successfully"
        } | ConvertTo-Json -Depth 5
    } else {
        Write-Host "`n=== Applied Profile: $Profile ===" -ForegroundColor Green
        Write-Host "Changes applied: $($changes.Count) agents" -ForegroundColor White
        foreach ($c in $changes) {
            Write-Host "  $($c.agent): $($c.from) → $($c.to)" -ForegroundColor DarkGreen
        }
        Write-Host "Backup: $backupName" -ForegroundColor Gray
        Write-Host "Marker: .opencode-profile → $Profile" -ForegroundColor Gray
    }
}
