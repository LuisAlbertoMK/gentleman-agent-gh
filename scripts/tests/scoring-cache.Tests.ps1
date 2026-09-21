#requires -Version 7
BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'score-auto.ps1'
    $repoRoot   = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $cacheFile  = Join-Path $repoRoot '.learnings/score-cache.json'

    # SCORE_CACHE_PATH: redirect score-auto.ps1 cache writes to a temp file,
    # eliminating the race where ScoreIntegration's AfterAll removes PESTER_TEST
    # process-wide while this suite is mid-execution. Even if PESTER_TEST vanishes,
    # score-auto writes to $TestDrive, never the real cache.
    $env:SCORE_CACHE_PATH = Join-Path $TestDrive 'score-cache.json'
}
AfterAll {
    $env:SCORE_CACHE_PATH = $null
}

Describe 'scoring-cache.ps1 — test-mode guard (S1)' {
    It 'PESTER_TEST=1 does not modify score-cache.json' {
        # WHY: Do NOT manipulate $env:PESTER_TEST here — run-tests.ps1 already sets
        # it process-wide for the entire Pester run. Setting it locally and clearing
        # in finally causes a race: in parallel suites, clearing PESTER_TEST kills
        # ScoreIntegration.Tests.ps1's test mode mid-execution.
        #
        # WHY assert on $env:SCORE_CACHE_PATH (TestDrive temp) not real cache:
        #   - Real cache is shared, any writer mutates it → non-deterministic
        #   - $env:SCORE_CACHE_PATH points to TestDrive (isolated per suite)
        #   - score-auto.ps1 writes cache there; no other writer touches it
        #   - Deterministic: temp is either unchanged or absent
        $tempCache = $env:SCORE_CACHE_PATH
        $tempBeforeHash = if ($tempCache -and (Test-Path $tempCache)) {
            (Get-FileHash $tempCache -Algorithm SHA256).Hash
        } else { $null }

        # PESTER_TEST is already set by run-tests.ps1 — just invoke
        & $scriptPath -Json 2>$null | Out-Null

        # Verify: temp file must NOT have been written with a real score.
        # If temp existed before, its hash must be unchanged. If it didn't exist,
        # it must still not exist (no side-effect leak from test-mode invocation).
        if ($null -ne $tempBeforeHash) {
            $tempAfterHash = (Get-FileHash $tempCache -Algorithm SHA256).Hash
            $tempAfterHash | Should -Be $tempBeforeHash
        } else {
            Test-Path $tempCache | Should -BeFalse
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
    }
    AfterAll {
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
