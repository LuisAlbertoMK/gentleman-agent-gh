#requires -Version 7

<#
.SYNOPSIS
    Tests for C4d: 4-field return contract validation in check-subagent-output.ps1.
.DESCRIPTION
    Validates that Validate-AgentReturnContract correctly checks subagent output
    for all 4 required sections: Decision Taken, Files Changed, Key Findings, Nuance.
    Also tests end-to-end via pwsh invocation of the script with -AgentOutput.

    Run: Invoke-Pester .\scripts\tests\check-subagent-output.Tests.ps1
#>

Describe "Validate-AgentReturnContract — function logic (C4d)" {
    BeforeAll {
        # Inline copy of Validate-AgentReturnContract (C4d) — mirrors scripts/check-subagent-output.ps1
        function Validate-AgentReturnContract {
            param([string]$Output, [string]$AgentName = "unknown")
            $requiredHeaders = @('## Decision Taken', '## Files Changed', '## Key Findings', '## Nuance')
            $missing = @()
            $empty   = @()
            foreach ($h in $requiredHeaders) {
                if ($Output -notmatch [regex]::Escape($h)) { $missing += $h }
            }
            if ($missing.Count -eq 0) {
                $lines  = $Output -split '\r?\n'
                $current = ""
                $sections = @{}
                foreach ($line in $lines) {
                    if ($line -match '^## ') {
                        $current = $line
                        $sections[$current] = @()
                    } elseif ($current) {
                        $sections[$current] += $line
                    }
                }
                foreach ($h in $requiredHeaders) {
                    $content = $sections[$h]
                    if ($content) {
                        $hasContent = @($content | Where-Object { $_.Trim() })
                        if ($hasContent.Count -eq 0) { $empty += $h }
                    } else {
                        $empty += $h
                    }
                }
            }
            return [PSCustomObject]@{
                valid   = ($missing.Count -eq 0 -and $empty.Count -eq 0)
                agent   = $AgentName
                missing = $missing
                empty   = $empty
            }
        }
    }

    It "accepts valid 4-field output" {
        $out = @"
## Decision Taken
Implemented C4d fix
## Files Changed
src/utils.ts
## Key Findings
1. [HIGH] Finding — Evidence — Recommendation
## Nuance
Edge case noted
"@
        $r = Validate-AgentReturnContract -Output $out
        $r.valid   | Should -BeTrue
        $r.missing | Should -Be @()
        $r.empty   | Should -Be @()
    }

    It "detects missing Nuance section" {
        $out = @"
## Decision Taken
Done
## Files Changed
file.ts
## Key Findings
1. [HIGH] Finding
"@
        $r = Validate-AgentReturnContract -Output $out
        $r.valid   | Should -BeFalse
        $r.missing | Should -Contain '## Nuance'
    }

    It "detects empty Key Findings section (header present, no content)" {
        $out = @"
## Decision Taken
Done
## Files Changed
file.ts
## Key Findings

## Nuance
Note
"@
        $r = Validate-AgentReturnContract -Output $out
        $r.valid  | Should -BeFalse
        $r.empty  | Should -Contain '## Key Findings'
    }

    It "rejects completely empty output" {
        $r = Validate-AgentReturnContract -Output ""
        $r.valid   | Should -BeFalse
        $r.missing | Should -HaveCount 4
    }
}

Describe "check-subagent-output.ps1 — contract validation flag in Quiet mode (C4d)" {
    BeforeAll {
        $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'check-subagent-output.ps1'
    }

    BeforeEach {
        # Hermetic fixture: temp git repo with a committed base file + an untracked
        # file. The script fail-closes (exit 1, status=FAIL) on an EMPTY diff, so it
        # needs visible changes to reach contract validation — a real-repo dependency
        # made these tests flaky depending on CI working-tree state.
        #
        # GIT_* SANITIZATION: when this suite runs inside a git pre-commit hook,
        # git exports GIT_DIR/GIT_INDEX_FILE/GIT_WORK_TREE into the hook process.
        # Those variables override -C for every child git call (fixture setup AND
        # the script-under-test subprocess), redirecting them at the REAL repo and
        # producing empty-diff early exits. Strip them for the duration of each test.
        $script:savedGitEnv = @{}
        foreach ($v in 'GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_OBJECT_DIRECTORY') {
            if (Test-Path "Env:$v") { $script:savedGitEnv[$v] = [Environment]::GetEnvironmentVariable($v) }
            Remove-Item "Env:$v" -ErrorAction SilentlyContinue
        }
        # Unique path per test: $TestDrive may persist across Its within a run;
        # a fixed 'repo' name lets one test's leftover untracked files be silently
        # committed by the next test's `git add .` + `commit`, producing an
        # empty-status fixture and bogus empty-output failures.
        $script:fixtureRepo = Join-Path $TestDrive "repo-$([guid]::NewGuid().ToString('N').Substring(0, 8))"
        New-Item -ItemType Directory -Path $script:fixtureRepo -Force | Out-Null
        git -C $script:fixtureRepo init -q
        git -C $script:fixtureRepo config user.email "test@example.com"
        git -C $script:fixtureRepo config user.name "Test"
        Set-Content -Path (Join-Path $script:fixtureRepo 'base.txt') -Value 'base'
        git -C $script:fixtureRepo add .
        git -C $script:fixtureRepo commit -q -m "base"
        if ($LASTEXITCODE -ne 0) { throw "fixture base commit failed (exit $LASTEXITCODE)" }
        Set-Content -Path (Join-Path $script:fixtureRepo 'untracked.txt') -Value 'change'
    }

    AfterEach {
        foreach ($kv in $script:savedGitEnv.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($kv.Key, $kv.Value)
        }
    }

    It "reports contract_valid=true for well-formed output" {
        $valid = @'
## Decision Taken
Fix C4d
## Files Changed
src/x.ts
## Key Findings
1. [HIGH] f
## Nuance
ok
'@
        # SAFE transport: pass the agent output via -AgentOutputFile instead of an
        # inline -AgentOutput argument. Inline multiline arguments depend on the
        # caller's native argument-passing mode and get truncated at the first
        # newline under some hosts (e.g. the pre-commit gate), producing a binding
        # failure and empty stdout. File transport is environment-independent.
        $tmpFile = Join-Path $TestDrive 'agent_out.txt'
        Set-Content -Path $tmpFile -Value $valid
        $json = & pwsh -NoProfile -File $scriptPath -RepoRoot $script:fixtureRepo -Quiet -AgentOutputFile $tmpFile | ConvertFrom-Json -ErrorAction SilentlyContinue
        $json | Should -Not -BeNullOrEmpty
        $json.contract_valid | Should -BeTrue
    }

    It "reports contract_valid=false for missing Nuance" {
        $bad = @'
## Decision Taken
Fix
## Files Changed
src/x.ts
## Key Findings
1. [HIGH] f
'@
        $tmpFile = Join-Path $TestDrive 'agent_out_bad.txt'
        Set-Content -Path $tmpFile -Value $bad
        # SAFE transport: see note in the well-formed test above.
        $rawOut = & pwsh -NoProfile -File $scriptPath -RepoRoot $script:fixtureRepo -Quiet -AgentOutputFile $tmpFile 2>&1
        $json = $rawOut | ConvertFrom-Json -ErrorAction SilentlyContinue
        $json | Should -Not -BeNullOrEmpty -Because "cso must emit parseable JSON; got: $($rawOut -join ' | ')"
        $json.contract_valid | Should -BeFalse
    }

    It 'T5 -AgentOutputFile loads output from file and detects contract violation' {
        $badOutput = @'
## Decision Taken
did things
## Files Changed
- a.txt
## Key Findings
found stuff
'@
        $outFile = Join-Path $TestDrive 'agent-output.md'
        Set-Content -Path $outFile -Value $badOutput -Encoding UTF8
        Set-Content -Path (Join-Path $script:fixtureRepo 'new.txt') -Value 'x'
        $r = & pwsh -NoProfile -File $scriptPath -RepoRoot $script:fixtureRepo -BaseRef HEAD -AgentOutputFile $outFile -Quiet 2>&1
        $LASTEXITCODE | Should -Be 0
        $json = ($r | Where-Object { $_ -match '^\{' } | Select-Object -First 1) | ConvertFrom-Json
        $json.contract_valid | Should -BeFalse
        $json.contract_detail | Should -Match 'Nuance'
    }

    It 'T6 -ExpectedFiles multi-value via -Command binds all elements (regression: was silently dropped)' {
        # Reproduces the monitor/post-delegation -Command subprocess vector:
        # `pwsh -NoProfile -NoLogo -Command "& 'cso' -ExpectedFiles @('a','b')"`.
        # Previously the monitor built '-ExpectedFiles 'a' 'b' (space-joined),
        # which PS fails to bind to [string[]] under -Command — ExpectedFiles
        # arrived empty and missing files were never reported (silent pass).
        Set-Content -Path (Join-Path $script:fixtureRepo 'new.txt') -Value 'x'
        $baseRef = (git -C $script:fixtureRepo rev-parse HEAD).Trim()
        $csoCmd = "& '$scriptPath' -BaseRef '$baseRef' -RepoRoot '$script:fixtureRepo' -Quiet -ExpectedFiles @('new.txt','ghost-missing.txt')"
        $out = & pwsh -NoProfile -NoLogo -Command $csoCmd 2>&1
        $LASTEXITCODE | Should -Be 0   # ghost-missing.txt makes missing_expected nonempty, but status stays OK for missing_expected alone
        $json = ($out | Where-Object { $_ -match '^\{' } | Select-Object -First 1) | ConvertFrom-Json -ErrorAction SilentlyContinue
        $json | Should -Not -BeNullOrEmpty -Because "raw=$($out -join ' | ')"
        $json.missing_expected | Should -Contain 'ghost-missing.txt'
        $json.missing_expected | Should -NOT -Contain 'new.txt'
    }
}

