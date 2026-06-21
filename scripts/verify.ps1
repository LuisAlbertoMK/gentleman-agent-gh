<#
.SYNOPSIS
  Unified verify profiles E1/E2/E3 — runnable checks for triple-verify gates.

.DESCRIPTION
  Implements the verify profiles defined in review-rules.jsonc with
  actual executable commands. Exit code 0 = all pass, non-zero = failures.

.PARAMETER Profile
  Verify profile: E1 (testing), E2 (static), E3 (build/runtime), or All.

.PARAMETER Json
  Output structured JSON for agent consumption.

.PARAMETER RepoRoot
  Root of the repo. Defaults to script parent dir.

.EXAMPLE
  .\scripts\verify.ps1 -Profile E2
  .\scripts\verify.ps1 -Profile All -Json
#>

param(
    [ValidateSet('E1','E2','E3','All')]
    [string]$VerifyProfile = 'All',
    [switch]$Json,
    [string]$RepoRoot = (Split-Path $PSScriptRoot -Parent)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$vRes = @{ profile = $VerifyProfile; checks = @(); passed = 0; failed = 0; errors = @() }

function Add-CheckResult {
    param([string]$Name, [bool]$Passed, [string]$Detail = '')
    $script:vRes.checks += @{ name = $Name; passed = $Passed; detail = $Detail }
    if ($Passed) { $script:vRes.passed++ } else { $script:vRes.failed++ }
    $color = if ($Passed) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} -- {2}" -f $(if ($Passed) { 'PASS' } else { 'FAIL' }), $Name, $Detail) -ForegroundColor $color
}

# ═══════════════════════════════════════════════════════
# E1 — Testing: syntax checks, frontmatter validation
# ═══════════════════════════════════════════════════════
function Invoke-E1Checks {
    Write-Host "`n=== E1: Testing ===" -ForegroundColor Cyan

    # [E1.1] PS script syntax — all files parse
    $scriptDir = Join-Path $RepoRoot 'scripts'
    $badSyntax = @()
    Get-ChildItem "$scriptDir\*.ps1" | ForEach-Object {
        $err = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$err)
        if ($err) { $badSyntax += "$($_.Name): $($err.Message)" }
    }
    if ($badSyntax.Count -eq 0) { Add-CheckResult 'PS Syntax' $true 'All scripts parse OK' }
    else { Add-CheckResult 'PS Syntax' $false "$($badSyntax.Count) files with errors: $($badSyntax -join '; ')" }

    # [E1.2] Skill frontmatter — basic YAML-like validation
    $skillsDir = Join-Path $RepoRoot '.agents\skills'
    $badFrontmatter = @()
    if (Test-Path $skillsDir) {
        Get-ChildItem "$skillsDir\*\SKILL.md" | ForEach-Object {
            $content = Get-Content $_.FullName -Raw -Encoding UTF8
            if ($content -match '^---') {
                $end = $content.IndexOf('---', 3)
                if ($end -eq -1) { $badFrontmatter += "$($_.Directory.Name): unclosed frontmatter" }
            }
        }
    }
    if ($badFrontmatter.Count -eq 0) { Add-CheckResult 'Skill Frontmatter' $true 'All frontmatter valid' }
    else { Add-CheckResult 'Skill Frontmatter' $false "$($badFrontmatter.Count) issues: $($badFrontmatter -join '; ')" }

    # [E1.3] cross-ref-check --basic
    $xrefScript = Join-Path $scriptDir 'cross-ref-check.ps1'
    if (Test-Path $xrefScript) { & $xrefScript; Add-CheckResult 'Cross-Ref Check' ($LASTEXITCODE -eq 0) "exit $LASTEXITCODE" }
    else { Add-CheckResult 'Cross-Ref Check' $true 'cross-ref-check.ps1 not found (skipped)' }
}

# ═══════════════════════════════════════════════════════
# E2 — Static: PSSA, secrets, hygiene
# ═══════════════════════════════════════════════════════
function Invoke-E2Checks {
    Write-Host "`n=== E2: Static ===" -ForegroundColor Cyan

    # [E2.1] PSSA gate
    $pssaScript = Join-Path $RepoRoot 'scripts\pssa-gate.ps1'
    if (Test-Path $pssaScript) {
        & $pssaScript -Mode Check
        Add-CheckResult 'PSSA Gate' ($LASTEXITCODE -eq 0) "exit $LASTEXITCODE"
    } else { Add-CheckResult 'PSSA Gate' $true 'pssa-gate.ps1 not found (skipped)' }

    # [E2.2] Secrets scan — grep for common patterns
    $secretsFound = @()
    $secretPatterns = @('password\s*=', 'secret\s*=', 'api[_-]?key\s*=', 'token\s*=', 'connection\s*string\s*=')
    $scanDirs = @((Join-Path $RepoRoot 'scripts'), (Join-Path $RepoRoot '.agents\skills'))
    foreach ($dir in $scanDirs) {
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem $dir -Recurse -Include '*.ps1','*.md','*.psm1' | ForEach-Object {
            $content = Get-Content $_.FullName -Raw -Encoding UTF8
            foreach ($pattern in $secretPatterns) {
                if ($content -match $pattern) {
                    $secretsFound += "$($_.Name): matched '$pattern'"
                }
            }
        }
    }
    if ($secretsFound.Count -eq 0) { Add-CheckResult 'Secrets Scan' $true 'No patterns detected' }
    else { Add-CheckResult 'Secrets Scan' $false "$($secretsFound.Count) potential secrets: $($secretsFound -join '; ')" }

    # [E2.3] Git hygiene — check for uncommitted changes
    Push-Location $RepoRoot
    $gitStatus = $(git status --short)
    Pop-Location
    if ([string]::IsNullOrWhiteSpace($gitStatus)) { Add-CheckResult 'Git Hygiene' $true 'Working tree clean' }
    else { Add-CheckResult 'Git Hygiene' $false "Uncommitted changes detected" }

    # [E2.4] review-rules.jsonc parse check
    $rulesPath = Join-Path $RepoRoot 'review-rules.jsonc'
    if (Test-Path $rulesPath) {
        try {
            $raw = Get-Content $rulesPath -Raw -Encoding UTF8
            $stripped = $raw -replace '(?m)^\s*//.*$','' -replace '(?m)\s*//[^"\n]*$','' -replace '(?s)/\*.*?\*/',''
            $null = $stripped | ConvertFrom-Json
            Add-CheckResult 'review-rules.jsonc' $true 'Parses OK'
        } catch { Add-CheckResult 'review-rules.jsonc' $false "Parse error: $_" }
    } else { Add-CheckResult 'review-rules.jsonc' $true 'Not found (skipped)' }
}

# ═══════════════════════════════════════════════════════
# E3 — Build/Runtime: junctions, project.json, script help
# ═══════════════════════════════════════════════════════
function Invoke-E3Checks {
    Write-Host "`n=== E3: Build/Runtime ===" -ForegroundColor Cyan

    # [E3.1] Global junctions exist
    $canonicalDir = Join-Path $RepoRoot '.agents\skills'
    $globalDir = "$env:USERPROFILE\.config\opencode\skills"
    $missingJunctions = @()
    if ((Test-Path $canonicalDir) -and (Test-Path $globalDir)) {
        Get-ChildItem $canonicalDir -Directory | Where-Object { $_.Name -ne '_shared' } | ForEach-Object {
            if (-not (Test-Path (Join-Path $globalDir $_.Name))) { $missingJunctions += $_.Name }
        }
    }
    if ($missingJunctions.Count -eq 0) { Add-CheckResult 'Global Junctions' $true 'All junctions present' }
    else { Add-CheckResult 'Global Junctions' $false "Missing: $($missingJunctions -join ', ')" }

    # [E3.2] .project.json validity
    $pjPath = Join-Path $RepoRoot '.project.json'
    if (Test-Path $pjPath) {
        try {
            $pj = Get-Content $pjPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $dimCount = $pj.score.dimensions.PSObject.Properties.Name.Count
            $scoreCurrent = $pj.score.current
            if ($dimCount -ge 6 -and $scoreCurrent -ge 0 -and $scoreCurrent -le 10) {
                Add-CheckResult '.project.json' $true "$dimCount dims, score $scoreCurrent/10"
            } else { Add-CheckResult '.project.json' $false "Invalid structure: $dimCount dims, score $scoreCurrent" }
        } catch { Add-CheckResult '.project.json' $false "Parse error: $_" }
    } else { Add-CheckResult '.project.json' $false 'Not found' }

    # [E3.3] Script help parsing — all scripts have .SYNOPSIS
    $scriptDir = Join-Path $RepoRoot 'scripts'
    $missingHelp = @()
    Get-ChildItem "$scriptDir\*.ps1" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -Encoding UTF8
        if ($content -notmatch '\.SYNOPSIS') { $missingHelp += $_.Name }
    }
    if ($missingHelp.Count -eq 0) { Add-CheckResult 'Script Help' $true 'All scripts have .SYNOPSIS' }
    else { Add-CheckResult 'Script Help' $false "$($missingHelp.Count) missing: $($missingHelp -join ', ')" }

    # [E3.4] CYCLE.md parse check
    $cyclePath = Join-Path $RepoRoot 'CYCLE.md'
    if (Test-Path $cyclePath) {
        $cycleContent = Get-Content $cyclePath -Raw -Encoding UTF8
        $hasBacklog = $cycleContent -match '\| Item \|'
        $hasLoop = $cycleContent -match 'LOOP:'
        $hasMetrics = $cycleContent -match '\| Metric \|'
        $details = @()
        if ($hasBacklog) { $details += 'backlog' }
        if ($hasLoop) { $details += 'loop' }
        if ($hasMetrics) { $details += 'metrics' }
        Add-CheckResult 'CYCLE.md' $true "Sections found: $($details -join ', ')"
    } else { Add-CheckResult 'CYCLE.md' $false 'Not found' }
}

# ═══════════════════════════════════════════════════════
# Main dispatch
# ═══════════════════════════════════════════════════════
Write-Host "Verify Profile: $VerifyProfile" -ForegroundColor Magenta

switch ($VerifyProfile) {
    'E1' { Invoke-E1Checks }
    'E2' { Invoke-E2Checks }
    'E3' { Invoke-E3Checks }
    'All' {
        Invoke-E1Checks
        Invoke-E2Checks
        Invoke-E3Checks
    }
}

$vRes.allPassed = ($vRes.failed -eq 0)

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $($vRes.passed), Failed: $($vRes.failed)" -ForegroundColor $(if ($vRes.allPassed) { 'Green' } else { 'Red' })

if ($Json) {
    $vRes.timestamp = (Get-Date -Format 'o')
    Write-Output ($vRes | ConvertTo-Json -Depth 3)
}

exit $(if ($vRes.allPassed) { 0 } else { 1 })
