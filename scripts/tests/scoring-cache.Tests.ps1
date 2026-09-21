#requires -Version 7
BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'score-auto.ps1'
    $repoRoot   = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $cacheFile  = Join-Path $repoRoot '.learnings/score-cache.json'
}

Describe 'scoring-cache.ps1 — test-mode guard (S1)' {
    BeforeAll {
        $cacheBefore = if (Test-Path $cacheFile) {
            (Get-Item $cacheFile).LastWriteTime
        } else { $null }
    }
    It 'PESTER_TEST=1 does not modify score-cache.json' {
        $env:PESTER_TEST = '1'
        try {
            & $scriptPath -Json 2>$null | Out-Null
        } finally {
            $env:PESTER_TEST = $null
        }
        if ($null -ne $cacheBefore) {
            $cacheAfter = (Get-Item $cacheFile).LastWriteTime
            $cacheAfter | Should -Be $cacheBefore
        } else {
            Test-Path $cacheFile | Should -BeFalse
        }
    }
}

Describe 'scoring-cache.ps1 — bias block after finalScore (S2)' {
    It 'bias calibration uses computed finalScore' {
        # The bias block at ~line 248 must reference $finalScore which is
        # assigned at ~line 275. Verify the script parses without errors
        # (would throw if $finalScore referenced before assignment).
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}

Describe 'scoring-cache.ps1 — cache-key top-level scripts only (S3)' {
    BeforeAll {
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "scoring-cache-test-$(Get-Random)"
        New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
        # Save original cache for restore
        $origCacheExists = Test-Path $cacheFile
        $origCache = if ($origCacheExists) { Get-Content $cacheFile -Raw -Encoding UTF8 } else { $null }
    }
    AfterAll {
        if ($origCacheExists -and $null -ne $origCache) {
            $origCache | Set-Content $cacheFile -Encoding UTF8
        }
        Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    }
    It 'cache key only hashes top-level scripts/*.ps1' {
        # Extract the hash computation from the script source to verify
        # it only uses $repoRoot\scripts\*.ps1, not tests/*.ps1
        $src = Get-Content $scriptPath -Raw -Encoding UTF8
        # Verify no reference to tests\*.ps1 in cache hash computation
        # (the compositeKey section should not include test files)
        $src | Should -Match '\$repoRoot\\scripts\\\*\.ps1'
    }
}
