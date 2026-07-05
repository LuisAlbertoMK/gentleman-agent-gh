#requires -Version 7.6
<#
.SYNOPSIS
    Gentleman Agent — One-shot machine setup for portability
.DESCRIPTION
    Sets up a new machine after cloning gentleman-agent-gh:
    - Creates global shell shortcuts (gentleman-vmk)
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
Set-StrictMode -Version Latest

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
# Normalize to forward slashes so JSONC `{env:...}` substitution doesn't
# produce invalid JSON escapes (e.g. `\g` in `D:\gentleman-agent-gh/...`)
$__rootDir = $RepoDir.Replace('\', '/')
if (-not $SkipEnvVar) {
    info "Setting GENTLEMAN_AGENT_ROOT → $__rootDir"
    # Current session
    $env:GENTLEMAN_AGENT_ROOT = $__rootDir
    # Persistent (user-level)
    $current = [Environment]::GetEnvironmentVariable("GENTLEMAN_AGENT_ROOT", "User")
    if ($current -ne $__rootDir) {
        [Environment]::SetEnvironmentVariable("GENTLEMAN_AGENT_ROOT", $__rootDir, "User")
        ok "GENTLEMAN_AGENT_ROOT set (takes effect in new shells)"
    } else {
        skip "GENTLEMAN_AGENT_ROOT already set correctly"
    }
} else {
    skip "GENTLEMAN_AGENT_ROOT (via -SkipEnvVar)"
}

# ── Step 2: pre-commit hooks ───────────────────────────────────────
info "Setting up pre-commit framework"
$pc = py -m pre_commit --version 2>$null
if ($pc) {
    ok "pre-commit $pc already installed"
} else {
    info "Installing pre-commit via pip..."
    py -m pip install pre-commit -q 2>$null
    if ($?) { ok "pre-commit installed" } else { warn "pre-commit install failed — CI can run it standalone" }
}
if (-not [string]::IsNullOrEmpty((py -m pre_commit --version 2>$null))) {
    $hooksPath = git config core.hooksPath 2>$null
    if ([string]::IsNullOrEmpty($hooksPath)) {
        py -m pre_commit install 2>$null
        if ($?) { ok "pre-commit hooks installed" } else { warn "pre-commit hooks install failed" }
    } else {
        skip "pre-commit hooks (hooksPath=$hooksPath — managed by OpenCode)"
    }
}

# ── Step 3: OpenCode env vars ──────────────────────────────────────
# NOTE: Do NOT set OPENCODE_CONFIG_DIR/CACHE_DIR/DB here — those would
# override ~\.config\opencode\ and break the global install. OpenCode
# uses its defaults (global config dir) automatically.
info "Setting OpenCode environment variables"
$ocVars = @{
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

# ── Step 4: Global shortcuts ───────────────────────────────────────
if (-not $SkipShortcuts) {
    info "Creating global shell shortcuts"
    $npmDir = "$env:APPDATA\npm"
    if (-not (Test-Path $npmDir)) { New-Item -ItemType Directory -Path $npmDir -Force | Out-Null }

    $shortcuts = @(
        @{ Name = "gentleman-vmk"; Ps1Cmd = "opencode --agent gentleman-vMK @args"; CmdCmd = "opencode --agent gentleman-vMK %*" }
    )
    foreach ($sc in $shortcuts) {
        $ps1Path = Join-Path $npmDir "$($sc.Name).ps1"
        $cmdPath = Join-Path $npmDir "$($sc.Name).cmd"

        if (-not (Test-Path $ps1Path)) {
            Set-Content -Path $ps1Path -Value "# $($sc.Name).ps1`n$($sc.Ps1Cmd)`nif (`$LASTEXITCODE -and `$LASTEXITCODE -ne 0) { exit `$LASTEXITCODE }"
            ok "Created $ps1Path"
        } else {
            skip "$ps1Path already exists"
        }

        if (-not (Test-Path $cmdPath)) {
            Set-Content -Path $cmdPath -Value "@echo off`n$($sc.CmdCmd)"
            ok "Created $cmdPath"
        } else {
            skip "$cmdPath already exists"
        }
    }
} else {
    skip "Global shortcuts (via -SkipShortcuts)"
}

# ── Step 5: Global opencode config ─────────────────────────────────
info "Syncing global opencode config from repo"
$globalConfigPath = "$env:USERPROFILE\.config\opencode\opencode.json"
$repoConfigPath = Join-Path $RepoDir "opencode.json"
if ((Test-Path $globalConfigPath) -and (Test-Path $repoConfigPath)) {
    $globalConfig = Get-Content $globalConfigPath -Raw | ConvertFrom-Json
    $repoConfig = Get-Content $repoConfigPath -Raw | ConvertFrom-Json

    $synced = $false
    # Sync default_agent
    if (-not $globalConfig.default_agent -or $globalConfig.default_agent -ne "gentleman-vMK") {
        $globalConfig | Add-Member -NotePropertyName "default_agent" -NotePropertyValue "gentleman-vMK" -Force
        $synced = $true
    }
    # Sync sections: mcp, permission, skills, agent
    foreach ($section in @("mcp", "permission", "skills", "agent")) {
        $repoValue = $repoConfig.$section
        if ($repoValue) {
            $globalConfig | Add-Member -NotePropertyName $section -NotePropertyValue $repoValue -Force
            $synced = $true
        }
    }
    if ($synced) {
        $globalConfig | ConvertTo-Json -Depth 10 | Set-Content $globalConfigPath
        ok "Global config synced from repo (default_agent + mcp + permission + skills + agent)"
    } else {
        skip "Global config already up to date"
    }
} else {
    warn "Global or repo config not found — sync manually"
}

# ── Step 6: Global skill config ────────────────────────────────────
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

# ── Step 6b: Global prompts junction ────────────────────────────────
# The global config may contain {file:prompts/sdd/*.md} references from agent
# definitions synced in Step 4. Those resolve relative to the global config dir,
# so we need the prompts directory there too.
info "Setting up global prompts junction"
$globalPromptsDir = "$env:USERPROFILE\.config\opencode\prompts"
$repoSddDir = Join-Path $RepoDir "prompts\sdd"
if (Test-Path $repoSddDir) {
    $sddJunction = "$globalPromptsDir\sdd"
    if (-not (Test-Path $sddJunction)) {
        if (-not (Test-Path $globalPromptsDir)) {
            New-Item -ItemType Directory -Path $globalPromptsDir -Force | Out-Null
        }
        New-Item -ItemType Junction -Path $sddJunction -Target $repoSddDir -Force 2>$null
        if ($?) { ok "Prompts junction created at $sddJunction" }
        else { warn "Could not create prompts junction. Copy prompts manually: Copy-Item '$repoSddDir' '$sddJunction' -Recurse" }
    } else {
        skip "Prompts junction already exists"
    }
} else {
    warn "Repo prompts/sdd not found at $repoSddDir"
}

# ── Step 6c: Global AGENTS.md ──────────────────────────────────────
# {file:AGENTS.md} in gentleman-vMK agent prompt resolves relative to global config
$globalAgentsMd = "$env:USERPROFILE\.config\opencode\AGENTS.md"
$repoAgentsMd = Join-Path $RepoDir "AGENTS.md"
if (Test-Path $repoAgentsMd) {
    if (-not (Test-Path $globalAgentsMd)) {
        Copy-Item -Path $repoAgentsMd -Destination $globalAgentsMd -Force
        ok "AGENTS.md copied to global config"
    } else {
        skip "AGENTS.md already exists in global config"
    }
} else {
    warn "Repo AGENTS.md not found at $repoAgentsMd"
}

# ── Step 7: Verify ────────────────────────────────────────────────
info "Verifying setup"
$checks = @(
    @{ Label = "GENTLEMAN_AGENT_ROOT"; Test = { $env:GENTLEMAN_AGENT_ROOT -eq $__rootDir } },
    @{ Label = "opencode.json exists"; Test = { Test-Path (Join-Path $RepoDir "opencode.json") } },
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
    Write-Host "   → Run 'gentleman-vmk' to launch" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "⚠️  Setup PARTIAL — review warnings above" -ForegroundColor Yellow
}
