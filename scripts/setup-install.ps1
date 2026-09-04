#requires -Version 5.1
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Gentleman Agent — Windows environment setup
.DESCRIPTION
    Configures gentleman-agent-gh on Windows:
    - Sets GENTLEMAN_AGENT_ROOT and OpenCode environment variables
    - Creates global shell shortcuts (gentleman-vmk)
    - Links skills into OpenCode global config
    - Optionally installs gentle-ai CLI dependency
.EXAMPLE
    .\scripts\setup-install.ps1                 # interactive
    .\scripts\setup-install.ps1 -InstallGentleAI  # auto-install dep
#>
param(
    [switch]$InstallGentleAI
,
    [switch]$Quiet,
    [switch]$Json)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repoDir = Split-Path -Path $PSScriptRoot -Parent

# ── Bootstrap ────────────────────────────────────────────────────────
Write-Host "==> Gentleman Agent — Windows setup" -ForegroundColor Cyan
Write-Host "    Repo: $repoDir`n" -ForegroundColor DarkGray

# ── Step 1: Run setup-machine.ps1 for env + shortcuts + skill links ─
try {
    & "$PSScriptRoot\setup-machine.ps1" -RepoDir $repoDir
} catch {
    Write-Host "[err] setup-machine.ps1 failed: $_" -ForegroundColor Red
    Write-Host "       Continuing with partial setup..." -ForegroundColor Yellow
}

# ── Step 2: Wire git hooks + build Go gate ──────────────────────────
# Without core.hooksPath, local commits run ungated (the quality gate is
# dead code). Without a gate binary, the hook falls back to pwsh (slower
# but still enforced) — see ADR-049 (PS fallback mandatory).
try {
    git -C $repoDir config core.hooksPath .githooks
    Write-Host "[ok] git hooks wired: core.hooksPath = .githooks" -ForegroundColor Green
    if (Get-Command go -ErrorAction SilentlyContinue) {
        Push-Location $repoDir
        try {
            & go build -o (Join-Path $repoDir 'bin\gate.exe') ./cmd/gate 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[ok] gate.exe built — fast pre-commit path active" -ForegroundColor Green
            } else {
                Write-Host "[warn] gate build failed — pre-commit falls back to pwsh" -ForegroundColor Yellow
            }
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "[info] Go not found — hooks fall back to pwsh (slower, still enforced)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[warn] hook wiring failed: $_" -ForegroundColor Yellow
}

# ── Step 3: Optional gentle-ai CLI ──────────────────────────────────
# NOTE: This repo (gentleman-agent-gh) does NOT install gentle-ai by default.
# The -InstallGentleAI switch is deprecated and now throws an error to prevent
# accidentally shadowing the local environment with a different upstream tool.
if ($InstallGentleAI) {
    throw "-InstallGentleAI is no longer supported. If you need the gentle-ai CLI, install it separately from https://github.com/Gentleman-Programming/gentle-ai"
}

$hasGentleAI = [bool](Get-Command "gentle-ai" -ErrorAction SilentlyContinue)
if (-not $hasGentleAI) {
    Write-Host "[info] gentle-ai CLI not found. This is optional — gentleman-agent-gh works without it." -ForegroundColor Yellow
    Write-Host "       To install gentle-ai separately, visit: https://github.com/Gentleman-Programming/gentle-ai" -ForegroundColor DarkGray
} else {
    Write-Host "[ok] gentle-ai CLI detected (optional dependency)" -ForegroundColor Green
}

# ── Done ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "✅ gentleman-agent-gh setup complete" -ForegroundColor Green
Write-Host "   Run 'gentleman-vmk' to launch" -ForegroundColor Cyan
