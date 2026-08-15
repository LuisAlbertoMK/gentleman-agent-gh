#requires -Version 7
# BabyAGI Loop - Phase 2 E2E Tests (Pester 6.1 / pwsh compatible)
# Functions defined in BeforeAll for scope isolation in Pester 6.

BeforeAll {
function New-Tasks {
    param([string]$GoalText)
    $connectors = @(" and ", " then ", " ; ", ", ")
    $parts = @($GoalText)
    foreach ($conn in $connectors) {
        $newParts = @()
        foreach ($p in $parts) {
            $split = $p -split [regex]::Escape($conn)
            $split | ForEach-Object { $newParts += $_.Trim() }
        }
        $parts = $newParts
    }

    $tasks = @()
    $idx = 1
    foreach ($p in $parts | Where-Object { $_.Length -gt 5 }) {
        $complexity = "medium"
        if ($p -match "all|every|comprehensive|scan|audit") { $complexity = "high" }
        elseif ($p -match "fix|add|update|create") { $complexity = "medium" }
        else { $complexity = "low" }

        $priority = switch ($complexity) {
            "high"   { 9 }
            "medium" { 6 }
            "low"    { 3 }
        }

        $task = New-Object -TypeName PSObject -Property ([ordered]@{
            id          = "task_$idx"
            description = $p
            priority    = $priority
            complexity  = $complexity
            status      = "pending"
        })
        $tasks += $task
        $idx++
    }

    if ($tasks.Count -eq 0) {
        $tasks += New-Object -TypeName PSObject -Property ([ordered]@{
            id = "task_1"; description = $GoalText; priority = 5; complexity = "medium"; status = "pending"
        })
    }

    return $tasks
}

function Sort-Queue {
    param([array]$Tasks)
    return $Tasks | Sort-Object -Property @{Expression = { $_.priority }; Descending = $true}
}

function Create-TasksFromResult {
    param([PSObject]$Task, [PSObject]$Result)
    $newTasks = @()

    if ($Result.status -eq "timeout") {
        $newTasks += New-Object -TypeName PSObject -Property ([ordered]@{
            id = "retry_$($Task.id)"; description = "retry"; priority = 4; complexity = "medium"; status = "pending"
        })
    }

    if ($Result.passed -eq $false) {
        $newTasks += New-Object -TypeName PSObject -Property ([ordered]@{
            id = "fix_$($Task.id)"; description = "fix"; priority = 7; complexity = "high"; status = "pending"
        })
    }

    if ($Result.changed_files -and @($Result.changed_files).Count -gt 0) {
        $newTasks += New-Object -TypeName PSObject -Property ([ordered]@{
            id = "audit_$($Task.id)"; description = "audit"; priority = 4; complexity = "medium"; status = "pending"
        })
    }

    return $newTasks
    }
}

Describe "BabyAGI Phase 2 - Task Creation" {

    Context "T1: Initial task parsing from goal" {
        It "Single goal becomes at least 1 task" {
            $tasks = New-Tasks -GoalText "Review all auth tests"
            @($tasks).Count | Should -BeGreaterThan 0
            $tasks[0].id | Should -Match "^task_"
            $tasks[0].status | Should -Be "pending"
        }

        It "Multi-part goal creates multiple tasks" {
            $tasks = New-Tasks -GoalText "Review auth tests and fix gaps"
            @($tasks).Count | Should -BeGreaterThan 1
        }
    }

    Context "T2: Complexity priority heuristic" {
        It "High complexity gets priority greater than 6" {
            $tasks = New-Tasks -GoalText "Audit all auth tests comprehensively"
            $tasks[0].priority | Should -BeGreaterThan 6
            $tasks[0].complexity | Should -Be "high"
        }

        It "Low complexity gets priority less than 4" {
            $tasks = New-Tasks -GoalText "List files in src"
            $tasks[0].priority | Should -BeLessThan 4
            $tasks[0].complexity | Should -Be "low"
        }
    }
}

Describe "BabyAGI Phase 2 - Prioritization" {

    Context "T3: Sort-Queue orders by priority descending" {
        It "Highest priority task comes first" {
            $tasks = @(
                New-Object -TypeName PSObject -Property ([ordered]@{ id = "t1"; priority = 3 })
                New-Object -TypeName PSObject -Property ([ordered]@{ id = "t2"; priority = 9 })
                New-Object -TypeName PSObject -Property ([ordered]@{ id = "t3"; priority = 5 })
            )
            $sorted = Sort-Queue -Tasks $tasks
            $sorted[0].id | Should -Be "t2"
            $sorted[1].id | Should -Be "t3"
            $sorted[2].id | Should -Be "t1"
        }
    }
}

Describe "BabyAGI Phase 2 - Task Creation from Results" {

    Context "T4: Creates retry task on timeout" {
        It "Creates retry task when status is timeout" {
            $task = New-Object -TypeName PSObject -Property ([ordered]@{ id = "task_1"; priority = 5 })
            $result = New-Object -TypeName PSObject -Property ([ordered]@{ status = "timeout"; passed = $true; changed_files = @() })

            $newTasks = Create-TasksFromResult -Task $task -Result $result
            @(@($newTasks) | Where-Object { $_.id -eq "retry_task_1" }).Count | Should -Be 1
        }
    }

    Context "T5: Creates fix task on failure" {
        It "Creates fix task when passed is false" {
            $task = New-Object -TypeName PSObject -Property ([ordered]@{ id = "task_2"; priority = 6 })
            $result = New-Object -TypeName PSObject -Property ([ordered]@{ status = "OK"; passed = $false; changed_files = @() })

            $newTasks = Create-TasksFromResult -Task $task -Result $result
            @(@($newTasks) | Where-Object { $_.id -eq "fix_task_2" }).Count | Should -Be 1
        }

        It "No new tasks on success" {
            $task = New-Object -TypeName PSObject -Property ([ordered]@{ id = "task_3"; priority = 4 })
            $result = New-Object -TypeName PSObject -Property ([ordered]@{ status = "OK"; passed = $true; changed_files = @() })

            $newTasks = Create-TasksFromResult -Task $task -Result $result
            @($newTasks).Count | Should -Be 0
        }
    }
}

Describe "BabyAGI Phase 2 - Fail-Closed" {

    Context "T6: Script contains fail-closed guard" {
        It "Guard clause is present in babyagi-loop.ps1" {
            $scriptPath = Join-Path $PSScriptRoot "..\scripts\babyagi-loop.ps1"
            $content = Get-Content $scriptPath -Raw
            $content | Should -Match "FAIL-CLOSED"
        }
    }
}
