#!/usr/bin/env pwsh
#requires -Version 7
<#
.SYNOPSIS Pre-commit quality gate — ALL 13 checks in a single pwsh invocation
.DESCRIPTION Called by .githooks/pre-commit. Replaces 9 separate pwsh calls.
  Saves ~1.8s per commit by eliminating redundant process startups.
#>
param([string]$RepoRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepoRoot) { $RepoRoot = (git rev-parse --show-toplevel 2>$null) ?? '.' }

$passed = 0; $failed = 0; $blocked = $false

function Pass { $script:passed++; Write-Host "  $([char]0x1b)[32mOK$([char]0x1b)[0m" }
function Warn  { param([string]$Msg) $script:passed++; if ($Msg) { Write-Host "  $([char]0x1b)[33m$Msg$([char]0x1b)[0m" } else { Write-Host "  $([char]0x1b)[33mWARN$([char]0x1b)[0m" } }
function Fail  { param([string]$Msg) $script:failed++; $script:blocked = $true; if ($Msg) { Write-Host "  $([char]0x1b)[31mBLOCKING: $Msg$([char]0x1b)[0m" } else { Write-Host "  $([char]0x1b)[31mBLOCKING$([char]0x1b)[0m" } }

# Detect staged files (done once, reused by multiple checks)
$staged = git diff --cached --name-only --diff-filter=ACM
$stagedPS1       = $staged | Where-Object { $_ -like '*.ps1' }
$stagedSkills    = $staged | Where-Object { $_ -match '\.agents/skills/' }
$stagedProject   = $staged | Where-Object { $_ -match '\.project\.json$' }
$stagedRules     = $staged | Where-Object { $_ -match 'review-rules\.jsonc$' }
$stagedAgents    = $staged | Where-Object { $_ -match 'AGENTS\.md|\.agents/skills/' }
$stagedRoja      = $staged | Where-Object { $_ -match '^(src/|test/|scripts/|migrations/|ci/|\.github/)' }
$stagedSkillMds  = $staged | Where-Object { $_ -match '\.agents/skills/[^/]+/SKILL\.md$' }
$stagedTests     = $staged | Where-Object { $_ -match '\.Tests\.ps1$' }
$stagedConfig    = $staged | Where-Object { $_ -match 'scripts/opencode-config/' }

Write-Host "`n=== Gentleman Quality Gate ==="

# [1/13] Trailing whitespace
Write-Host "[1/13] Trailing whitespace..."
$wsOut = git diff --cached --check 2>&1
$wsLines = $wsOut | Where-Object { $_ -notmatch '^\s*$' }
if ($wsLines) { $wsLines -join "`n" | ForEach-Object { Write-Host "    $_" }; Warn "fix trailing whitespace before push" }
else { Pass }

# [2/13] #requires Version check
Write-Host "[2/13] #requires Version check (staged .ps1)..."
if ($stagedPS1) {
    $missing = $stagedPS1 | Where-Object {
        $full = Join-Path $RepoRoot $_
        if (-not (Test-Path $full)) { $false }
        else { -not ((Get-Content $full -TotalCount 3) -match '#requires -Version (5\.1|7)') }
    }
    if ($missing) { $missing | ForEach-Object { Write-Host "    $_" }; Fail "scripts missing '#requires -Version 5.1 or 7'" }
    else { Pass }
} else { Pass }

# [3/13] Cross-ref check
Write-Host "[3/13] Cross-ref check..."
if ($stagedSkills) {
    & "$RepoRoot/scripts/cross-ref-check.ps1" -Quiet -ErrorAction SilentlyContinue 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Pass } else { Fail "cross-ref validation failed" }
} else { Pass }

# [4/13] Skill drift
Write-Host "[4/13] Skill drift..."
if ($stagedSkills) {
    & "$RepoRoot/scripts/check-skill-drift.ps1" -Quiet -ErrorAction SilentlyContinue 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Pass } else { Warn "skill drift detected (non-blocking)" }
} else { Pass }

# [5/13] Improvement cycle — overweight skills
Write-Host "[5/13] Improvement cycle..."
$canonical = "$RepoRoot/.agents/skills"
$overweight = if (Test-Path $canonical) {
    Get-ChildItem $canonical -Directory | Where-Object { $_.Name -ne '_shared' } | ForEach-Object {
        $md = Join-Path $_.FullName 'SKILL.md'
        if (Test-Path $md) { $len = (Get-Content $md -Raw).Length; if ($len -gt 3072) { "$($_.Name) ($($len)B)" } }
    }
}
if ($overweight) { Warn "skills >3KB (consider improvement cycle):`n$($overweight -join "`n")" } else { Pass }

# [6/13] .project.json integrity
Write-Host "[6/13] .project.json integrity..."
if ($stagedProject) {
    try {
        $json = Get-Content "$RepoRoot/.project.json" -Raw -Encoding UTF8 | ConvertFrom-Json
        $dims = $json.score.dimensions.PSObject.Properties.Name.Count
        $current = $json.score.current
        if ($dims -ne 13) { Fail "Expected 13 dimensions, found $dims" }
        elseif ($null -eq $current -or $current -lt 5) { Fail "score.current missing or < 5" }
        else { Pass }
    } catch { Fail ".project.json parse error: $_" }
} else { Pass }

# [7/13] review-rules.jsonc integrity
Write-Host "[7/13] review-rules.jsonc integrity..."
if ($stagedRules) {
    try {
        $raw = Get-Content "$RepoRoot/review-rules.jsonc" -Raw -Encoding UTF8
        $parsed = $raw -replace '(?m)^\s*//.*$','' -replace '(?m)\s*//[^"''\n]*$','' -replace '(?s)/\*.*?\*/','' | ConvertFrom-Json
        $z = $parsed.zones.PSObject.Properties.Name.Count; $c = $parsed.context_zones.PSObject.Properties.Name.Count
        $m = $parsed.modes.PSObject.Properties.Name.Count; $p = $parsed.jd_profiles.PSObject.Properties.Name.Count
        $s = $parsed.jd_profile_selector.Count
        if ($z -ne 3) { Fail "Expected 3 zones, found $z" }
        elseif ($c -ne 4) { Fail "Expected 4 context zones, found $c" }
        elseif ($m -ne 4) { Fail "Expected 4 modes, found $m" }
        elseif ($p -lt 1) { Fail "Expected >=1 jd_profiles, found $p" }
        elseif ($s -lt 1) { Fail "Expected >=1 selectors, found $s" }
        else { Pass }
    } catch { Fail "review-rules.jsonc parse error: $_" }
} else { Pass }

# [8/13] Benchmark check
Write-Host "[8/13] Benchmark check..."
if ($stagedAgents) {
    $benchOut = & "$RepoRoot/scripts/benchmark.ps1" -Gate 2>&1 | Out-String
    if ($benchOut -match 'REGRESSIONS') { Warn "benchmark regressions detected`n$benchOut" }
    else { $benchOut.Trim() -split "`n" | ForEach-Object { Write-Host "    $_" }; Pass }
} else { Pass }

# [9/13] JD review check
Write-Host "[9/13] JD review check (ROJA zone)..."
if ($stagedRoja) {
    $rojaPreview = $stagedRoja | ForEach-Object { "    $_" }
    Warn "ROJA zone files staged without JD dual review:`n$($rojaPreview -join "`n")`n  Use '!ship' or 'judgment-day'"
} else { Pass }

# [10/13] Secrets scan
Write-Host "[10/13] Secrets scan..."
$diffContent = git diff --cached --diff-filter=ACM -- ':!.githooks' ':!*.tests.ps1' ':!scripts/check-mcp-security.ps1' ':!.agents/skills/*/references/*' ':!.gitleaks.toml' ':!docs/mejoras/*'
$secrets = $diffContent | Select-String -Pattern '^\+[^\+]' | ForEach-Object { $_.Line.Substring(1) } |
    Select-String -Pattern '(ghp_|gho_|github_pat_|AKIA|ctx7sk_|-----BEGIN\s+(RSA|EC|DSA|PRIVATE)\s+KEY|GH_TOKEN\s*=|GITHUB_TOKEN\s*=|password\s*=|api[_-]?key\s*=|secret\s*=|token\s*=)'
if ($secrets) {
    $secrets | ForEach-Object {
        $line = $_.Line.Trim()
        if ($line.Length -gt 80) { $line = $line.Substring(0,77)+'...' }
        Write-Host "    $($_.Filename):$($_.LineNumber) $line"
    }
    Fail "potential secrets found in staged diff"
} else { Pass }

# [11/13] SKILL.md frontmatter completeness
Write-Host "[11/13] Taste invariant: SKILL.md frontmatter..."
if ($stagedSkillMds) {
    $fmFail = $false
    foreach ($sf in $stagedSkillMds) {
        $fullPath = Join-Path $RepoRoot $sf
        if (-not (Test-Path $fullPath)) { continue }
        $content = Get-Content $fullPath -Raw
        $fm = if ($content -match '^---\s*(.*?)---') { $Matches[1] } else { '' }
        if ($fm -notmatch 'name:\s+') { Write-Host "  $([char]0x1b)[31m  BLOCKING: $sf — missing 'name:'$([char]0x1b)[0m"; $fmFail=$true }
        if ($fm -notmatch 'description:\s+') { Write-Host "  $([char]0x1b)[31m  BLOCKING: $sf — missing 'description:'$([char]0x1b)[0m"; $fmFail=$true }
        if ($fm -notmatch 'triggers:\s+') { Write-Host "  $([char]0x1b)[31m  BLOCKING: $sf — missing 'triggers:'$([char]0x1b)[0m"; $fmFail=$true }
    }
    if ($fmFail) { Fail "frontmatter issues" } else { Pass }
} else { Pass }

# [12/13] Pester tests
Write-Host "[12/13] Pester tests..."
if ($stagedTests) {
    try {
        Import-Module Pester -ErrorAction Stop
        $results = Invoke-Pester -Path ($stagedTests | ForEach-Object { Join-Path $RepoRoot $_ }) -PassThru
        if ($results.FailedCount -gt 0) { Fail "Pester: $($results.FailedCount) test(s) failed" } else { Pass }
    } catch { Warn "Pester not available: $_" }
} else { Pass }

# [13/13] Config expansion check
Write-Host "[13/13] Config expansion check..."
if ($stagedConfig) {
    $importMarkers = git show :opencode.json 2>$null | Select-String -Pattern '\$import'
    if ($importMarkers) { Fail "Config sources changed but opencode.json has unresolved `$import markers" }
    else { Pass }
} else { Pass }

# Summary
Write-Host "`n=== Gate: $passed/$($passed+$failed) passed ==="
if ($blocked) { Write-Host "  $([char]0x1b)[31mBLOCKED$([char]0x1b)[0m" }
else { Write-Host "  $([char]0x1b)[32mALL CLEAR$([char]0x1b)[0m" }

# Capture result
$blockedStr = if ($blocked) { 'yes' } else { 'no' }
& "$RepoRoot/scripts/capture-errors.ps1" -Source quality-gate -Passed $passed -Failed $failed -Blocked $blockedStr *>$null

exit $(if ($blocked) { 1 } else { 0 })
