#requires -Version 5.1
<#
.SYNOPSIS
    Gentleman Agent — Windows bootstrap entry point
.DESCRIPTION
    Clones the repo and runs install.ps1. Supports both curl|powershell one-liner
    and local execution.
.PARAMETER RepoUrl
    Override repository URL (default: https://github.com/anomalco/opencode.git)
.PARAMETER Branch
    Override git branch (default: master)
.PARAMETER InstallDir
    Override install directory (default: $env:LOCALAPPDATA\gentleman-agent)
.PARAMETER Update
    Update existing installation instead of fresh clone
.EXAMPLE
    iex "& { $(irm https://gentleman.sh/install.ps1) }"
.EXAMPLE
    .\scripts\bootstrap.ps1 -Update
.NOTES
    Auto-detects scoop/choco for dependency installation.
#>
param(
    [string]$RepoUrl = "https://github.com/anomalco/opencode.git",
    [string]$Branch = "master",
    [string]$InstallDir = "$env:LOCALAPPDATA\gentleman-agent",
    [switch]$Update
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.ForegroundColor = 'White'

function info  { Write-Host "==> " -ForegroundColor Cyan -NoNewline; Write-Host "$args" }
function ok    { Write-Host "[ok] " -ForegroundColor Green -NoNewline; Write-Host "$args" }
function warn  { Write-Host "[warn] " -ForegroundColor Yellow -NoNewline; Write-Host "$args" }
function err   { Write-Host "[err] " -ForegroundColor Red -NoNewline; Write-Host "$args"; exit 1 }

info "Gentleman Agent Bootstrap v1.0.0 (Windows)"

# ── Check Git ─────────────────────────────────────────────────────
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    warn "Git not found. Attempting install via available package manager..."
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        & scoop install git 2>$null; if (-not $?) { err "scoop install git failed" }
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        & choco install git -y 2>$null; if (-not $?) { err "choco install git failed" }
    } else {
        err "Install Git for Windows from https://git-scm.com/download/win, then re-run."
    }
}

# ── Clone / update ────────────────────────────────────────────────
if (Test-Path "$InstallDir\.git") {
    if ($Update) {
        info "Updating existing installation at $InstallDir"
        & git -C "$InstallDir" fetch origin $Branch 2>$null
        & git -C "$InstallDir" reset --hard "origin/$Branch" 2>$null
    } else {
        warn "Already installed at $InstallDir"
        $reply = Read-Host "Run with -Update to refresh, or skip? [s/U]"
        if ($reply -match '^[sS]') { ok "Skipped"; exit 0 }
        & git -C "$InstallDir" pull --ff-only origin $Branch 2>$null
        if (-not $?) {
            warn "Pull failed, re-cloning..."
            Remove-Item -Recurse -Force "$InstallDir" -ErrorAction SilentlyContinue
            & git clone --depth 1 --branch $Branch $RepoUrl $InstallDir 2>$null
            if (-not $?) { err "Clone failed: $RepoUrl" }
        }
    }
} else {
    info "Cloning $RepoUrl (branch: $Branch)"
    $parent = Split-Path $InstallDir -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    & git clone --depth 1 --branch $Branch $RepoUrl $InstallDir 2>$null
    if (-not $?) { err "Clone failed: $RepoUrl" }
}

# ── Run installer ────────────────────────────────────────────────
Set-Location $InstallDir
info "Running install.ps1..."
& "$InstallDir\scripts\install.ps1"

# ── Next steps ────────────────────────────────────────────────────
Write-Host ""
info "Gentleman Agent installed!"
Write-Host ""
Write-Host "  Install dir:  $InstallDir" -ForegroundColor Cyan
Write-Host "  Skills:       ~\.config\opencode\skills\*" -ForegroundColor Cyan
Write-Host "  Scripts:      ~\.config\opencode\scripts\*" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Run OpenCode to activate. To verify:" -ForegroundColor White
Write-Host "    Get-ChildItem ~\.config\opencode\skills" -ForegroundColor Gray
Write-Host ""
Write-Host "  For updates later:" -ForegroundColor White
Write-Host "    cd $InstallDir; git pull; .\scripts\bootstrap.ps1 -Update" -ForegroundColor Gray
Write-Host ""
