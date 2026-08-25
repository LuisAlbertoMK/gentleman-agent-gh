#requires -Version 7
<#
.SYNOPSIS
    Async delegation resilience tests — closes test gaps identified in
    docs/mejoras/2026-08-19-async-delegation-analysis.md (finding #11):

    1. Concurrent delegations — result/PID file isolation per task
    2. Monitor crash / orphan lifecycle — PID write + cleanup + stale detection
    3. False stability — out-of-scope external changes must NOT reset or pollute
       the convergence signal (scope filter, rec #5)

    Run: Invoke-Pester scripts\tests\async-resilience.Tests.ps1
#>

Describe "Async delegation resilience (concurrency / crash / false-stability)" {
    BeforeAll {
        $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)  # repo root
        $sdir = Join-Path $root 'scripts'
        $monitorSrc = Get-Content (Join-Path $sdir 'monitor-subagent.ps1') -Raw
        $babyagiSrc = Get-Content (Join-Path $sdir 'babyagi-loop.ps1') -Raw
        $registrySrc = Get-Content (Join-Path $sdir 'delegation-registry.ps1') -Raw
    }

    # --- Scenario 1: Concurrent delegations ---

    Context "Concurrent delegation isolation" {
        It "babyagi names result file per taskRef (no shared collision name)" {
            $babyagiSrc | Should -Match '\$\{taskRef\}\.async-result\.json'
        }

        It "monitor prefers TaskId for its own result file (rec #10: direct-call concurrency)" {
            $monitorSrc | Should -Match 'if \(\$TaskId\) \{ "\$fileSafeTask\.async-result\.json" \}'
        }

        It "monitor falls back to BaseRef naming without TaskId (backward compat)" {
            $monitorSrc | Should -Match '"\$fileSafeBase\.async-result\.json"'
        }

        It "BEHAVIORAL: with -TaskId the result lands in {TaskId}.async-result.json, not {BaseRef}" {
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("async-tid-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
            try {
                New-Item -ItemType Directory -Path (Join-Path $tmp 'src') -Force | Out-Null
                git -C $tmp init --quiet 2>$null
                Set-Content -Path (Join-Path $tmp 'src/.keep') -Value ''
                git -C $tmp add . 2>$null
                git -C $tmp -c user.name=t -c user.email=t@t.local commit --quiet -m init 2>$null
                Set-Content -Path (Join-Path $tmp 'src/change.txt') -Value 'x'

                $outLog = Join-Path $tmp 'm-out.log'; $errLog = Join-Path $tmp 'm-err.log'
                $proc = Start-Process -FilePath 'pwsh' -ArgumentList @(
                    '-NoProfile', '-NoLogo', '-File', (Join-Path $sdir 'monitor-subagent.ps1'),
                    '-RepoRoot', $tmp, '-BaseRef', 'HEAD', '-TaskId', 'taskA_1',
                    '-AllowedPaths', 'src/*',
                    '-PollIntervalSec', '1', '-MaxWaitSec', '30',
                    '-WriteResultFile'
                ) -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru -WindowStyle Hidden
                if (-not $proc.WaitForExit(60000)) { $proc.Kill(); throw "monitor did not converge within 60s" }

                Test-Path (Join-Path $tmp 'taskA_1.async-result.json') | Should -BeTrue -Because "TaskId naming must win"
                Test-Path (Join-Path $tmp 'HEAD.async-result.json') | Should -BeFalse -Because "BaseRef file must not be created when TaskId is set"
            } finally {
                Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "monitor PID file is TaskId-scoped (concurrent monitors don't overwrite each other)" {
            $monitorSrc | Should -Match 'async-monitor-\$TaskId\.pid'
        }

        It "registry cancel targets only its own TaskId PID file" {
            $registrySrc | Should -Match 'async-monitor-\$TaskId\.pid'
        }

        It "result JSON carries schema_version for concurrent-writer detectability" {
            $monitorSrc | Should -Match 'schema_version\s*=\s*1'
        }
    }

    # --- Scenario 2: Monitor crash / orphan lifecycle ---

    Context "Monitor orphan lifecycle" {
        It "monitor writes its PID before polling (crash leaves trace)" {
            $monitorSrc | Should -Match 'Set-Content -Path \$pidFile -Value \$PID'
        }

        It "monitor warns on stale PID file instead of silently overwriting" {
            $monitorSrc | Should -Match 'stale PID file exists'
        }

        It "monitor removes PID file after completion (no orphan registration)" {
            $monitorSrc | Should -Match 'remove PID file if created'
            $monitorSrc | Should -Match 'Remove-Item -LiteralPath \$pidFile'
        }

        It "PID cleanup happens AFTER callback invocation (callback failure cannot orphan PID)" {
            $callbackIdx = $monitorSrc.IndexOf('& $CompletionCallback -ResultJson')
            $cleanupIdx  = $monitorSrc.IndexOf('Remove-Item -LiteralPath $pidFile')
            $callbackIdx | Should -BeGreaterThan -1
            $cleanupIdx  | Should -BeGreaterThan -1
            $cleanupIdx  | Should -BeGreaterThan $callbackIdx
        }

        It "registry cancel verifies process identity before kill (PID reuse protection)" {
            $registrySrc | Should -Match 'isMonitor'
            $registrySrc | Should -Match 'PID reuse protection'
        }
    }

    # --- Scenario 3: False stability from external commits ---

    Context "False stability protection (scope filter)" {
        It "monitor filters stability signal by AllowedPaths (rec #5)" {
            $monitorSrc | Should -Match 'Scope-filter the stability signal'
            $monitorSrc | Should -Match '\$file -like \$_'
        }

        It "scope filter is guarded: without AllowedPaths behavior is unchanged" {
            # The filter block must sit behind an emptiness guard
            $monitorSrc | Should -Match '(?s)if \(\$AllowedPaths\) \{[^}]*\$file -like'
        }

        It "BEHAVIORAL: out-of-scope changes are excluded from convergence signal" {
            $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("async-resil-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
            try {
                New-Item -ItemType Directory -Path (Join-Path $tmp 'src') -Force | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $tmp 'docs') -Force | Out-Null
                git -C $tmp init --quiet 2>$null
                # Track parent dirs so later files appear INDIVIDUALLY in git status
                # (untracked dirs collapse to '?? src/' which breaks per-file asserts)
                Set-Content -Path (Join-Path $tmp 'src/.keep') -Value ''
                Set-Content -Path (Join-Path $tmp 'docs/.keep') -Value ''
                git -C $tmp add . 2>$null
                git -C $tmp -c user.name=t -c user.email=t@t.local commit --quiet -m init 2>$null

                # Pre-created changes (deterministic): one in-scope, one external
                Set-Content -Path (Join-Path $tmp 'src/in-scope.txt') -Value 'a'
                Set-Content -Path (Join-Path $tmp 'docs/out-of-scope.txt') -Value 'b'

                $outLog = Join-Path $tmp 'monitor-out.log'
                $errLog = Join-Path $tmp 'monitor-err.log'
                $proc = Start-Process -FilePath 'pwsh' -ArgumentList @(
                    '-NoProfile', '-NoLogo', '-File', (Join-Path $sdir 'monitor-subagent.ps1'),
                    '-RepoRoot', $tmp, '-BaseRef', 'HEAD',
                    '-AllowedPaths', 'src/*',
                    '-PollIntervalSec', '1', '-MaxWaitSec', '30',
                    '-WriteResultFile'
                ) -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru -WindowStyle Hidden

                $exited = $proc.WaitForExit(60000)
                if (-not $exited) { $proc.Kill(); throw "monitor did not converge within 60s" }

                $resultFile = Join-Path $tmp 'HEAD.async-result.json'
                Test-Path $resultFile | Should -BeTrue -Because "monitor must write result file"
                $result = Get-Content $resultFile -Raw | ConvertFrom-Json

                # NOTE: status may legitimately be FAIL here — validate-write-scope
                # independently flags out-of-scope working-tree changes (correct
                # behavior, orthogonal to this test). What we verify is that the
                # STABILITY SIGNAL itself converged and was correctly scoped.
                $result.reason | Should -Be 'stable'
                ($result.changed_files -contains 'src/in-scope.txt') | Should -BeTrue -Because "in-scope change must appear: $($result.changed_files -join ', ')"
                ($result.changed_files -contains 'docs/out-of-scope.txt') | Should -BeFalse -Because "external change must be filtered out: $($result.changed_files -join ', ')"
            } finally {
                Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It "All touched scripts pass syntax check (0 parse errors)" {
        foreach ($f in @('monitor-subagent.ps1', 'babyagi-loop.ps1', 'delegation-registry.ps1')) {
            $tokens = $null; $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile(
                (Join-Path $sdir $f), [ref]$tokens, [ref]$errors) | Out-Null
            $errors.Count | Should -Be 0 -Because "$f has $($errors.Count) parse errors"
        }
    }
}
