#requires -Version 7.6
<#
.SYNOPSIS
    Gentleman-ize any project — one command to inherit MCPs, agents, skills, and SDD pipeline.

.DESCRIPTION
    Bootstraps a project directory with gentleman-vMK as default agent.
    Skills, scripts, AGENTS.md, and MCPs are inherited from the global config
    (synced by sync-global.ps1 or setup-machine.ps1).

    Call from any project directory:
      .\scripts\use-gentleman.ps1
      .\scripts\use-gentleman.ps1 -TargetDir ..\my-other-project -DefaultAgent gentleman-quick

.PARAMETER TargetDir
    Project directory to gentleman-ize. Defaults to current directory.

.PARAMETER DefaultAgent
    Agent to set as default. Default: gentleman-vMK. Options: gentleman-vMK, gentleman-deep,
    gentleman-codex, gentleman-quick.

.PARAMETER Json
    Output JSON report instead of human-readable text.

.PARAMETER Yes
    Non-interactive — skip confirmation prompts.

.EXAMPLE
    .\scripts\use-gentleman.ps1
    Gentleman-izes the current directory.

.EXAMPLE
    .\scripts\use-gentleman.ps1 -TargetDir ..\my-api -DefaultAgent gentleman-quick
    Sets up my-api with gentleman-quick as default.

.EXAMPLE
    .\scripts\use-gentleman.ps1 -Json -Yes
    Silent JSON output for CI/scripting.
#>
param(
    [string]$TargetDir = (Get-Location).Path,
    [ValidateSet("gentleman-vMK","gentleman-deep","gentleman-codex","gentleman-quick")]
    [string]$DefaultAgent = "gentleman-vMK",
    [switch]$Json,
    [switch]$Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Paths ────────────────────────────────────────────────────────────
$globalCfgDir   = "$env:USERPROFILE\.config\opencode"
$globalCfgFile  = "$globalCfgDir\opencode.json"
$globalSkills   = "$globalCfgDir\skills"
$projectCfgFile = "$TargetDir\opencode.json"
$repoRoot       = Split-Path -Path $PSScriptRoot -Parent

function Write-Step($name, $scriptBlock) {
    try { & $scriptBlock; return $true } catch { Write-Warning "  [FAIL] $name — $_"; return $false }
}

function Out-Message($msg, $color) {
    if (-not $Json) { Write-Host $msg -ForegroundColor $color }
}

# ── Resolve target dir ───────────────────────────────────────────────
$TargetDir = [System.IO.Path]::GetFullPath($TargetDir)
if (-not (Test-Path $TargetDir -PathType Container)) {
    if (-not $Yes) {
        $resp = Read-Host "Directory '$TargetDir' doesn't exist. Create it? [Y/n]"
        if ($resp -eq 'n' -or $resp -eq 'N') { throw "Aborted by user" }
    }
    New-Item -ItemType Directory -Path $TargetDir -ErrorAction Stop | Out-Null
    Out-Message "  Created $TargetDir" -color Green
}

# ── 1. Verify global config ─────────────────────────────────────────
Out-Message "==> Gentleman Portability — $TargetDir" -color Cyan

$globalOk = $true

# Check skills junction
if (-not (Test-Path "$globalSkills\gentleman-vMK\SKILL.md" -PathType Leaf)) {
    Out-Message "  [warn] Global skills junction not found. Run setup-machine.ps1 first." -color Yellow
    $globalOk = $false
}

# Check global config has gentleman agents
if (Test-Path $globalCfgFile -PathType Leaf) {
    try {
        $cfg = Get-Content $globalCfgFile -Raw | ConvertFrom-Json
        $hasGentleman = $null -ne ($cfg.agent.PSObject.Properties['gentleman-vMK'])
        if (-not $hasGentleman) {
            Out-Message "  [warn] gentleman-vMK not in global config. Run sync-global.ps1." -color Yellow
            $globalOk = $false
        }
    } catch {
        Out-Message "  [warn] Global config unreadable: $_" -color Yellow
        $globalOk = $false
    }
} else {
    Out-Message "  [warn] No global opencode.json. Run setup-machine.ps1." -color Yellow
    $globalOk = $false
}

if (-not $globalOk) {
    $repoSetup = Join-Path $repoRoot "scripts\setup-machine.ps1"
    if (Test-Path $repoSetup) {
        Out-Message "  -> Fixing by running setup-machine.ps1..." -color Cyan
        & $repoSetup -RepoDir $repoRoot -Yes:$Yes
        # Re-check after fix
        $cfg = Get-Content $globalCfgFile -Raw | ConvertFrom-Json
        $globalOk = $true
    } else {
        throw "Global gentleman setup incomplete. Clone gentleman-agent-gh and run setup-machine.ps1 first."
    }
}

# ── 2. Create or update project opencode.json ────────────────────────
$projectCfg = @{}
if (Test-Path $projectCfgFile -PathType Leaf) {
    try {
        $existing = Get-Content $projectCfgFile -Raw | ConvertFrom-Json
        $existing.PSObject.Properties | ForEach-Object { $projectCfg[$_.Name] = $_.Value }
    } catch {
        Out-Message "  [warn] Existing config unreadable, overwriting" -color Yellow
    }
}

# Ensure minimal setup: default_agent + $schema
$currentSchema = $projectCfg['$schema']
if (-not $projectCfg.ContainsKey('$schema') -or $currentSchema -isnot [string] -or [string]::IsNullOrEmpty($currentSchema)) {
    $projectCfg['$schema'] = "https://opencode.ai/config.json"
}
$projectCfg['default_agent'] = $DefaultAgent

# Inherit MCPs from global if project has none
$hasMcp = $projectCfg.ContainsKey('mcp') -and @($projectCfg['mcp'].PSObject.Properties).Count -gt 0
if (-not $hasMcp -and $cfg.mcp) {
    $projectCfg['mcp'] = $cfg.mcp
}

# Inherit permissions from global if project has none
$hasPermissions = $projectCfg.ContainsKey('permission') -and @($projectCfg['permission'].PSObject.Properties).Count -gt 0
if (-not $hasPermissions -and $cfg.permission) {
    $projectCfg['permission'] = $cfg.permission
}

$projectCfg | ConvertTo-Json -Depth 10 | Set-Content $projectCfgFile -Encoding UTF8 -Force
Out-Message "  Created $projectCfgFile" -color Green
Out-Message "    default_agent: $DefaultAgent" -color DarkGray
Out-Message "    MCPs inherited from global: $(if($hasMcp){'project own'}else{'yes'})" -color DarkGray

# ── 3. Verify end-to-end ─────────────────────────────────────────────
$verifyOk = $true
try {
    $check = Get-Content $projectCfgFile -Raw | ConvertFrom-Json
    if ($check.default_agent -ne $DefaultAgent) { throw "default_agent mismatch" }
    Out-Message "  [ok] Config valid, JSON parses correctly" -color Green
} catch {
    Out-Message "  [err] Config verification failed: $_" -color Red
    $verifyOk = $false
}

# ── Report ───────────────────────────────────────────────────────────
$report = @{
    status         = if ($verifyOk) { "ok" } else { "fail" }
    target_dir     = $TargetDir
    default_agent  = $DefaultAgent
    project_config = $projectCfgFile
    global_ok      = $globalOk
    errors         = @()
}

if (-not $verifyOk) { $report.errors += "Config verification failed" }

if ($Json) {
    $report | ConvertTo-Json -Depth 3
} else {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Gentleman Portability Report" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Target  : $TargetDir" -ForegroundColor White
    Write-Host "  Agent   : $DefaultAgent" -ForegroundColor White
    Write-Host "  Status  : $(if($verifyOk){'✅ OK'}else{'❌ FAIL'})" -ForegroundColor $(if($verifyOk){'Green'}else{'Red'})
    Write-Host ""
    Write-Host "  To use: cd $TargetDir && opencode" -ForegroundColor Cyan
    Write-Host "  Skills : $globalSkills (junction, auto-synced)" -ForegroundColor DarkGray
    Write-Host "  MCPs   : Inherited from global config" -ForegroundColor DarkGray
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
}
