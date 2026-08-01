#requires -Version 7
<#
.SYNOPSIS
  Audit trail for .gentleman agent actions — append-only log with read/filter/session.
.DESCRIPTION
  Manages .gentleman/audit.log — an append-only CSV tracking agent actions
  across all modes. Supports three commands: append, read, session.
.PARAMETER Command
  append | read | session
.PARAMETER Agent
  Agent name for append (e.g. gentleman-deep-auto)
.PARAMETER Mode
  Mode for append: manual | semi | auto
.PARAMETER Action
  Action type: ALLOW | DENY | ASK_ALLOW | ASK_DENY | WRITE | EDIT | ERROR
.PARAMETER Detail
  The command or detail being logged
.PARAMETER FilterAction
  Filter read/session by action type (accepts wildcard)
.PARAMETER FilterAgent
  Filter read/session by agent name (accepts wildcard)
.PARAMETER Last
  Show only last N entries (read mode)
.PARAMETER Since
  Show entries since this datetime (session mode)
.EXAMPLE
  .\scripts\audit-log.ps1 append -agent gentleman-deep-auto -mode auto -action ALLOW -detail "git status"
.EXAMPLE
  .\scripts\audit-log.ps1 read -filterAction DENY -last 20
.EXAMPLE
  .\scripts\audit-log.ps1 session -since "2026-07-29"
#>
[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory)]
    [ValidateSet('append','read','session')]
    [string]$Command,

    [string]$Agent = "unknown",
    [ValidateSet('manual','semi','auto','unknown')]
    [string]$Mode = "unknown",
    [ValidateSet('ALLOW','DENY','ASK_ALLOW','ASK_DENY','WRITE','EDIT','ERROR','DECISION','INFO')]
    [string]$Action = "INFO",
    [string]$Detail = "",

    [string]$FilterAction = "*",
    [string]$FilterAgent = "*",
    [int]$Last = 50,
    [datetime]$Since
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$repoRoot = Split-Path $PSScriptRoot -Parent
$logDir = Join-Path $repoRoot ".gentleman"
$logFile = Join-Path $logDir "audit.log"

if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

switch ($Command) {
    'append' {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $safeDetail = $Detail -replace '[\r\n]+', ' ' -replace ',', ';'
        $line = "$timestamp, $Agent, $Mode, $Action, $safeDetail"
        Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
        Write-Verbose "audit: $line"
    }

    'read' {
        if (-not (Test-Path -LiteralPath $logFile)) {
            Write-Host "Audit log not found" -ForegroundColor Yellow
            return
        }
        [string[]]$allLines = Get-Content -LiteralPath $logFile -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($allLines.Count -le 1) {
            Write-Host "No entries found" -ForegroundColor Yellow
            return
        }
        [System.Collections.ArrayList]$filtered = @()
        foreach ($line in $allLines) {
            if ($line -match "^#") { continue }
            if ($FilterAction -ne "*" -and $line -notmatch $FilterAction) { continue }
            if ($FilterAgent -ne "*" -and $line -notmatch $FilterAgent) { continue }
            $null = $filtered.Add($line)
        }
        if ($filtered.Count -eq 0) {
            Write-Host "No matching entries" -ForegroundColor Yellow
            return
        }
        $start = [Math]::Max(0, $filtered.Count - $Last)
        for ($i = $start; $i -lt $filtered.Count; $i++) {
            Write-Host $filtered[$i]
        }
        [int]$shown = [Math]::Min($Last, $filtered.Count)
        Write-Host "($($filtered.Count) total, showing last $shown)" -ForegroundColor DarkGray
    }

    'session' {
        if (-not (Test-Path -LiteralPath $logFile)) {
            Write-Host "Audit log not found" -ForegroundColor Yellow
            return
        }
        [string[]]$allLines = Get-Content -LiteralPath $logFile -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $Since) {
            $Since = (Get-Date).AddHours(-8)
        }
        $sinceStr = $Since.ToString("yyyy-MM-dd HH:mm:ss")
        [System.Collections.ArrayList]$filtered = @()
        foreach ($line in $allLines) {
            if ($line -match "^#") { continue }
            if ($line -match "^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})") {
                $entryDate = $Matches[1]
                if ($entryDate -lt $sinceStr) { continue }
                if ($FilterAction -ne "*" -and $line -notmatch $FilterAction) { continue }
                if ($FilterAgent -ne "*" -and $line -notmatch $FilterAgent) { continue }
                $null = $filtered.Add($line)
            }
        }
        if ($filtered.Count -eq 0) {
            $sinceFmt = $Since.ToString("yyyy-MM-dd HH:mm")
            Write-Host "No entries since $sinceFmt" -ForegroundColor Yellow
            return
        }

        $total = $filtered.Count
        [int]$allowCount = @($filtered | Where-Object { $_ -match ', ALLOW,' }).Count
        [int]$denyCount = @($filtered | Where-Object { $_ -match ', DENY,' }).Count
        [int]$errorCount = @($filtered | Where-Object { $_ -match ', ERROR,' }).Count
        [int]$writeCount = @($filtered | Where-Object { $_ -match ', (WRITE|EDIT),' }).Count
        [int]$askDenyCount = @($filtered | Where-Object { $_ -match ', ASK_DENY,' }).Count
        $sinceFmt = $Since.ToString("yyyy-MM-dd HH:mm")

        Write-Host "=== Session Audit: $sinceFmt -> now ===" -ForegroundColor Cyan
        Write-Host "  Total:       $total entries"
        Write-Host "  ALLOW:       $allowCount" -ForegroundColor Green
        Write-Host "  DENY:        $denyCount" -ForegroundColor Red
        Write-Host "  ASK_DENY:    $askDenyCount" -ForegroundColor Yellow
        Write-Host "  WRITE/EDIT:  $writeCount" -ForegroundColor Magenta
        Write-Host "  ERRORS:      $errorCount" -ForegroundColor Red
        [int]$recent = [Math]::Min(10, $total)
        Write-Host "--- Recent entries (last $recent) ---" -ForegroundColor DarkGray
        $filtered | Select-Object -Last 10 | ForEach-Object { Write-Host "  $_" }
    }
}
