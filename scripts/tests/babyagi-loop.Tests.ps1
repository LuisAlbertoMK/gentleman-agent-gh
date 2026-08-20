#requires -Version 7

<#
.SYNOPSIS
    Tests for babyagi-loop.ps1 — parameter validation, fail-closed guard,
    DryRun acceptance, task creation heuristic, and prioritization.
#>

BeforeAll {
    $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'babyagi-loop.ps1'
}

# ---------------------------------------------------------------------------
# 1. Syntax validation
# ---------------------------------------------------------------------------
Describe "babyagi-loop.ps1 — syntax validation" {
    It "script has no parse errors" {
        $tokens = $null; $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
}

# ---------------------------------------------------------------------------
# 2. Fail-closed guard: -AllowedPaths is mandatory
# ---------------------------------------------------------------------------
Describe "babyagi-loop.ps1 — fail-closed guard" {
    It "exits 1 when -AllowedPaths is missing" {
        $null = & pwsh -NoProfile -Command "& '$scriptPath' -Goal 'test'" 2>$null
        $LASTEXITCODE | Should -Be 1
    }

    It "exits 1 when -AllowedPaths is empty" {
        $null = & pwsh -NoProfile -Command "& '$scriptPath' -Goal 'test' -AllowedPaths @()" 2>$null
        $LASTEXITCODE | Should -Be 1
    }
}

# ---------------------------------------------------------------------------
# 3. Parameter validation: missing Mandatory -Goal
# ---------------------------------------------------------------------------
Describe "babyagi-loop.ps1 — parameter validation" {
    It "exits 1 when -Goal is missing" {
        $null = & pwsh -NoProfile -Command "& '$scriptPath' -AllowedPaths 'src/*'" 2>$null
        $LASTEXITCODE | Should -Be 1
    }
}

# ---------------------------------------------------------------------------
# 4. Missing Phase 1 dependency: post-delegation-check.ps1
# ---------------------------------------------------------------------------
Describe "babyagi-loop.ps1 — missing dependency" {
    It "exits 1 when post-delegation-check.ps1 is absent" {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "babyagi-test-$(Get-Random)"
        try {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            $tempScript = Join-Path $tempDir "babyagi-loop.ps1"
            Copy-Item $scriptPath $tempScript -Force

            $null = & pwsh -NoProfile -Command "& '$tempScript' -Goal 'test' -AllowedPaths 'src/*'" 2>$null
            $LASTEXITCODE | Should -Be 1
        }
        finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# 5. DryRun parameter acceptance (BABYAGI_TEST_MODE skips the real loop)
# ---------------------------------------------------------------------------
Describe "babyagi-loop.ps1 — DryRun mode" {
    It "accepts -DryRun without error when loop is skipped" {
        $env:BABYAGI_TEST_MODE = "1"
        try {
            $null = & pwsh -NoProfile -Command "& '$scriptPath' -Goal 'test goal' -AllowedPaths 'src/*' -DryRun" 2>&1
            $LASTEXITCODE | Should -Be 0
        }
        finally {
            $env:BABYAGI_TEST_MODE = $null
        }
    }
}

# ---------------------------------------------------------------------------
# 6. New-InitialTasks heuristic: goal splitting
# ---------------------------------------------------------------------------
Describe "babyagi-loop.ps1 — New-InitialTasks heuristic" {
    BeforeAll {
        $env:BABYAGI_TEST_MODE = "1"
        . $scriptPath -Goal "dummy" -AllowedPaths "src/*"
    }

    AfterAll {
        $env:BABYAGI_TEST_MODE = $null
    }

    It "splits goal by ' and ' connector" {
        $tasks = New-InitialTasks -GoalText "review auth tests and fix login bugs"
        $tasks.Count | Should -Be 2
        $tasks[0].description | Should -Be "review auth tests"
        $tasks[1].description | Should -Be "fix login bugs"
    }

    It "splits goal by ' then ' connector" {
        $tasks = New-InitialTasks -GoalText "scan the repo then update docs"
        $tasks.Count | Should -Be 2
        $tasks[0].description | Should -Be "scan the repo"
        $tasks[1].description | Should -Be "update docs"
    }

    It "splits goal by ' ; ' connector (space-semicolon-space)" {
        $tasks = New-InitialTasks -GoalText "run tests ; fix failures"
        $tasks.Count | Should -Be 2
        $tasks[0].description | Should -Be "run tests"
        $tasks[1].description | Should -Be "fix failures"
    }

    It "splits goal by ', ' connector" {
        $tasks = New-InitialTasks -GoalText "add tests, update README"
        $tasks.Count | Should -Be 2
        $tasks[0].description | Should -Be "add tests"
        $tasks[1].description | Should -Be "update README"
    }

    It "creates fallback task for simple unsplit goal" {
        $tasks = New-InitialTasks -GoalText "review everything"
        $tasks.Count | Should -Be 1
        $tasks[0].id | Should -Be "task_1"
        $tasks[0].description | Should -Be "review everything"
    }

    It "assigns high complexity and priority for audit keywords" {
        $tasks = New-InitialTasks -GoalText "comprehensive scan of all auth code"
        $tasks.Count | Should -BeGreaterOrEqual 1
        $tasks[0].complexity | Should -Be "high"
        $tasks[0].priority | Should -Be 9
    }

    It "assigns medium complexity for fix/add keywords" {
        $tasks = New-InitialTasks -GoalText "fix the login handler"
        $tasks.Count | Should -BeGreaterOrEqual 1
        $tasks[0].complexity | Should -Be "medium"
        $tasks[0].priority | Should -Be 6
    }

    It "assigns low complexity for simple actions" {
        $tasks = New-InitialTasks -GoalText "read the config file"
        $tasks.Count | Should -BeGreaterOrEqual 1
        $tasks[0].complexity | Should -Be "low"
        $tasks[0].priority | Should -Be 3
    }

    It "trims whitespace from split parts" {
        $tasks = New-InitialTasks -GoalText "task one  and  task two"
        $tasks.Count | Should -Be 2
        $tasks[0].description | Should -Not -Match "^\s"
        $tasks[1].description | Should -Not -Match "^\s"
    }

    It "filters out short fragments (<= 5 chars)" {
        $tasks = New-InitialTasks -GoalText "do it and review the full auth module"
        # "do it" is 5 chars exactly — should be filtered out by Where-Object { $_.Length -gt 5 }
        $tasks.Count | Should -Be 1
        $tasks[0].description | Should -Be "review the full auth module"
    }
}

# ---------------------------------------------------------------------------
# 7. Sort-TaskQueue: prioritization
# ---------------------------------------------------------------------------
Describe "babyagi-loop.ps1 — Sort-TaskQueue" {
    BeforeAll {
        $env:BABYAGI_TEST_MODE = "1"
        . $scriptPath -Goal "dummy" -AllowedPaths "src/*"
    }

    AfterAll {
        $env:BABYAGI_TEST_MODE = $null
    }

    It "sorts tasks by priority descending" {
        $tasks = @(
            [PSCustomObject]@{ id = "low";  description = "low";  priority = 3; complexity = "low";    status = "pending" }
            [PSCustomObject]@{ id = "high"; description = "high"; priority = 9; complexity = "high";   status = "pending" }
            [PSCustomObject]@{ id = "mid";  description = "mid";  priority = 6; complexity = "medium"; status = "pending" }
        )
        $sorted = Sort-TaskQueue -Tasks $tasks
        $sorted[0].id | Should -Be "high"
        $sorted[1].id | Should -Be "mid"
        $sorted[2].id | Should -Be "low"
    }

    It "uses complexity as tiebreaker (alphabetical ascending)" {
        $tasks = @(
            [PSCustomObject]@{ id = "a"; description = "a"; priority = 6; complexity = "high";   status = "pending" }
            [PSCustomObject]@{ id = "b"; description = "b"; priority = 6; complexity = "low";    status = "pending" }
            [PSCustomObject]@{ id = "c"; description = "c"; priority = 6; complexity = "medium"; status = "pending" }
        )
        $sorted = Sort-TaskQueue -Tasks $tasks
        # Sort-Object ascending on string: alphabetical order = high, low, medium
        $sorted[0].complexity | Should -Be "high"
        $sorted[1].complexity | Should -Be "low"
        $sorted[2].complexity | Should -Be "medium"
    }
}

# ---------------------------------------------------------------------------
# 8. New-TasksFromResult: follow-up task creation
# ---------------------------------------------------------------------------
Describe "babyagi-loop.ps1 — New-TasksFromResult" {
    BeforeAll {
        $env:BABYAGI_TEST_MODE = "1"
        . $scriptPath -Goal "dummy" -AllowedPaths "src/*"
    }

    AfterAll {
        $env:BABYAGI_TEST_MODE = $null
    }

    It "creates retry task on timeout" {
        $task = [PSCustomObject]@{ id = "task_1"; description = "do work"; priority = 6; complexity = "medium"; status = "completed" }
        $result = [PSCustomObject]@{ status = "timeout"; passed = $false }
        $newTasks = New-TasksFromResult -Task $task -Result $result
        $retry = $newTasks | Where-Object { $_.id -like "retry_*" }
        $retry | Should -Not -BeNullOrEmpty
        $retry.description | Should -Match "Retry"
    }

    It "creates fix task on failure" {
        $task = [PSCustomObject]@{ id = "task_2"; description = "check tests"; priority = 6; complexity = "medium"; status = "completed" }
        $result = [PSCustomObject]@{ status = "done"; passed = $false; reason = "assertion error" }
        $newTasks = New-TasksFromResult -Task $task -Result $result
        $fix = $newTasks | Where-Object { $_.id -like "fix_*" }
        $fix | Should -Not -BeNullOrEmpty
        $fix.complexity | Should -Be "high"
    }

    It "creates audit task when changed files present" {
        $task = [PSCustomObject]@{ id = "task_3"; description = "scan code"; priority = 6; complexity = "medium"; status = "completed" }
        $result = [PSCustomObject]@{ status = "done"; passed = $true; changed_files = @("src/a.cs", "src/b.cs") }
        $newTasks = New-TasksFromResult -Task $task -Result $result
        $audit = $newTasks | Where-Object { $_.id -like "audit_*" }
        $audit | Should -Not -BeNullOrEmpty
        $audit.description | Should -Match "Audit changed files"
    }

    It "returns empty when task passed with no changes" {
        $task = [PSCustomObject]@{ id = "task_4"; description = "read config"; priority = 3; complexity = "low"; status = "completed" }
        $result = [PSCustomObject]@{ status = "done"; passed = $true }
        $newTasks = New-TasksFromResult -Task $task -Result $result
        # PowerShell coerces empty @() to $null in some contexts
        ($null -eq $newTasks -or $newTasks.Count -eq 0) | Should -BeTrue
    }
}
