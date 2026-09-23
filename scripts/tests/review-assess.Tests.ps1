#requires -Version 5.1
<#
.SYNOPSIS
    Tests for review-assess.ps1 — fail-closed con fixtures de repos git reales.
.DESCRIPTION
    Pester 5 dash-style. B1: sin seams de entorno (el hook REVIEW_ASSESS_NUMSTAT y
    REVIEW_ASSESS_CONSUMED fueron eliminados); cada It crea un repo git temporal
    real (git init + commits) y evalua el script contra el. Requiere git + Pester
    5.5+ en pwsh para ejecucion.
#>

BeforeAll {
    $assessPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'review-assess.ps1'
    # PS-CI-03 remediation: allowlist validation — only .ps1 directly under scripts/
    $resolvedAssess = Resolve-Path -LiteralPath $assessPath -ErrorAction Stop
    if ([System.IO.Path]::GetExtension($resolvedAssess.Path) -ne '.ps1') { throw "Blocked: allowlist requires .ps1 ($assessPath)" }
    $scriptsDir = Resolve-Path -LiteralPath (Split-Path $PSScriptRoot -Parent) -ErrorAction Stop
    if (-not $resolvedAssess.Path.StartsWith($scriptsDir.Path, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Blocked: path outside scripts/ ($assessPath)" }
    $assessPath = $resolvedAssess.Path

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) { throw 'git is required for review-assess tests (real-repo fixtures)' }

    function New-AssessRepo {
        param([string]$Root)
        New-Item -ItemType Directory -Path $Root -Force | Out-Null
        Push-Location -LiteralPath $Root
        try {
            & git init -q 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'git init failed' }
            & git config user.email 'pester@example.com' 2>$null | Out-Null
            & git config user.name 'Pester' 2>$null | Out-Null
        }
        finally {
            Pop-Location
        }
        return $Root
    }

    function Add-AssessCommit {
        param(
            [string]$Root,
            [hashtable]$Files,
            [string]$Message = 'test commit'
        )
        Push-Location -LiteralPath $Root
        try {
            foreach ($k in $Files.Keys) {
                $fp = Join-Path $Root $k
                $dir = Split-Path $fp -Parent
                if (-not (Test-Path -LiteralPath $dir)) {
                    New-Item -ItemType Directory -Path $dir -Force | Out-Null
                }
                Set-Content -LiteralPath $fp -Value $Files[$k] -Encoding UTF8
            }
            & git add -A 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
            & git commit -q -m "$Message" 2>$null | Out-Null
            if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
        }
        finally {
            Pop-Location
        }
    }

    function Get-AssessSha {
        param([string]$Root, [string]$Ref)
        Push-Location -LiteralPath $Root
        try {
            $sha = & git rev-parse --verify --quiet "$Ref" 2>$null
            if ($LASTEXITCODE -ne 0) { throw "cannot resolve $Ref in fixture repo" }
            return (("$sha" -split "`r?`n")[0]).Trim()
        }
        finally {
            Pop-Location
        }
    }

    function Invoke-Assess {
        param([string]$Root, [string]$BaseRef)
        Push-Location -LiteralPath $Root
        try {
            $line = & "$assessPath" -BaseRef "$BaseRef" | Where-Object { $_ -match '^\{' } | Select-Object -First 1
        }
        finally {
            Pop-Location
        }
        return ($line | ConvertFrom-Json)
    }
}

Describe 'review-assess.ps1' {
    It 'marks high_risk scripts/** as review due' {
        $repo = New-AssessRepo -Root (Join-Path $TestDrive 'repo-high-risk')
        Add-AssessCommit -Root $repo -Files @{ 'README.md' = 'base' }
        Add-AssessCommit -Root $repo -Files @{ 'scripts/foo.ps1' = 'Write-Output hi' }
        $json = Invoke-Assess -Root $repo -BaseRef 'HEAD~1'
        $json.review_due | Should -BeTrue
        $json.review_due_reason | Should -Be 'high_risk'
    }

    It 'marks slice_budget_reached as due with 2+ non-trivial files' {
        $repo = New-AssessRepo -Root (Join-Path $TestDrive 'repo-slice')
        Add-AssessCommit -Root $repo -Files @{ 'README.md' = 'base' }
        Add-AssessCommit -Root $repo -Files @{ 'src/a.js' = 'var a = 1;'; 'src/b.js' = 'var b = 2;' }
        $json = Invoke-Assess -Root $repo -BaseRef 'HEAD~1'
        $json.review_due | Should -BeTrue
        $json.review_due_reason | Should -Be 'slice_budget_reached'
    }

    It 'marks a single non-trivial file as due' {
        $repo = New-AssessRepo -Root (Join-Path $TestDrive 'repo-single')
        Add-AssessCommit -Root $repo -Files @{ 'README.md' = 'base' }
        Add-AssessCommit -Root $repo -Files @{ 'src/only-one.js' = 'var a = 1;' }
        $json = Invoke-Assess -Root $repo -BaseRef 'HEAD~1'
        $json.review_due | Should -BeTrue
        $json.review_due_reason | Should -Be 'slice_budget_reached'
    }

    It 'returns no-due when only trivial files changed' {
        $repo = New-AssessRepo -Root (Join-Path $TestDrive 'repo-trivial')
        Add-AssessCommit -Root $repo -Files @{ 'README.md' = 'base' }
        Add-AssessCommit -Root $repo -Files @{ 'docs/notes.md' = 'just docs' }
        $json = Invoke-Assess -Root $repo -BaseRef 'HEAD~1'
        $json.review_due | Should -Be $false
        $json.review_due_reason | Should -Be 'under_budget'
    }

    It 'returns no-due when the candidate sha is in the repo-local store' {
        $repo = New-AssessRepo -Root (Join-Path $TestDrive 'repo-consumed')
        Add-AssessCommit -Root $repo -Files @{ 'README.md' = 'base' }
        Add-AssessCommit -Root $repo -Files @{ 'scripts/foo.ps1' = 'Write-Output hi' }
        $sha = Get-AssessSha -Root $repo -Ref 'HEAD~1'
        $storeDir = Join-Path $repo '.gentleman'
        New-Item -ItemType Directory -Path $storeDir -Force | Out-Null
        $map = @{}
        $map[$sha] = @{ consumed_at = '2026-09-23T00:00:00Z'; by = 'pester' }
        ($map | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath (Join-Path $storeDir 'review-consumed.json') -Encoding UTF8
        $json = Invoke-Assess -Root $repo -BaseRef 'HEAD~1'
        $json.candidate_consumed | Should -BeTrue
        $json.review_due | Should -Be $false
        $json.review_due_reason | Should -Be 'already_reviewed'
    }

    It 'embeds the BaseRef verbatim in next_transition when due' {
        $repo = New-AssessRepo -Root (Join-Path $TestDrive 'repo-next')
        Add-AssessCommit -Root $repo -Files @{ 'README.md' = 'base' }
        Add-AssessCommit -Root $repo -Files @{ 'src/a.js' = 'var a = 1;'; 'src/b.js' = 'var b = 2;' }
        $json = Invoke-Assess -Root $repo -BaseRef 'HEAD~1'
        $json.next_transition | Should -Match 'review-status\.ps1'
        $json.next_transition | Should -Match 'HEAD~1'
    }

    It 'fails closed (throw) on an unresolvable BaseRef' {
        $repo = New-AssessRepo -Root (Join-Path $TestDrive 'repo-badref')
        Add-AssessCommit -Root $repo -Files @{ 'README.md' = 'base' }
        { Invoke-Assess -Root $repo -BaseRef 'nonexistent-ref-zzz' } | Should -Throw '*fail-closed*'
    }
}
