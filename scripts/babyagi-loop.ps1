#requires -Version 5.1
<#
.SYNOPSIS
    BabyAGI autonomous loop — executes tasks iteratively using async delegation from Phase 1.

.DESCRIPTION
    Phase 2 of the mini-orchestrator. Implements the classic BabyAGI pattern:
    Execution -> Task Creation -> Prioritization, with async fire-and-forget delegation
    from Phase 1 (post-delegation-check.ps1 -Async).

    Inherits all guardrails from the auto-sub deny floor.
    No LLM calls inside the script — uses heuristic task creation + prioritization.

.PARAMETER Goal
    The high-level objective to accomplish (e.g. "Review all auth tests").

.PARAMETER MaxIterations
    Maximum number of task cycles. Default: 5.

.PARAMETER BudgetTokens
    Token budget hint (for logging/observability). Default: 2048.

.PARAMETER AllowedPaths
    Comma-separated path patterns allowed for async delegation. Required (fail-closed).

.PARAMETER PollIntervalSec
    Seconds between convergence polls. Default: 15.

.EXAMPLE
    babyagi-loop.ps1 -Goal "Review all auth tests in src/auth/*" -MaxIterations 5
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$Goal,

    [int]$MaxIterations = 5,

    [int]$BudgetTokens = 2048,

    [Parameter(Mandatory=$true)]
    [string[]]$AllowedPaths,

    [int]$PollIntervalSec = 15,

    [switch]$DryRun,

    [switch]$Force
)

# Guardrails — fail-closed
if (-not $AllowedPaths -or $AllowedPaths.Count -eq 0) {
    Write-Error "FAIL-CLOSED: -AllowedPaths is required. Cannot start BabyAGI loop without path scope."
    exit 1
}

# Resolve script directory for Phase 1 dependency
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PostDelegation = Join-Path $ScriptDir "post-delegation-check.ps1"
$MonitorScript = Join-Path $ScriptDir "monitor-subagent.ps1"

if (-not (Test-Path $PostDelegation)) {
    Write-Error "Phase 1 dependency not found: $PostDelegation"
    exit 1
}

# ---------------------------------------------------------------------------
# Task object: @{ id; description; priority; complexity; status }
# priority (1-10): higher = more urgent
# complexity: "low" | "medium" | "high"
# ---------------------------------------------------------------------------

# --- Phase 1: Initial Task Creation ---
function New-InitialTasks {
    param([string]$GoalText)

    # Heuristic: split goal into actionable sub-tasks by connector keywords
    $connectors = @(" and ", " then ", " ; ", ", ", " + ")
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

        $tasks += [PSCustomObject]@{
            id           = "task_$idx"
            description  = $p
            priority     = $priority
            complexity   = $complexity
            status       = "pending"
        }
        $idx++
    }

    # Fallback: if no tasks created, treat goal as single task
    if ($tasks.Count -eq 0) {
        $tasks += [PSCustomObject]@{
            id          = "task_1"
            description = $GoalText
            priority    = 5
            complexity  = "medium"
            status      = "pending"
        }
    }

    return $tasks
}

# --- Phase 2: Prioritization ---
function Sort-TaskQueue {
    param([array]$Tasks)
    return $Tasks | Sort-Object -Property @{Expression = {$_.priority}; Descending = $true},
                                 @{Expression = {$_.complexity}; Descending = $false}
}

# --- Phase 3: Execution (via Phase 1 async delegation) ---
function Invoke-TaskAsync {
    param(
        [PSObject]$Task,
        [string[]]$Paths,
        [string]$BaseRef,
        [int]$PollSec
    )

    $taskRef = "$($Task.id)_$BaseRef"
    $resultFile = "${taskRef}.async-result.json"

    # Clean up any stale result file (guarded: dry-run / requires -Force for removal)
    if (Test-Path $resultFile) {
        if ($DryRun) {
            Write-Host "[BabyAGI][DryRun] Would remove stale result: $resultFile"
        } elseif (-not $Force) {
            Write-Warning "[BabyAGI] Stale result file present: $resultFile. Pass -Force to clean (or -DryRun to preview)."
            return $null
        } else {
            try {
                Remove-Item -Path $resultFile -Force -ErrorAction Stop
            } catch {
                Write-Error "[BabyAGI] Failed to remove stale result: $($_.Exception.Message)"
                return $null
            }
        }
    }

    # Launch async delegation from Phase 1
    Write-Host "[BabyAGI] Executing: $($Task.description)" -ForegroundColor Cyan
    & $PostDelegation -BaseRef $taskRef -AllowedPaths $Paths -Async `
        -ExtraContext "Task: $($Task.description)" 2>&1 | Out-Null

    # Poll for result file (convergence delegated to Phase 1 monitor)
    $maxWait = 300
    $elapsed = 0
    while (-not (Test-Path $resultFile) -and $elapsed -lt $maxWait) {
        Start-Sleep -Seconds $PollSec
        $elapsed += $PollSec
    }

    if (-not (Test-Path $resultFile)) {
        Write-Warning "[BabyAGI] Timeout waiting for task $($Task.id) result after ${maxWait}s"
        return $null
    }

    $result = Get-Content $resultFile -Raw | ConvertFrom-Json
    return $result
}

# --- Phase 4: Task Creation from Results ---
function New-TasksFromResult {
    param([PSObject]$Task, [PSObject]$Result)

    $newTasks = @()

    if ($Result.status -eq "timeout") {
        # Retry with reduced scope
        $newTasks += [PSCustomObject]@{
            id          = "retry_$($Task.id)"
            description = "Retry $($Task.description) with stricter path scope"
            priority    = [math]::Max($Task.priority - 2, 1)
            complexity  = $Task.complexity
            status      = "pending"
        }
    }

    if ($Result.passed -eq $false) {
        $newTasks += [PSCustomObject]@{
            id          = "fix_$($Task.id)"
            description = "Fix failures from: $($Task.description)"
            priority    = [math]::Max($Task.priority + 1, 10)
            complexity  = "high"
            status      = "pending"
        }
    }

    # If task found changed files, audit them (heuristic: results mention findings)
    if ($Result.PSObject.Properties.Name -contains 'changed_files' -and $Result.changed_files.Count -gt 0) {
        $newTasks += [PSCustomObject]@{
            id          = "audit_$($Task.id)"
            description = "Audit changed files from $($Task.description): $($Result.changed_files -join ', ')"
            priority    = 4
            complexity  = "medium"
            status      = "pending"
        }
    }

    return $newTasks
}

# --- Main Loop ---
function Start-BabyAGILoop {
    Write-Host "[BabyAGI] Goal: $Goal" -ForegroundColor Green
    Write-Host "[BabyAGI] Max iterations: $MaxIterations" -ForegroundColor Green

    # Phase 1: create initial tasks
    $taskQueue = New-InitialTasks -GoalText $Goal
    Write-Host "[BabyAGI] Initial tasks: $($taskQueue.Count)" -ForegroundColor Green

    $iteration = 0
    $completed = 0
    $failed = 0

    while ($iteration -lt $MaxIterations -and $taskQueue.Count -gt 0) {
        $iteration++
        Write-Host "`n[===== Iteration $iteration / $MaxIterations =====]" -ForegroundColor Yellow

        # Phase 2: prioritize
        $taskQueue = Sort-TaskQueue -Tasks $taskQueue

        # Take highest-priority task
        $currentTask = $taskQueue[0]
        $taskQueue = $taskQueue[1..($taskQueue.Count - 1)]

        $currentTask.status = "in_progress"
        Write-Host "[BabyAGI] Selected: $($currentTask.description) (priority=$($currentTask.priority), complexity=$($currentTask.complexity))" -ForegroundColor Yellow

        # Phase 3: execute via async delegation
        $result = Invoke-TaskAsync -Task $currentTask -Paths $AllowedPaths -BaseRef "HEAD" -PollSec $PollIntervalSec

        if ($null -eq $result) {
            Write-Warning "[BabyAGI] Task $($currentTask.id) returned no result"
            $failed++
            $currentTask.status = "failed"
        }
        else {
            if ($result.passed) {
                Write-Host "[BabyAGI] Task $($currentTask.id) PASSED" -ForegroundColor Green
                $completed++
                $currentTask.status = "completed"
            }
            else {
                Write-Warning "[BabyAGI] Task $($currentTask.id) FAILED: $($result.reason)"
                $failed++
                $currentTask.status = "failed"
            }
        }

        # Phase 4: create new tasks from result
        $newTasks = New-TasksFromResult -Task $currentTask -Result $result
        if ($newTasks.Count -gt 0) {
            Write-Host "[BabyAGI] Created $($newTasks.Count) new task(s) from result" -ForegroundColor Cyan
            $taskQueue += $newTasks
        }

        # Convergence check: if no pending tasks and no new tasks, stop
        $pendingCount = @($taskQueue | Where-Object { $_.status -eq "pending" }).Count
        if ($pendingCount -eq 0 -and $newTasks.Count -eq 0) {
            Write-Host "[BabyAGI] Convergence: no pending tasks, stopping." -ForegroundColor Green
            break
        }
    }

    # Final summary
    Write-Host "`n[===== BabyAGI Summary =====]" -ForegroundColor Green
    Write-Host "Iterations: $iteration" -ForegroundColor Green
    Write-Host "Completed: $completed" -ForegroundColor Green
    Write-Host "Failed: $failed" -ForegroundColor Green
    Write-Host "Remaining in queue: $($taskQueue.Count)" -ForegroundColor Green

    return [PSCustomObject]@{
        iterations     = $iteration
        completed      = $completed
        failed         = $failed
        queueremaining = $taskQueue.Count
        goal           = $Goal
    }
}

# Execute (skip if running under test mode)
if (-not $env:BABYAGI_TEST_MODE) {
    Start-BabyAGILoop
}
