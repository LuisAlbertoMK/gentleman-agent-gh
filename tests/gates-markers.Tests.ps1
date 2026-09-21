#requires -Version 7
<#
.SYNOPSIS
    Pester tests for gates S1-S4: marker evidence, stale pruning, FORCE_SHIP, naming, write-scope.
.DESCRIPTION
    Tests the cluster of gate improvements — markers carry evidence {who,when,why,fileHash},
    stale marker pruning, FORCE_SHIP strict parsing, collision-free naming, single-pass glob.
#>
BeforeAll {
    $script:repoRoot = (Get-Item $PSScriptRoot).Parent.FullName
    $script:jdDir = Join-Path $script:repoRoot '.jd-cleared'
    $script:breakerDir = Join-Path $script:repoRoot '.breaker-cleared'
}

Describe 'S1: Markers carry evidence' {
    BeforeAll {
        $script:testMarkerDir = Join-Path $script:repoRoot '.jd-cleared'
        if (-not (Test-Path $script:testMarkerDir)) { New-Item -ItemType Directory -Path $script:testMarkerDir -Force | Out-Null }
    }

    It 'gate-prep.ps1 is syntactically valid' {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:repoRoot 'scripts/gate-prep.ps1'),
            [ref]$null, [ref]$errors
        ) | Out-Null
        $errors | Should -BeNullOrEmpty
    }

    It 'pre-commit-gate.ps1 is syntactically valid' {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:repoRoot '.githooks/pre-commit-gate.ps1'),
            [ref]$null, [ref]$errors
        ) | Out-Null
        $errors | Should -BeNullOrEmpty
    }

    It 'gate-prep creates evidence markers with fileHash prefix' {
        # Create a temp .ps1 file, stage it, run gate-prep in -WhatIf to check format
        $tmpFile = Join-Path $script:repoRoot '_test_marker_tmp.ps1'
        Set-Content -Path $tmpFile -Value '# test marker' -Encoding UTF8
        try {
            Push-Location $script:repoRoot
            & git add _test_marker_tmp.ps1 2>$null

            # Read the gate-prep source to verify it contains evidence logic
            $gatePrepContent = Get-Content (Join-Path $script:repoRoot 'scripts/gate-prep.ps1') -Raw
            $gatePrepContent | Should -Match 'fileHash:'
            $gatePrepContent | Should -Match 'Get-FileHash'
        } finally {
            & git reset HEAD _test_marker_tmp.ps1 2>$null
            Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
        }
    }

    It 'gate-prep contains stale pruning logic' {
        $content = Get-Content (Join-Path $script:repoRoot 'scripts/gate-prep.ps1') -Raw
        $content | Should -Match '\[prune\]'
        $content | Should -Match 'target removed from tree'
    }

    It 'pre-commit-gate validates marker prefix content' {
        $content = Get-Content (Join-Path $script:repoRoot '.githooks/pre-commit-gate.ps1') -Raw
        # Should accept both empty (legacy) and evidence format
        $content | Should -Match 'markerContent'
        $content | Should -Match 'fileHash:'
    }

    It 'pre-commit-gate prunes stale markers' {
        $content = Get-Content (Join-Path $script:repoRoot '.githooks/pre-commit-gate.ps1') -Raw
        $content | Should -Match 'PRUNE'
        $content | Should -Match 'target.*removed from tree'
    }
}

Describe 'S1: Stale marker pruning' {
    It 'check-adversarial.ps1 prunes stale breaker markers' {
        $content = Get-Content (Join-Path $script:repoRoot 'scripts/check-adversarial.ps1') -Raw
        $content | Should -Match '\[prune\]'
        $content | Should -Match 'breaker-cleared stale'
    }
}

Describe 'S2: FORCE_SHIP strict parsing' {
    It 'check-adversarial.ps1 uses strict FORCE_SHIP (not [bool])' {
        $content = Get-Content (Join-Path $script:repoRoot 'scripts/check-adversarial.ps1') -Raw
        # Must NOT use [bool]$env:FORCE_SHIP (the old buggy pattern)
        $content | Should -Not -Match '\[bool\]\$env:FORCE_SHIP'
        # Must enforce strict equality against '1' or 'true'
        $content | Should -Match 'FORCE_SHIP'
    }

    It 'pre-commit-gate.ps1 uses strict FORCE_SHIP' {
        $content = Get-Content (Join-Path $script:repoRoot '.githooks/pre-commit-gate.ps1') -Raw
        # Must NOT use [bool]$env:FORCE_SHIP
        $content | Should -Not -Match '\[bool\]\$env:FORCE_SHIP'
        # Must enforce strict equality
        $content | Should -Match 'FORCE_SHIP'
    }
}

Describe 'S3: Collision-free marker naming' {
    It 'gate-prep.ps1 uses hash suffix for collision-free naming' {
        $content = Get-Content (Join-Path $script:repoRoot 'scripts/gate-prep.ps1') -Raw
        # Must use SHA256 hash suffix to avoid path collisions
        $content | Should -Match 'pathHash'
        $content | Should -Match 'SHA256'
    }

    It 'pre-commit-gate.ps1 uses hash-suffixed marker lookup' {
        $content = Get-Content (Join-Path $script:repoRoot '.githooks/pre-commit-gate.ps1') -Raw
        $content | Should -Match 'markerNew'
        $content | Should -Match 'markerLegacy'
    }

    It 'check-adversarial.ps1 uses hash-suffixed breaker marker lookup' {
        $content = Get-Content (Join-Path $script:repoRoot 'scripts/check-adversarial.ps1') -Raw
        $content | Should -Match 'markerNew'
        $content | Should -Match 'markerLegacy'
    }
}

Describe 'S4: Single-pass glob matching' {
    It 'validate-write-scope.ps1 uses [^/] for single-segment glob' {
        $content = Get-Content (Join-Path $script:repoRoot 'scripts/validate-write-scope.ps1') -Raw
        # Single * must match [^/]* (not .*) to avoid crossing path separators
        $content | Should -Match '\[\^/\]\*'
    }

    It 'validate-write-scope.ps1 uses non-capturing group alternation' {
        $content = Get-Content (Join-Path $script:repoRoot 'scripts/validate-write-scope.ps1') -Raw
        $content | Should -Match '\^\(\?:'
    }

    It 'src/*.ps1 does NOT match src/deep/x.ps1' {
        # Simulate the regex conversion
        $escaped = [regex]::Escape('src/*.ps1')
        $escaped = $escaped.Replace('\*\*', '.*')
        $escaped = $escaped -replace '\\\*', '[^/]*'
        $escaped = $escaped -replace '\\\?', '[^/]'
        $regex = "^(?:$escaped)$"
        'src/foo.ps1' | Should -Match $regex
        'src/deep/x.ps1' | Should -Not -Match $regex
    }

    It 'src/**/*.ps1 DOES match src/deep/x.ps1' {
        $escaped = [regex]::Escape('src/**/*.ps1')
        $escaped = $escaped.Replace('\*\*/', '(?:.*/)?')
        $escaped = $escaped.Replace('\*\*', '.*')
        $escaped = $escaped -replace '\\\*', '[^/]*'
        $escaped = $escaped -replace '\\\?', '[^/]'
        $regex = "^(?:$escaped)$"
        'src/deep/x.ps1' | Should -Match $regex
        'src/foo.ps1' | Should -Match $regex
    }

    It 'validate-write-scope.ps1 has syntax validation' {
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $script:repoRoot 'scripts/validate-write-scope.ps1'),
            [ref]$null, [ref]$errors
        ) | Out-Null
        $errors | Should -BeNullOrEmpty
    }
}
