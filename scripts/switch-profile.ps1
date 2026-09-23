#requires -Version 7
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
.PARAMETER ProjectRoot
    Override the project root (where opencode.json + scripts/opencode-configs live)
    instead of resolving via $env:GENTLEMAN_AGENT_ROOT / walk-up. Used by hermetic
    test fixtures; default resolution is unchanged when omitted.
.EXAMPLE
    .\switch-profile.ps1 -Status
    .\switch-profile.ps1 -Profile go -DryRun -Json
    .\switch-profile.ps1 -Profile zen -Force
#>

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

    [switch]$Json,

    [Parameter()]
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Resolve project root ---
function Get-GentlemanProjectRoot {
    # Explicit -ProjectRoot override wins (hermetic fixtures; no env dependence)
    if ($ProjectRoot) {
        if (Test-Path $ProjectRoot) { return (Resolve-Path $ProjectRoot).Path }
        throw "ProjectRoot not found: $ProjectRoot"
    }
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
    'go'  = 19   # 12 deepseek→contributor + 5 mimo→contributor + 2 qwen→contributor
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

# 4. Dirty tree check (opencode.json + profile JSONs)
if (-not $Force) {
    $dirtyTargets = @('opencode.json', 'scripts/opencode-configs/profile-go.json', 'scripts/opencode-configs/profile-zen.json')
    $dirtyFiles = @()
    foreach ($target in $dirtyTargets) {
        $gitStatus = & git -C $ProjectRoot status --porcelain $target 2>&1
        $gitStatusStr = if ($gitStatus -is [string]) { $gitStatus } elseif ($gitStatus -is [System.Management.Automation.ErrorRecord]) { '' } else { "$gitStatus" }
        if ($gitStatusStr -and $gitStatusStr.Trim()) {
            $dirtyFiles += $target
        }
    }
    if ($dirtyFiles.Count -gt 0) {
        throw "Dirty files in git: $($dirtyFiles -join ', '). Use -Force to override, or stash/commit first."
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
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$backupBase = "opencode.json.bak-$Profile-$timestamp"
$backupPath = Join-Path $ProjectRoot $backupBase
# Prevent collision: if name exists (extremely unlikely with ms), append incremental suffix
$suffix = 1
while (Test-Path $backupPath) {
    $backupPath = Join-Path $ProjectRoot "$backupBase-$suffix"
    $suffix++
}
$backupName = Split-Path -Leaf $backupPath

# --- Scoped agent-object span locator (minified-JSON safe) ---
# Finds the byte span of "<agentName>":{ ... } on the raw text by brace-depth
# scanning (string-aware), so replacement never leaks outside the agent object.
function Get-AgentObjectSpan {
    param(
        [string]$Raw,
        [string]$AgentName
    )
    $needle = '"' + $AgentName + '":{'
    $start = $Raw.IndexOf($needle, [StringComparison]::Ordinal)
    if ($start -lt 0) { return $null }
    $objStart = $start + $needle.Length - 1
    $depth = 0
    $inString = $false
    $escaped = $false
    for ($i = $objStart; $i -lt $Raw.Length; $i++) {
        $ch = $Raw[$i]
        if ($inString) {
            if ($escaped) { $escaped = $false }
            elseif ($ch -eq '\') { $escaped = $true }
            elseif ($ch -eq '"') { $inString = $false }
        } else {
            if ($ch -eq '"') { $inString = $true }
            elseif ($ch -eq '{') { $depth++ }
            elseif ($ch -eq '}') {
                $depth--
                if ($depth -eq 0) {
                    return @{ Start = $objStart; End = $i }
                }
            }
        }
    }
    return $null
}

# --- Apply changes via ShouldProcess ---
if ($PSCmdlet.ShouldProcess($OpencodeJsonPath, "Apply $Profile profile ($($changes.Count) model overrides)")) {
    $backupCreated = $null

    if ($changes.Count -gt 0) {
        # --- Allowlist validation: verify every overlay entry ---
        $allowedModels = @(
            'opencode-go/muse-spark-1.3-contributor',
            'opencode/muse-spark-1.3-contributor-free'
        )
        $agentKeyRegex = '^gentleman-[a-z0-9-]+-sub(-auto)?$'
        foreach ($prop in $mapping.PSObject.Properties) {
            if ($prop.Name -notmatch $agentKeyRegex) {
                throw "ALLOWLIST REJECTED: overlay key '$($prop.Name)' does not match $agentKeyRegex"
            }
            if ($prop.Value -notin $allowedModels) {
                throw "ALLOWLIST REJECTED: model '$($prop.Value)' for agent '$($prop.Name)' is not in allowed list: $($allowedModels -join ', ')"
            }
        }

        # Create backup
        Copy-Item -LiteralPath $OpencodeJsonPath -Destination $backupPath -Force
        $backupCreated = $backupName
        if (-not $Quiet) {
            Write-Host "Backup: $backupName" -ForegroundColor Gray
        }

        # Apply model overrides — scoped raw-text replacement (minified-JSON safe).
        # Locates the agent object span ("<agent>":{ ... }) and replaces the FIRST
        # "model":"..." inside it, preserving every other byte (no reformatting).
        # Fail-closed: throws if any expected replacement cannot be applied.
        $rawContent = [System.IO.File]::ReadAllText($OpencodeJsonPath) -replace "`r`n", "`n"
        $applied = 0
        foreach ($change in $changes) {
            $span = Get-AgentObjectSpan -Raw $rawContent -AgentName $change.agent
            if ($null -eq $span) {
                throw "APPLY FAILED: agent object '$($change.agent)' not found in opencode.json"
            }
            $spanText = $rawContent.Substring($span.Start, $span.End - $span.Start + 1)
            $modelMatch = [regex]::Match($spanText, '"model":"([^"]*)"')
            if (-not $modelMatch.Success) {
                throw "APPLY FAILED: no model key found in agent object '$($change.agent)'"
            }
            $oldValue = $modelMatch.Groups[1].Value
            if ($oldValue -ne $change.from) {
                throw "APPLY FAILED: agent '$($change.agent)' expected current model '$($change.from)' but raw text has '$oldValue'"
            }
            $newSpanText = $spanText.Substring(0, $modelMatch.Index) + '"model":"' + $change.to + '"' + $spanText.Substring($modelMatch.Index + $modelMatch.Length)
            $rawContent = $rawContent.Substring(0, $span.Start) + $newSpanText + $rawContent.Substring($span.End + 1)
            $applied++
        }
        if ($applied -ne $changes.Count) {
            throw "APPLY FAILED: expected $($changes.Count) replacements, applied $applied"
        }
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($OpencodeJsonPath, $rawContent, $utf8NoBom)

        # Post-write validation — FAIL-CLOSED gate (throw on mismatch, no silent warnings)
        $verify = Get-Content $OpencodeJsonPath -Raw | ConvertFrom-Json
        $verifyAgentKeys = @($verify.agent.PSObject.Properties.Name)
        $verifySubagentKeys = $verifyAgentKeys | Where-Object { $_ -match '-sub(-auto)?$' }
        $verifyFreeCount = @($verifySubagentKeys | Where-Object {
            $m = $verify.agent.$_.model
            $m -and $m -match 'contributor-free$'
        }).Count
        $verifyContributorCount = @($verifySubagentKeys | Where-Object {
            $m = $verify.agent.$_.model
            $m -and $m -match 'muse-spark-1\.3-contributor$'
        }).Count
        $verifyDeepseekCount = @($verifySubagentKeys | Where-Object {
            $m = $verify.agent.$_.model
            $m -and $m -match 'deepseek'
        }).Count
        $verifyMimoCount = @($verifySubagentKeys | Where-Object {
            $m = $verify.agent.$_.model
            $m -and $m -match 'mimo'
        }).Count
        $verifyQwenCount = @($verifySubagentKeys | Where-Object {
            $m = $verify.agent.$_.model
            $m -and $m -match 'qwen'
        }).Count
        if ($Profile -eq 'zen' -and $verifyFreeCount -lt 19) {
            throw "Post-write validation FAILED: expected >= 19 zen-free agents, found $verifyFreeCount"
        }
        if ($Profile -eq 'go') {
            if ($verifyDeepseekCount -ne 0) {
                throw "Post-write validation FAILED: expected 0 deepseek-sub agents for Go, found $verifyDeepseekCount"
            }
            if ($verifyMimoCount -ne 0) {
                throw "Post-write validation FAILED: expected 0 mimo-sub agents for Go, found $verifyMimoCount"
            }
            if ($verifyQwenCount -ne 0) {
                throw "Post-write validation FAILED: expected 0 qwen-sub agents for Go, found $verifyQwenCount"
            }
            # 5 subs intentionally free-tier (quick/frontend/datascience/docs/quick-auto) per JD pto 1 + cost proposal
            if ($verifyContributorCount -lt 19) {
                throw "Post-write validation FAILED: expected >= 19 muse-spark-contributor-sub agents for Go, found $verifyContributorCount"
            }
        }
    }

    # Write sidecar marker (idempotent — safe even when 0 changes)
    $Profile | Set-Content -LiteralPath $MarkerPath -Encoding UTF8 -Force

    if ($Json) {
        @{
            profile  = $Profile
            changed  = $changes
            counts   = @{ expected = $ExpectedCounts[$Profile]; actual = $changes.Count }
            backup   = $backupCreated
            dry_run  = $false
            message  = if ($changes.Count -gt 0) { "Applied profile '$Profile' successfully" } else { "Already on profile '$Profile' — no changes needed" }
        } | ConvertTo-Json -Depth 5
    } else {
        if ($changes.Count -gt 0) {
            Write-Host "`n=== Applied Profile: $Profile ===" -ForegroundColor Green
            Write-Host "Changes applied: $($changes.Count) agents" -ForegroundColor White
            foreach ($c in $changes) {
                Write-Host "  $($c.agent): $($c.from) → $($c.to)" -ForegroundColor DarkGreen
            }
            Write-Host "Backup: $backupName" -ForegroundColor Gray
        } else {
            Write-Host "Already on profile '$Profile' — no changes needed." -ForegroundColor Cyan
        }
        Write-Host "Marker: .opencode-profile → $Profile" -ForegroundColor Gray
    }
}
