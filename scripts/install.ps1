#requires -Version 7.6
<#
.SYNOPSIS
    Gentleman Agent — Windows environment setup
.DESCRIPTION
    Configures gentleman-agent-gh on Windows:
    - Sets GENTLEMAN_AGENT_ROOT and OpenCode environment variables
    - Creates global shell shortcuts (opencode-vmk, gentleman-vmk)
    - Links skills into OpenCode global config
    - Optionally installs gentle-ai CLI dependency
.EXAMPLE
    .\scripts\install.ps1                 # interactive
    .\scripts\install.ps1 -InstallGentleAI  # auto-install dep
    .\scripts\install.ps1 -Yes             # non-interactive
#>
param(
    [switch]$InstallGentleAI,
    [switch]$Yes
)
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

# ── Step 2: Optional gentle-ai CLI ──────────────────────────────────
$hasGentleAI = [bool](Get-Command "gentle-ai" -ErrorAction SilentlyContinue)
if (-not $hasGentleAI) {
    $installDep = $InstallGentleAI
    if (-not $installDep -and -not $Yes) {
        $resp = Read-Host "gentle-ai CLI not found. Install it? (required to use these skills) [Y/n]"
        $installDep = ($resp -ne 'n' -and $resp -ne 'N')
    }
    if ($installDep) {
        Write-Host "==> Installing gentle-ai CLI..." -ForegroundColor Cyan
        $url = "https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.ps1"
        $tmpFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        try {
            Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $tmpFile
            $hash = (Get-FileHash -LiteralPath $tmpFile -Algorithm SHA256).Hash
            Write-Host "       Downloaded to: $tmpFile" -ForegroundColor DarkGray
            Write-Host "       SHA256: $hash" -ForegroundColor DarkGray
            Write-Host "       Source: $url" -ForegroundColor DarkGray
            $expected = $env:GENTLE_AI_INSTALL_HASH
            if ($expected) {
                if ($hash -ne $expected) {
                    throw "Checksum mismatch! Expected $expected, got $hash. Aborting for safety."
                }
                Write-Host "       [ok] checksum verified" -ForegroundColor Green
            } else {
                Write-Host "       [warn] Set GENTLE_AI_INSTALL_HASH to verify checksum automatically" -ForegroundColor Yellow
            }
            if (-not $Yes) {
                $confirm = Read-Host "Execute remote install script? [Y/n]"
                if ($confirm -eq 'n' -or $confirm -eq 'N') { throw "Aborted by user" }
            }
            & $tmpFile
        } finally {
            if (Test-Path $tmpFile) { Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue }
        }
    } else {
        Write-Host "[warn] gentle-ai CLI not installed. Skills won't be usable." -ForegroundColor Yellow
        Write-Host "       Install later: .\scripts\install.ps1 -InstallGentleAI" -ForegroundColor DarkGray
    }
} else {
    Write-Host "[ok] gentle-ai CLI already installed" -ForegroundColor Green
}

# ── Done ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "✅ gentleman-agent-gh setup complete" -ForegroundColor Green
Write-Host "   Run 'opencode-vmk' to launch" -ForegroundColor Cyan
Write-Host "   Run 'gentleman-vmk' (alias)" -ForegroundColor Cyan
