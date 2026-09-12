#requires -Version 5.1 # PS 5.1 compatible: no &&/||, no modern ternary/?? (mem #767)
<#
.SYNOPSIS
    E2E testing wrapper — simple interactive tests with Playwright

.DESCRIPTION
    Like analyze-page.ps1 but with interactive actions (click, fill, type, etc.)

.PARAMETER Url
    URL to test

.PARAMETER Actions
    Comma-separated actions: click:#selector,fill:#selector=value,wait:#selector

.PARAMETER Analyze
    Run Ollama analysis on final screenshot

.PARAMETER Model
    Ollama model for analysis (default: moondream:latest)

.PARAMETER Screenshot
    Filename for final screenshot (default: e2e-final.png)

.PARAMETER Headed
    Open browser visually (not headless)

.PARAMETER Mode
    Execution mode: visible|headless|smoke|off (default headless).
    visible needs a display; without one it falls back to headless with WARN.
    smoke runs node-only e2e/dashboard.smoke.js (no browser). off skips all.

.PARAMETER EvidenceDir
    Directory where screenshots/traces/evidence are stored (default test-results).

.EXAMPLE
    .\e2e-test.ps1 -Url "http://localhost:3000" -Actions "click:#login,fill:#email=user@test.com"

.EXAMPLE
    .\e2e-test.ps1 -Url "http://localhost:3000" -Actions "click:#login" -Analyze

.EXAMPLE
    .\e2e-test.ps1 -Url "http://localhost:3000" -Actions "click:#login" -Headed
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [Parameter(Mandatory = $false)]
    [string]$Actions = '',

    [switch]$Analyze,

    [string]$Model = 'moondream:latest',

    [string]$Screenshot = 'e2e-final.png',

    [int]$Timeout = 30000,

    # Display mode switch (legacy flag; -Mode visible is the preferred equivalent).
    [switch]$Headed,
    [switch]$Quiet,
    [switch]$Json,

    # Execution mode: visible = headed browser, headless = no UI,
    # smoke = node-only e2e/dashboard.smoke.js (no browser), off = skip all.
    [ValidateSet('visible', 'headless', 'smoke', 'off')]
    [string]$Mode = 'headless',

    # Directory where screenshots/traces/evidence are stored for CI artifact upload.
    [string]$EvidenceDir = 'test-results'
)

if ($Quiet -or $Json) { $null = $Quiet; $null = $Json }
Set-StrictMode -Version Latest

# Make native (node) non-zero exits observable as terminating errors in PS 7.3+.
# Guarded: the variable does not exist in PS 5.1, where the explicit
# exit $LASTEXITCODE at the bottom propagates node's code instead.
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSNativeCommandUseErrorActionPreference = $true
}

$ErrorActionPreference = 'Stop'

# Resolve script path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$jsScript = Join-Path $scriptDir 'e2e-test.js'

if (-not (Test-Path $jsScript)) {
    Write-Error "e2e-test.js not found at: $jsScript"
    exit 1
}

# Mode off: skip everything (commit-verde gate fast path).
if ($Mode -eq 'off') {
    Write-Host "E2E skipped (-Mode off)."
    exit 0
}

# Smoke mode: node-only assertions, no browser required.
if ($Mode -eq 'smoke') {
    $repoRoot = Split-Path -Parent $scriptDir
    $smokeScript = Join-Path $repoRoot 'e2e/dashboard.smoke.js'
    if (-not (Test-Path $smokeScript)) {
        Write-Warning "E2E smoke skipped (e2e/dashboard.smoke.js not found)."
        exit 0
    }
    Write-Host "=== E2E Smoke (no browser) ===" -ForegroundColor Cyan
    try {
        & node $smokeScript
    } catch {
        Write-Error "E2E smoke failed: $_"
        exit 1
    }
    exit $LASTEXITCODE
}

# Visible mode needs a display: check $env:DISPLAY (Linux CI) or video
# controller via Get-CimInstance (Windows). Without one, fall back to headless.
$effectiveMode = $Mode
if (($Mode -eq 'visible') -and (-not $Headed)) {
    # -Mode visible implies headed even without the legacy switch.
    $Headed = $true
}
if ($Headed) {
    $effectiveMode = 'visible'
}
if ($effectiveMode -eq 'visible') {
    $hasDisplay = $false
    if ($env:DISPLAY) {
        $hasDisplay = $true
    } else {
        try {
            $video = Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop
            if ($video) {
                $hasDisplay = $true
            }
        } catch {
            $hasDisplay = $false
        }
    }
    if (-not $hasDisplay) {
        Write-Warning "No display detected — falling back from visible to headless."
        $effectiveMode = 'headless'
        $Headed = $false
    }
}

# No Playwright browser available: fall back to smoke (node-only) with WARN.
# Mirrors the pre-commit gate check (node -e require('playwright')).
$hasBrowser = $false
try {
    node -e "require('playwright')" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $hasBrowser = $true
    }
} catch {
    $hasBrowser = $false
}
if (-not $hasBrowser) {
    Write-Warning "Playwright browser not found — falling back to smoke (node e2e/dashboard.smoke.js)."
    $repoRoot = Split-Path -Parent $scriptDir
    $smokeScript = Join-Path $repoRoot 'e2e/dashboard.smoke.js'
    if (-not (Test-Path $smokeScript)) {
        Write-Warning "E2E smoke skipped (e2e/dashboard.smoke.js not found)."
        exit 0
    }
    try {
        & node $smokeScript
    } catch {
        Write-Error "E2E smoke fallback failed: $_"
        exit 1
    }
    exit $LASTEXITCODE
}

# Evidence directory: screenshots/traces land here for CI artifact upload.
if ($EvidenceDir) {
    if (-not (Test-Path $EvidenceDir)) {
        New-Item -ItemType Directory -Path $EvidenceDir | Out-Null
    }
}
if ($Screenshot) {
    if (-not [System.IO.Path]::IsPathRooted($Screenshot)) {
        if ($EvidenceDir) {
            $Screenshot = Join-Path $EvidenceDir $Screenshot
        }
    }
}

# Align playwright.config.js (E2E_MODE: visible|headless|smoke) with the effective mode.
if (($effectiveMode -eq 'visible') -or ($effectiveMode -eq 'headless')) {
    $env:E2E_MODE = $effectiveMode
}

# Build arguments
$nodeArgs = @($jsScript, '--url', $Url)

if ($Actions) {
    $nodeArgs += '--actions'
    $nodeArgs += $Actions
}

if ($Analyze) {
    $nodeArgs += '--analyze'
    $nodeArgs += '--model'
    $nodeArgs += $Model
}

if ($Screenshot) {
    $nodeArgs += '--screenshot'
    $nodeArgs += $Screenshot
}

if ($Timeout) {
    $nodeArgs += '--timeout'
    $nodeArgs += $Timeout.ToString()
}

if ($Headed) {
    $nodeArgs += '--headed'
}

# Execute
Write-Host "=== E2E Test ===" -ForegroundColor Cyan
Write-Host "URL: $Url"
Write-Host "Actions: $Actions"
Write-Host ""

try {
    & node @nodeArgs
} catch {
    Write-Error "E2E test failed: $_"
    exit 1
}

# Belt and suspenders: propagate node's real exit code (PS 5.1 has no
# $PSNativeCommandUseErrorActionPreference, so a non-zero node exit falls
# through to here instead of the catch).
exit $LASTEXITCODE
