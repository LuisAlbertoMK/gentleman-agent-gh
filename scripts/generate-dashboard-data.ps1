#requires -Version 7.0
<#
.SYNOPSIS
  Generate dashboard data.json for Gentleman Dashboard.
.DESCRIPTION
  Reads opencode.json agent count, scans .agents/skills/*/SKILL.md for
  token_budget frontmatter + byte size, runs bin/fast.exe --gate --json for
  fast metrics, reads .project.json score. Emits JSON to docs/dashboard/data.json
  or $env:TEMP when PESTER_TEST=1. Supports -WhatIf (no write).
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$RepoRoot = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($RepoRoot -and (Test-Path $RepoRoot)) {
    $repoRoot = (Resolve-Path $RepoRoot).Path
} else {
    $repoRoot = Split-Path $PSScriptRoot -Parent
    if (-not (Test-Path (Join-Path $repoRoot 'opencode.json'))) { $repoRoot = (Get-Location).Path }
    if ($RepoRoot -and -not (Test-Path $RepoRoot)) { Write-Warning "RepoRoot not found: $RepoRoot — using $repoRoot" }
}

$isTest = $env:PESTER_TEST -eq '1'

if ($isTest) {
    $outPath = Join-Path $env:TEMP 'dashboard-data-test.json'
} else {
    $outDir = Join-Path $repoRoot 'docs/dashboard'
    $outPath = Join-Path $outDir 'data.json'
}

# --- agents ---
$agentsTotal = 0
try {
    $ocPath = Join-Path $repoRoot 'opencode.json'
    if (Test-Path $ocPath) {
        $oc = Get-Content $ocPath -Raw | ConvertFrom-Json
        if ($null -ne $oc.agent) {
            $agentsTotal = @($oc.agent.PSObject.Properties).Count
        } elseif ($null -ne $oc.agents) {
            $agentsTotal = @($oc.agents.PSObject.Properties).Count
        }
    }
} catch { $agentsTotal = 0 }

# --- skills ---
$skillsTotal = 0
$budgeted = 0
$avgBudget = 0
$overBudgetList = @()
$sumBudget = 0
try {
    $skillsDir = Join-Path $repoRoot '.agents/skills'
    if (Test-Path $skillsDir) {
        $skillDirs = @(Get-ChildItem $skillsDir -Directory -ErrorAction Stop)
        $skillsTotal = $skillDirs.Count
        $budgets = @()
        foreach ($d in $skillDirs) {
            $skillFile = Join-Path $d.FullName 'SKILL.md'
            if (-not (Test-Path $skillFile)) { continue }
            try {
                $head = ((Get-Content $skillFile -TotalCount 20 -Encoding UTF8 -ErrorAction Stop) -join "`n")
            } catch {
                Write-Warning "SKILL.md read failed $skillFile : $($_.Exception.Message)"
                continue
            }
            $m = [regex]::Match($head, 'token_budget:\s*(\d+)')
            if ($m.Success) {
                $b = [int]$m.Groups[1].Value
                $budgets += $b
                $sumBudget += $b
                $budgeted++
            }
            $sz = (Get-Item $skillFile).Length
            # budget threshold 3200 (from fast.exe tokenBudget.budget)
            $budgetVal = if ($m.Success) { [int]$m.Groups[1].Value } else { 3200 }
            if ($sz -gt 3200 -or $sz -gt $budgetVal) {
                # over-budget if exceeds global 3200 or its own token_budget
                # Use global 3200 as primary (matches fast.exe overBudgetFiles=8)
                if ($sz -gt 3200) {
                    $overBudgetList += [PSCustomObject]@{
                        name   = $d.Name
                        size   = $sz
                        budget = $budgetVal
                        actual = $sz
                        delta  = $sz - $budgetVal
                    }
                }
            }
        }
        if ($budgeted -gt 0) { $avgBudget = [int]($sumBudget / $budgeted) }
        # sort by delta desc, keep all for overBudgetSkills, top5 for overBudget alias
        $overBudgetList = @($overBudgetList | Sort-Object -Property delta -Descending)
    }
} catch { Write-Warning $_.Exception.Message; $overBudgetList = @() }

$overBudgetCount = $overBudgetList.Count

# --- fast.exe gate ---
$gatePassed = $false
$gateTotal = 0
$gateDurationMs = 0
$elapsedMs = 0
$crossRefMs = 0
$tokenBudgetMs = 0
$crossRef = 0
$tokenBudgetTotal = 0
$tokenBudgetOver = 0
try {
    $fastExe = Join-Path $repoRoot 'bin/fast.exe'
    if (Test-Path $fastExe) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $raw = & $fastExe --gate --json 2>$null
        $sw.Stop()
        $elapsedMs = [int]$sw.ElapsedMilliseconds
        $gateDurationMs = $elapsedMs
        if ($raw) {
            try { $j = ($raw | Out-String) | ConvertFrom-Json } catch { $j = $null }
            if ($null -ne $j) {
                # passed alias
                if ($null -ne $j.passed) { $gatePassed = [bool]$j.passed }
                elseif ($null -ne $j.pass) { $gatePassed = [bool]$j.pass }
                try { if ($null -ne $j.elapsedMs) { $elapsedMs = [int]$j.elapsedMs; $gateDurationMs = $elapsedMs } } catch { Write-Debug "what failed: $($_.Exception.Message)" }
                try { if ($null -ne $j.crossRef.elapsedMs) { $crossRefMs = [int]$j.crossRef.elapsedMs } } catch { Write-Debug "what failed: $($_.Exception.Message)" }
                try { if ($null -ne $j.tokenBudget.elapsedMs) { $tokenBudgetMs = [int]$j.tokenBudget.elapsedMs } } catch { Write-Debug "what failed: $($_.Exception.Message)" }
                try { if ($null -ne $j.crossRef.canonicalSkills) { $crossRef = [int]$j.crossRef.canonicalSkills } } catch { Write-Debug "what failed: $($_.Exception.Message)" }
                try { if ($crossRef -eq 0 -and $null -ne $j.crossRef.agents) { $crossRef = [int]$j.crossRef.agents } } catch { Write-Debug "what failed: $($_.Exception.Message)" }
                try { if ($null -ne $j.tokenBudget.skills.budget) { $tokenBudgetTotal = [int]$j.tokenBudget.skills.budget } } catch { Write-Debug "what failed: $($_.Exception.Message)" }
                try { if ($null -ne $j.tokenBudget.budget) { $tokenBudgetTotal = [int]$j.tokenBudget.budget } } catch { Write-Debug "what failed: $($_.Exception.Message)" }
                try { if ($null -ne $j.tokenBudget.skills.overBudgetFiles) { $tokenBudgetOver = [int]$j.tokenBudget.skills.overBudgetFiles } } catch { Write-Debug "what failed: $($_.Exception.Message)" }
            }
        }
    } else {
        $gatePassed = $false
        $elapsedMs = 0
        $gateDurationMs = 0
    }
} catch {
    $gatePassed = $false
    $elapsedMs = 0
    $gateDurationMs = 0
}
# gate.total = number of checks in .githooks/pre-commit-gate.ps1 (currently 26), NOT 58+93
$gateTotal = 0
$gateFile = Join-Path $repoRoot '.githooks/pre-commit-gate.ps1'
if (Test-Path $gateFile) {
    $headers = [regex]::Matches((Get-Content $gateFile -Raw), '\[(\d+)/(\d+)\]')
    $denoms = @($headers | ForEach-Object { [int]$_.Groups[2].Value } | Where-Object { $_ -gt 0 })
    if ($denoms.Count -gt 0) { $gateTotal = ($denoms | Measure-Object -Maximum).Maximum }
}
if ($crossRef -eq 0) {
    try {
        $fj = & (Join-Path $repoRoot 'bin/fast.exe') --gate --json 2>$null | ConvertFrom-Json
        if ($null -ne $fj.crossRef.canonicalSkills) { $crossRef = [int]$fj.crossRef.canonicalSkills }
    } catch { Write-Warning $_.Exception.Message }
}

# --- score ---
$scoreVal = 0
try {
    $pj = Join-Path $repoRoot '.project.json'
    if (Test-Path $pj) {
        $pjJson = Get-Content $pj -Raw | ConvertFrom-Json
        if ($null -ne $pjJson.score.current) { $scoreVal = [double]$pjJson.score.current }
        elseif ($null -ne $pjJson.score) { $scoreVal = [double]$pjJson.score }
    }
} catch { $scoreVal = 0 }

$generatedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

# Build union data.json covering BOTH spec contracts
$data = [ordered]@{
    generatedAt = $generatedAt
    gate        = [ordered]@{
        passed           = $gatePassed
        pass             = $gatePassed
        total            = $gateTotal
        durationMs       = $gateDurationMs
        elapsedMs        = $elapsedMs
        crossRef         = $crossRef
        tokenBudget      = [ordered]@{
            total           = $tokenBudgetTotal
            overBudgetFiles = $tokenBudgetOver
        }
    }
    fast        = [ordered]@{
        elapsedMs     = $elapsedMs
        crossRefMs    = $crossRefMs
        tokenBudgetMs = $tokenBudgetMs
    }
    agents      = [ordered]@{
        total = $agentsTotal
    }
    skills      = [ordered]@{
        total            = $skillsTotal
        budgeted         = $budgeted
        avgBudget        = $avgBudget
        overBudget       = $overBudgetCount
        overBudgetSkills = @($overBudgetList | ForEach-Object {
            [ordered]@{ name = $_.name; size = $_.size; budget = $_.budget; actual = $_.actual; delta = $_.delta }
        })
        overBudgetFiles  = $overBudgetCount
    }
    score       = $scoreVal
    projectScore = $scoreVal
}

$json = $data | ConvertTo-Json -Depth 6 -Compress

if ($PSCmdlet.ShouldProcess($outPath, 'Write dashboard data.json')) {
    if (-not $isTest) {
        $dir = Split-Path $outPath -Parent
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    }
    Set-Content -Path $outPath -Value $json -Encoding utf8NoBOM
    Write-Host "Dashboard data written to $outPath (agents=$agentsTotal skills=$skillsTotal overBudget=$overBudgetCount gatePassed=$gatePassed)"
}
