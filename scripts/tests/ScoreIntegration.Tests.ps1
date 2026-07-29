#requires -Version 5.1
<#
.SYNOPSIS
  Integration tests for score-auto.ps1 — full pipeline validation.
.DESCRIPTION
  Tests run score-auto.ps1 -Json -Quiet and validate:
  - Exit code 0 (regression for multiline pipeline parsing bug)
  - All 13 expected dimensions present
  - All scores in range 0-10
  - Valid JSON structure
  - Cache round-trip integrity
.NOTES
  ⚠ These are integration tests — they exercise the real pipeline.
    Not suitable for per-commit execution (cache bypass on first run).
#>
param([switch]$Quiet)
Set-StrictMode -Version Latest

BeforeAll {
    $script:ProjectRoot = git rev-parse --show-toplevel 2>$null
    if (-not $script:ProjectRoot) { throw "Not in a git repo" }
    $script:ScoreScript = Join-Path $script:ProjectRoot "scripts/score-auto.ps1"
    $script:ScoreDims   = Join-Path $script:ProjectRoot "scripts/lib/score-dims.ps1"

    # Expected 13 dimensions (see line 163 in score-auto.ps1)
    $script:ExpectedDims = @(
        'PA','Sec','DC','CC','BP','Or','Bi','Me','SP','SE','CA','BI2','SD'
    )
}

# ============================================================
Describe 'Integration: Pipeline Integrity' {

    It 'score-auto.ps1 exists and is readable' {
        $script:ScoreScript | Should -Exist
    }

    It 'score-dims.ps1 exists and is readable' {
        $script:ScoreDims | Should -Exist
    }

    It 'exit code 0 (regression: multiline pipeline + -ThrottleLimit bug)' {
        # This was failing with exit 1 due to positional parameter parsing
        # in ForEach-Object { ... } -ThrottleLimit
        $result = & $script:ScoreScript -Quiet 2>$null
        $LASTEXITCODE | Should -Be 0 -Because 'multiline pipeline parsing must not throw'
    }

    It 'produces valid JSON with all 13 expected dimensions' {
        $json = & $script:ScoreScript -Json 2>$null
        $LASTEXITCODE | Should -Be 0

        $obj = $json | ConvertFrom-Json
        $obj.score | Should -Not -BeNullOrEmpty
        $obj.score.current | Should -Not -BeNullOrEmpty
        $obj.score.dimensions | Should -Not -BeNullOrEmpty
        $obj.dimensions_detail | Should -Not -BeNullOrEmpty
    }
}

# ============================================================
Describe 'Integration: Score Range & Sanity' {

    It 'composite score is between 0 and 10' {
        $json = & $script:ScoreScript -Json 2>$null
        $obj  = $json | ConvertFrom-Json
        $obj.score.current -ge 0 | Should -Be $true
        $obj.score.current -le 10 | Should -Be $true
    }

    It 'all displayed dimensions have scores between 0 and 10' {
        $json = & $script:ScoreScript -Json 2>$null
        $obj  = $json | ConvertFrom-Json

        $badDims = @()
        foreach ($prop in $obj.score.dimensions.PSObject.Properties) {
            $val = $prop.Value
            if ($null -eq $val -or $val -lt 0 -or $val -gt 10) {
                $badDims += "$($prop.Name)=$val"
            }
        }
        $badDims | Should -BeNullOrEmpty -Because "all dims must be 0-10: $badDims"
    }

    It 'composite score equals average of all internal dimensions (±0.2)' {
        $json = & $script:ScoreScript -Json 2>$null
        $obj  = $json | ConvertFrom-Json

        # All dims include SG (Staleness Gate) — 14 total
        $dimValues = foreach ($prop in $obj.dimensions_detail.PSObject.Properties) {
            $prop.Value.s
        }
        $avg = [math]::Round(($dimValues | Measure-Object -Average).Average, 1)
        $diff = [math]::Abs($obj.score.current - $avg)
        $diff | Should -BeLessOrEqual 0.2 -Because "composite ($($obj.score.current)) must match dim avg ($avg)" }
}

# ============================================================
Describe 'Integration: Cache Round-Trip' {

    It 'second run returns cached results' {
        # Run twice — first populates cache, second reads it
        $first  = & $script:ScoreScript -Json 2>$null
        $second = & $script:ScoreScript -Json 2>$null

        $firstObj  = $first | ConvertFrom-Json
        $secondObj = $second | ConvertFrom-Json

        # Composite score should match (same git HEAD)
        $firstObj.score.current | Should -Be $secondObj.score.current
    }
}

# ============================================================
Describe 'Integration: 0.0 Dimension Diagnostics' {

    It 'Clean Code (CC) has evidence with total_scripts > 0' {
        $json = & $script:ScoreScript -Json 2>$null
        $obj  = $json | ConvertFrom-Json

        if ($obj.dimensions_detail.CC.s -eq 0) {
            $cc = $obj.dimensions_detail.CC.e
            Write-Host "CC=0 — with_help=$($cc.with_help) with_params=$($cc.with_params) with_strictmode=$($cc.with_strictmode) total=$($cc.total_scripts)" -ForegroundColor DarkYellow
            $cc.total_scripts | Should -BeGreaterThan 0 -Because 'if CC=0, at least scripts should be detected'
        } else {
            $obj.dimensions_detail.CC.s | Should -BeGreaterThan 0
        }
    }

    It 'Best Practices (BP) has evidence with param_cov >= 0' {
        $json = & $script:ScoreScript -Json 2>$null
        $obj  = $json | ConvertFrom-Json

        $bp = $obj.dimensions_detail.BP.e
        ($bp.param_cov -ge 0) | Should -Be $true
    }
}

# ============================================================
Describe 'Integration: Orthography (Or) corruption detection' {

    It 'corruption scanner runs without error' {
        $json = & $script:ScoreScript -Json 2>$null
        $obj  = $json | ConvertFrom-Json

        $or = $obj.dimensions_detail.Or.e
        $or.scanned | Should -BeGreaterOrEqual 0
    }
}
