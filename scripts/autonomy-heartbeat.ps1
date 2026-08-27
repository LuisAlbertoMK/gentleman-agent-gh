#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true)]
<#
.SYNOPSIS
    Autonomy heartbeat — reminds the agent every N minutes that auto = complete autonomy.
.DESCRIPTION
    Writes a timestamped reminder to .learnings/autonomy-heartbeat.jsonl and optionally
    starts a background job that repeats. No push, no approval wait — local only.

    Modes:
      -Check    : write one heartbeat entry (default, idempotent)
      -Install  : register a hidden background job repeating every Minutes
      -Uninstall: remove the background job + schedule
      -Status   : show last heartbeat(s)

    The heartbeat file is gitignored (local only). Safe to run anytime.

.PARAMETER Minutes
    Interval for -Install (default 5).
.PARAMETER Check
    Default mode — single heartbeat entry.
#>
param(
    [switch]$Check,
    [switch]$Install,
    [switch]$Uninstall,
    [switch]$Status,
    [int]$Minutes = 5
)

Set-StrictMode -Version Latest
. (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")
$repoRoot = Get-GentlemanProjectRoot
$hbFile = Join-Path (Join-Path $repoRoot ".learnings") "autonomy-heartbeat.jsonl"
$jobName = "gentleman-autonomy-heartbeat"

function Write-Heartbeat {
    $entry = [ordered]@{
        ts = (Get-Date -Format "o")
        branch = (git -C $repoRoot branch --show-current 2>$null)
        msg = "AUTO = autonomía completa — rama local, no esperar aprobación, no push hasta revisión final"
        interval_min = $Minutes
    }
    $learnings = Join-Path $repoRoot ".learnings"
    if (-not (Test-Path $learnings)) { New-Item -ItemType Directory -Path $learnings -Force | Out-Null }
    ($entry | ConvertTo-Json -Compress) | Add-Content -LiteralPath $hbFile -Encoding UTF8
    Write-Host "♥ heartbeat [$($entry.branch)] $($entry.ts)" -ForegroundColor DarkGreen
}

if ($Status) {
    if (Test-Path $hbFile) {
        Get-Content $hbFile -Tail 5 | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
        $j = Get-Job -Name $jobName -ErrorAction SilentlyContinue
        if ($j) { Write-Host "Job: $($j.Name) State=$($j.State)" -ForegroundColor Cyan } else { Write-Host "Job: not installed (run -Install)" -ForegroundColor Yellow }
    } else { Write-Host "No heartbeat yet — run -Check or -Install" -ForegroundColor Yellow }
    exit 0
}

if ($Uninstall) {
    Get-Job -Name $jobName -ErrorAction SilentlyContinue | Remove-Job -Force -ErrorAction SilentlyContinue
    # Also try to remove any scheduled task variant
    try { Unregister-ScheduledTask -TaskName $jobName -Confirm:$false -ErrorAction SilentlyContinue } catch {}
    Write-Host "♥ heartbeat uninstalled" -ForegroundColor Yellow
    exit 0
}

if ($Install) {
    # Install: ensure check first, then start background job
    Write-Heartbeat
    $existing = Get-Job -Name $jobName -ErrorAction SilentlyContinue
    if ($existing) { $existing | Remove-Job -Force -ErrorAction SilentlyContinue }
    $sb = {
        param($RepoRoot, $JobMinutes)
        while ($true) {
            Start-Sleep -Seconds ($JobMinutes * 60)
            $hb = Join-Path (Join-Path $RepoRoot ".learnings") "autonomy-heartbeat.jsonl"
            $entry = @{ ts = (Get-Date -Format "o"); branch = (git -C $RepoRoot branch --show-current 2>$null); msg = "AUTO heartbeat — autonomía completa" } | ConvertTo-Json -Compress
            $entry | Add-Content -LiteralPath $hb -Encoding UTF8
        }
    }
    $null = Start-Job -Name $jobName -ScriptBlock $sb -ArgumentList $repoRoot, $Minutes
    Write-Host "♥ heartbeat installed: every ${Minutes}min background job '$jobName' (local only, no push)" -ForegroundColor Green
    Write-Host "  Check: scripts/autonomy-heartbeat.ps1 -Status  |  Stop: -Uninstall" -ForegroundColor DarkGray
    exit 0
}

# Default: -Check (or no flag)
Write-Heartbeat
