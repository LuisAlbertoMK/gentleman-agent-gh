#Requires -Version 5.1
<#
.SYNOPSIS
    Gentleman Agent -- OpenCode skill installer (Windows).
    Creates junctions from repo skills/scripts to ~/.config/opencode/.
.DESCRIPTION
    Usage: .\scripts\install.ps1
    Requires: git clone of gentleman-agent-gh completed.
    Creates global junctions so OpenCode can load skills from any directory.
.NOTES
    This installs gentleman-agent-gh, NOT Gentle-AI.
    For Gentle-AI see https://github.com/Gentleman-Programming/gentle-ai
#>
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$srcSkills = Resolve-Path "$PSScriptRoot\..\.agents\skills" -ErrorAction Stop
$dstSkills = "$env:USERPROFILE\.config\opencode\skills"
$srcScripts = Resolve-Path "$PSScriptRoot" -ErrorAction Stop
$dstScripts = "$env:USERPROFILE\.config\opencode\scripts"

Write-Host "==> Gentleman Agent Installer (Windows)" -ForegroundColor Cyan
Write-Host ""

# Skills
Write-Host "[info] Installing skills..." -ForegroundColor Blue
try {
    New-Item -ItemType Directory -Path $dstSkills -Force | Out-Null
    $count = 0
    foreach ($skill in Get-ChildItem -Directory -Path $srcSkills) {
        $link = Join-Path $dstSkills $skill.Name
        if (-not (Test-Path $link)) {
            New-Item -ItemType Junction -Path $link -Target $skill.FullName -ErrorAction Stop | Out-Null
            $count++
        }
    }
    $totalSkills = @(Get-ChildItem -Directory $srcSkills).Count
    Write-Host "[ok] $count new junctions (total available: $totalSkills)" -ForegroundColor Green
} catch {
    Write-Host "[err] Skills installation failed: $_" -ForegroundColor Red
    throw
}

# Scripts
Write-Host "[info] Installing scripts..." -ForegroundColor Blue
try {
    if (-not (Test-Path $dstScripts)) {
        New-Item -ItemType Junction -Path $dstScripts -Target $srcScripts -ErrorAction Stop | Out-Null
        Write-Host "[ok] Scripts junction created" -ForegroundColor Green
    } else {
        Write-Host "[warn] $dstScripts exists, skipping" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[err] Scripts installation failed: $_" -ForegroundColor Red
    throw
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host "Next step: open OpenCode and load the skills" -ForegroundColor White
