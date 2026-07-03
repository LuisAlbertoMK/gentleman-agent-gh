#requires -Version 7.0
<#
.SYNOPSIS
    Gentleman Agent — One-shot machine setup for portability
.DESCRIPTION
    Sets up a new machine after cloning gentleman-agent-gh:
    - Creates global shell shortcuts (opencode-vmk, gentleman-vmk)
    - Sets GENTLEMAN_AGENT_ROOT environment variable
    - Configures OpenCode env vars
    - Creates skill junction in global config
    - Verifies everything works
.PARAMETER RepoDir
    Path to the cloned gentleman-agent-gh repo (default: current dir)
.PARAMETER SkipEnvVar
    Skip persistent env var registration (for containers/CI)
.PARAMETER SkipShortcuts
    Skip global shell shortcut creation
.EXAMPLE
    # From inside the cloned repo:
    .\scripts\setup-machine.ps1

    # From anywhere:
    .\scripts\setup-machine.ps1 -RepoDir D:\gentleman-agent-gh
#>
param(
    [string]$RepoDir = (Get-Location).Path,
    [switch]$SkipEnvVar,
    [switch]$SkipShortcuts
)

$ErrorActionPreference = "Stop"

# ── Helpers ─────────────────────────────────────────────────────────
function info  { Write-Host "==> " -ForegroundColor Cyan -NoNewline; Write-Host "$args" }
function ok    { Write-Host "[ok] " -ForegroundColor Green -NoNewline; Write-Host "$args" }
function warn  { Write-Host "[warn] " -ForegroundColor Yellow -NoNewline; Write-Host "$args" }
function err   { Write-Host "[err] " -ForegroundColor Red -NoNewline; Write-Host "$args"; exit 1 }
function skip  { Write-Host "[skip] " -ForegroundColor DarkGray -NoNewline; Write-Host "$args" }

# ── Validate repo ───────────────────────────────────────────────────
info "Validating repo at $RepoDir"
$requiredFiles = @("opencode.json", "AGENTS.md", ".agents/skills")
foreach ($f in $requiredFiles) {
    $path = Join-Path $RepoDir $f
    if (-not (Test-Path $path)) { err "Missing $f — is $RepoDir the gentleman-agent-gh repo?" }
}
ok "Repo structure validated"

# ── Step 1: GENTLEMAN_AGENT_ROOT ────────────────────────────────────
if (-not $SkipEnvVar) {
    info "Setting GENTLEMAN_AGENT_ROOT → $RepoDir"
    # Current session
    $env:GENTLEMAN_AGENT_ROOT = $RepoDir
    # Persistent (user-level)
    $current = [Environment]::GetEnvironmentVariable("GENTLEMAN_AGENT_ROOT", "User")
    if ($current -ne $RepoDir) {
        [Environment]::SetEnvironmentVariable("GENTLEMAN_AGENT_ROOT", $RepoDir, "User")
        ok "GENTLEMAN_AGENT_ROOT set (takes effect in new shells)"
    } else {
        skip "GENTLEMAN_AGENT_ROOT already set correctly"
    }
} else {
    skip "GENTLEMAN_AGENT_ROOT (via -SkipEnvVar)"
}

# ── Step 2: OpenCode env vars ──────────────────────────────────────
info "Setting OpenCode environment variables"
$ocVars = @{
    "OPENCODE_CACHE_DIR"              = "$RepoDir\.vmk-cache"
    "OPENCODE_CONFIG_DIR"             = "$RepoDir\.vmk-config"
    "OPENCODE_DB"                     = "$RepoDir\.vmk-data\opencode.db"
    "OPENCODE_DISABLE_EMBEDDED_WEB_UI" = "true"
    "OPENCODE_DISABLE_MODELS_FETCH"    = "true"
    "OPENCODE_EXPERIMENTAL_DISABLE_FILEWATCHER" = "true"
}
foreach ($kv in $ocVars.GetEnumerator()) {
    $current = [Environment]::GetEnvironmentVariable($kv.Key, "User")
    if ($current -ne $kv.Value) {
        [Environment]::SetEnvironmentVariable($kv.Key, $kv.Value, "User")
        Set-Item -Path "env:$($kv.Key)" -Value $kv.Value
        ok "$($kv.Key) set"
    } else {
        skip "$($kv.Key) already set"
    }
}

# ── Step 3: Global shortcuts ───────────────────────────────────────
if (-not $SkipShortcuts) {
    info "Creating global shell shortcuts"
    $npmDir = "$env:APPDATA\npm"
    if (-not (Test-Path $npmDir)) { New-Item -ItemType Directory -Path $npmDir -Force | Out-Null }

    $shortcuts = @(
        @{ Name = "opencode-vmk"; Cmd = "opencode --agent gentleman-vMK `$*" },
        @{ Name = "gentleman-vmk"; Cmd = "opencode --agent gentleman-vMK `$*" }
    )
    foreach ($sc in $shortcuts) {
        $ps1Path = Join-Path $npmDir "$($sc.Name).ps1"
        $cmdPath = Join-Path $npmDir "$($sc.Name).cmd"
        $needCreate = $false

        if (-not (Test-Path $ps1Path)) {
            Set-Content -Path $ps1Path -Value "# $($sc.Name).ps1`n$($sc.Cmd)`nif (`$LASTEXITCODE -and `$LASTEXITCODE -ne 0) { exit `$LASTEXITCODE }"
            ok "Created $ps1Path"
        } else {
            skip "$ps1Path already exists"
        }

        if (-not (Test-Path $cmdPath)) {
            Set-Content -Path $cmdPath -Value "@echo off`n$($sc.Cmd -replace '\$', '%')"
            ok "Created $cmdPath"
        } else {
            skip "$cmdPath already exists"
        }
    }
} else {
    skip "Global shortcuts (via -SkipShortcuts)"
}

# ── Step 4: Global skill config ────────────────────────────────────
info "Setting up global skill config"
$globalSkillsDir = "$env:USERPROFILE\.config\opencode\skills"
$repoSkillsDir = Join-Path $RepoDir ".agents\skills"
if (-not (Test-Path $globalSkillsDir)) {
    New-Item -ItemType Directory -Path $globalSkillsDir -Force | Out-Null
}
# Check junction or directory exists
if (-not (Test-Path "$globalSkillsDir\_shared")) {
    # Create junction to repo skills
    New-Item -ItemType Junction -Path "$globalSkillsDir" -Target $repoSkillsDir -Force 2>$null
    if ($?) { ok "Skills junction created at $globalSkillsDir" }
    else { warn "Could not create junction (needs admin/elevation). Copy skills manually." }
} else {
    skip "Skills junction already exists"
}

# ── Step 5: Verify ────────────────────────────────────────────────
info "Verifying setup"
$checks = @(
    @{ Label = "GENTLEMAN_AGENT_ROOT"; Test = { $env:GENTLEMAN_AGENT_ROOT -eq $RepoDir } },
    @{ Label = "opencode.json exists"; Test = { Test-Path (Join-Path $RepoDir "opencode.json") } },
    @{ Label = "Global shortcut: opencode-vmk"; Test = { Get-Command "opencode-vmk" -ErrorAction SilentlyContinue } },
    @{ Label = "Global shortcut: gentleman-vmk"; Test = { Get-Command "gentleman-vmk" -ErrorAction SilentlyContinue } }
)
$allOk = $true
foreach ($c in $checks) {
    if (& $c.Test) { ok $c.Label }
    else { warn "$($c.Label) — FAILED"; $allOk = $false }
}

if ($allOk) {
    Write-Host ""
    Write-Host "✅ Machine setup COMPLETE" -ForegroundColor Green
    Write-Host "   → Run 'opencode-vmk' to launch" -ForegroundColor Cyan
    Write-Host "   → Run 'gentleman-vmk' (alias)" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "⚠️  Setup PARTIAL — review warnings above" -ForegroundColor Yellow
}
