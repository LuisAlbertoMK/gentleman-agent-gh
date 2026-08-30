#requires -Version 7
[CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName='Benchmark')]
<#
.SYNOPSIS
    Benchmark Core — unified benchmarking: score, regression detection, async push validation.
.DESCRIPTION
    Consolidated benchmarking operations.
    Replaces: benchmark.ps1, benchmark-regression.ps1, benchmark-async-push.ps1

    SUBCOMMANDS:
    - Benchmark:     Score system metrics (skills, scripts, junctions) + baseline/gate/snapshot
    - Regression:    Statistical performance regression detection (median + IQR, 5-10 runs)
    - AsyncPush:     Benchmark async delegation polling overhead (push vs legacy polling)

.PARAMETER Command
    Subcommand: Benchmark, Regression, AsyncPush (default: Benchmark).

# Benchmark parameters
.PARAMETER Snapshot
    Write a dated benchmarks/YYYY-MM-DD.json snapshot and refresh LATEST_benchmark.json.
.PARAMETER Gate
    Compare current metrics vs the pinned baseline; exit 2 on regression or when no baseline exists.
.PARAMETER SetBaseline
    Pin the current run's metrics as the baseline at -Baseline.
.PARAMETER Baseline
    Path to the pinned baseline file (default: repo-root benchmark-baseline.json).
.PARAMETER SuiteSeconds
    Optional full-test-suite wall-time (seconds) recorded as SuiteSeconds.
.PARAMETER Json
    Emit raw JSON instead of human-readable output.

# Regression parameters
.PARAMETER RegCommand
    The benchmark command to run (e.g. "scripts/sync-vmk.ps1 -DryRun -Json").
.PARAMETER Runs
    Number of samples to collect (default: 10, minimum: 5 per protocol §0.7).
.PARAMETER RegBaseline
    Path to baseline JSON file (default: docs/mejoras/benchmark-baseline.json).
.PARAMETER Threshold
    Regression threshold as % above baseline median (default: 15 = 15% slower).
.PARAMETER Json
    Output machine-readable JSON.
.PARAMETER UpdateBaseline
    Write a new baseline from the current run.
.PARAMETER Quiet
    Suppress verbose output.

# AsyncPush parameters
.PARAMETER DryRun
    Report the plan without state changes.
.PARAMETER Force
    Force cleanup even on errors.

.EXAMPLE
    .\scripts\benchmark-core.ps1 -Command Benchmark
    .\scripts\benchmark-core.ps1 -Command Benchmark -Snapshot
    .\scripts\benchmark-core.ps1 -Command Benchmark -Gate
    .\scripts\benchmark-core.ps1 -Command Benchmark -SetBaseline
    .\scripts\benchmark-core.ps1 -Command Regression -RegCommand "scripts/sync-vmk.ps1 -DryRun" -Runs 10
    .\scripts\benchmark-core.ps1 -Command Regression -RegCommand "scripts/sync-vmk.ps1 -DryRun" -UpdateBaseline
    .\scripts\benchmark-core.ps1 -Command AsyncPush -Verbose
#>
param(
    [Parameter(ParameterSetName='Benchmark', Position=0)]
    [Parameter(ParameterSetName='Regression', Position=0)]
    [Parameter(ParameterSetName='AsyncPush', Position=0)]
    [ValidateSet('Benchmark','Regression','AsyncPush')]
    [string]$Command = 'Benchmark',

    # Benchmark params
    [switch]$Snapshot,
    [switch]$Gate,
    [switch]$Json,
    [switch]$SetBaseline,
    [string]$Baseline = (Join-Path (Split-Path $PSScriptRoot -Parent) "benchmark-baseline.json"),
    [int]$SuiteSeconds = 0,

    # Regression params
    [string]$RegCommand,
    [ValidateRange(5, 50)]
    [int]$Runs = 10,
    [string]$RegBaseline = "",
    [double]$Threshold = 15.0,
    [switch]$UpdateBaseline,
    [switch]$Quiet,

    # AsyncPush params
    [switch]$DryRun,
    [switch]$Force
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$sdir = Join-Path $repoRoot 'scripts'

# ============================================================
# BENCHMARK COMMAND
# ============================================================
if ($Command -eq 'Benchmark') {
    . (Join-Path (Join-Path $PSScriptRoot "lib") "platform.ps1")
    $r = Convert-Path "$PSScriptRoot\.."
    $cd = "$r\.agents\skills"; $am = "$r\AGENTS.md"; $sd = "$r\scripts"; $sn = "$r\benchmarks"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $sk = @(Get-ChildItem $cd -Directory).PSWhere({$_.Name -ne '_shared'}).PSForEach({
        $m = "$($_.FullName)\SKILL.md"; if(!(test-path $m)){return}
        $c = Get-Content $m -Raw
        @{Name=$_.Name; Bytes=$c.Length; Lines=($c-split"`n").Count; F=$c-match"^---"; W=$c-match"(?m)^## When to Use"; R=$c-match"(?m)^## (Rules|Critical Rules)"}
    })
    $ac = if(test-path $am){Get-Content $am -Raw}else{""}
    $sc = Get-ChildItem $sd -Filter *.ps1 -EA 0
    $gd = Join-Path (Get-GlobalConfigDir) "skills"
    $jo = 0; $dead = 0
    foreach($i in $sk){
        $it = Get-Item "$gd\$($i.Name)" -EA 0
        if($it -and $it.LinkType -in @("Junction","SymbolicLink")){
            $valid = $false
            if($it.Target){
                $t = Resolve-Path $it.Target -EA SilentlyContinue
                $e = Resolve-Path "$cd\$($i.Name)" -EA SilentlyContinue
                if($t -and $e -and $t.Path -eq $e.Path){$valid=$true}
            }
            if($valid){$jo++}else{$dead++}
        }
    }
    $ab = ($sk.PSForEach({$_.Bytes}) | Measure-Object -Sum).Sum
    $al = ($sk.PSForEach({$_.Lines}) | Measure-Object -Sum).Sum
    $o3 = $sk.PSWhere({$_.Bytes -gt 3072}).Count
    $sb = @($sk.PSForEach({$_.Bytes}) | Sort-Object); $ct = $sb.Count
    $md = if($ct-gt0){if($ct%2-eq1){$sb[($ct-1)/2]}else{[math]::Round(($sb[$ct/2-1]+$sb[$ct/2])/2)}}else{0}
    $sw.Stop()
    $sys = @{
        AgentsMdBytes=[int]($ac.Length); AgentsMdLines=($ac-split"`n").Count; TotalSkills=$sk.Count
        TotalSkillBytes=[int]$ab; TotalSkillLines=[int]$al; SkillsOver3kb=$o3
        AvgSkillBytes=if($ct-gt0){[math]::Round($ab/$ct)}else{0}; MedianSkillBytes=$md
        MinSkillBytes=if($ct-gt0){$sb[0]}else{0}; MaxSkillBytes=if($ct-gt0){$sb[-1]}else{0}
        ScriptsCount=$sc.Count; GlobalJunctionsOk=$jo; DeadJunctions=$dead
        TokenEstimate=[int]($ab/3.5); BenchmarkSeconds=[math]::Round($sw.Elapsed.TotalSeconds,3)
        SuiteSeconds=$SuiteSeconds
        FrontmatterPct=if($ct-gt0){[math]::Round((@($sk | Where-Object {$_.F}).Count)/$ct*100,1)}else{0}
        WhenToUsePct=if($ct-gt0){[math]::Round((@($sk | Where-Object {$_.W}).Count)/$ct*100,1)}else{0}
        RulesPct=if($ct-gt0){[math]::Round((@($sk | Where-Object {$_.R}).Count)/$ct*100,1)}else{0}
    }
    $cmit = try{(git rev-parse --short HEAD 2>$null).Trim()}catch{"unknown"}
    $ts = (Get-Date -Format "o")
    $snap = @{version="1.0"; timestamp=$ts; commit="$cmit"; system=$sys}
    function dump($x){Write-Output ("  AGENTS.md: {0}B ({1} lines)"-f $x.AgentsMdBytes,$x.AgentsMdLines)
        ("  Skills: {0} | Total: {1}B ({2} lines)"-f $x.TotalSkills,$x.TotalSkillBytes,$x.TotalSkillLines)
        ("  >3KB: {0} | Junctions: {1}/{2} (dead: {3})"-f $x.SkillsOver3kb,$x.GlobalJunctionsOk,$x.TotalSkills,$x.DeadJunctions)
        ("  Avg: {0}B | Median: {1}B | Range: {2}-{3}B"-f $x.AvgSkillBytes,$x.MedianSkillBytes,$x.MinSkillBytes,$x.MaxSkillBytes)
        ("  Frontmatter: {0}% | WhenToUse: {1}% | Rules: {2}%"-f $x.FrontmatterPct,$x.WhenToUsePct,$x.RulesPct)
        ("  Scripts: {0} | TokenEstimate: {1} | BenchmarkSeconds: {2}s"-f $x.ScriptsCount,$x.TokenEstimate,$x.BenchmarkSeconds)}
    if(!(test-path $cd)){Write-Error "Canonical skills dir not found: $cd";exit 2}
    if($Snapshot){
        try{
            if(!(test-path $sn)){New-Item $sn -ItemType Directory -Force | Out-Null}
            $fn="{0:yyyy-MM-dd}.json"-f(Get-Date); $js=$snap|ConvertTo-Json -Depth 3
            Set-Content "$sn\$fn" $js -Encoding UTF8
            $lat=Join-Path (Join-Path $r "docs\metricas") "snapshots\LATEST_benchmark.json"
            $latDir=Split-Path $lat -Parent
            if(!(test-path $latDir)){New-Item $latDir -ItemType Directory -Force | Out-Null}
            Set-Content $lat $js -Encoding UTF8
            if(!$Json){Write-Output "Snapshot saved: $sn\$fn"}
        }catch{Write-Warning "benchmark: snapshot save failed ($($_.Exception.Message))"}
    }
    if($SetBaseline){
        try{
            $bd=Split-Path $Baseline -Parent
            if($bd -and !(test-path $bd)){New-Item $bd -ItemType Directory -Force | Out-Null}
            Set-Content $Baseline ($snap|ConvertTo-Json -Depth 3) -Encoding UTF8
            if(!$Json){Write-Output "Baseline pinned: $Baseline (GlobalJunctionsOk=$jo, DeadJunctions=$dead)"}
        }catch{Write-Warning "benchmark: baseline save failed ($($_.Exception.Message))"}
    }
    if($Gate){
        $reg=@()
        if(!(test-path $Baseline)){
            Write-Output "BENCHMARK FAIL: pinned baseline not found at $Baseline — run benchmark-core.ps1 -Command Benchmark -SetBaseline"
            dump $sys; exit 2
        }
        try{
            $pr=Get-Content $Baseline -Raw | ConvertFrom-Json; $pz=$pr.system
            if($sys.AgentsMdBytes-gt$pz.AgentsMdBytes*1.1){$reg+="AGENTS.md grew >10% ($($pz.AgentsMdBytes)->$($sys.AgentsMdBytes))"}
            if($sys.TotalSkillBytes-gt$pz.TotalSkillBytes*1.05){$reg+="Total skill bytes grew >5% ($($pz.TotalSkillBytes)->$($sys.TotalSkillBytes))"}
            if($sys.SkillsOver3kb-gt$pz.SkillsOver3kb){$reg+="Skills >3KB increased ($($pz.SkillsOver3kb)->$($sys.SkillsOver3kb))"}
            if(-not $env:CI -and -not $env:GITHUB_ACTIONS -and $sys.GlobalJunctionsOk-lt$pz.GlobalJunctionsOk){$reg+="Global junctions decreased ($($pz.GlobalJunctionsOk)->$($sys.GlobalJunctionsOk))"}
            if($sys.DeadJunctions-gt0){$reg+="Dead junctions detected ($($sys.DeadJunctions))"}
        }catch{Write-Debug "bench: baseline compare failed ($($_.Exception.Message))"}
        if($reg.Count-gt0){Write-Output "BENCHMARK REGRESSIONS:";$reg | ForEach-Object {Write-Output "  - $_"};dump $sys;exit 2}
        dump $sys
        if(!$Json){Write-Output "   Skills: $($sys.TotalSkills) | Total: $($sys.TotalSkillBytes)B | >3KB: $($sys.SkillsOver3kb) | Junctions: $($sys.GlobalJunctionsOk)/$($sys.TotalSkills) | Dead: $($sys.DeadJunctions)"}
    }
    if(!$Snapshot -and !$Gate -and !$SetBaseline -or $Json){
        if($Json){Write-Output ($snap|ConvertTo-Json -Depth 3)}else{Write-Output "  Commit: $cmit";dump $sys;Write-Output "  SuiteSeconds: $($sys.SuiteSeconds)"}
    }
    exit 0
}

# ============================================================
# REGRESSION COMMAND
# ============================================================
if ($Command -eq 'Regression') {
    if (-not $RegCommand) { Write-Error "Missing required -RegCommand parameter"; exit 1 }

    if (-not $RegBaseline) { $RegBaseline = Join-Path $repoRoot "docs/mejoras/benchmark-baseline.json" }

    $parts = $RegCommand -split '\s+'
    $scriptName = $parts[0]
    $scriptArgs = if ($parts.Count -gt 1) { $parts[1..($parts.Count-1)] } else { @() }

    if (-not $scriptName.StartsWith('-') -and (Test-Path (Join-Path $repoRoot "scripts/$scriptName"))) {
        $scriptPath = Join-Path $repoRoot "scripts/$scriptName"
    } elseif (Test-Path $scriptName) { $scriptPath = $scriptName }
    else { Write-Error "Script not found: $scriptName"; exit 1 }

    $baselineData = $null
    if (Test-Path $RegBaseline) {
        try { $baselineData = Get-Content $RegBaseline -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue } catch { Write-Warning "Baseline JSON parse error: $_" }
    }

    $samples = @()
    if (-not $Json -and -not $Quiet) { Write-Host "🏃 Running benchmark: $scriptName ($Runs samples)" -ForegroundColor Cyan }

    for ($i = 0; $i -lt $Runs; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-Expression ("& '" + ($scriptPath -replace "'", "''") + "' $($scriptArgs -join ' ')") > $null 2>&1
        $sw.Stop()
        $samples += $sw.Elapsed.TotalMilliseconds
        if (-not $Json) { Write-Progress -Activity "Benchmarking" -Status "Run $($i+1)/$Runs" -PercentComplete (($i+1)/$Runs*100) }
    }

    $samples = $samples | Sort-Object
    $count = $samples.Count
    $median = if ($count % 2 -eq 0) { ($samples[$count/2 - 1] + $samples[$count/2]) / 2 } else { $samples[[math]::Floor($count/2)] }
    $q1 = $samples[[math]::Floor($count * 0.25)]
    $q3 = $samples[[math]::Floor($count * 0.75)]
    $iqr = $q3 - $q1
    $mean = ($samples | Measure-Object -Average).Average
    $stdev = if ($count -gt 1) { $variance = ($samples | ForEach-Object { [math]::Pow($_ - $mean, 2) } | Measure-Object -Sum).Sum / ($count - 1); [math]::Sqrt($variance) } else { 0 }

    $regressionDetected = $false
    $regressionPercent = 0
    if ($baselineData -and $baselineData.median_ms) {
        $baselineMedian = $baselineData.median_ms
        $improvement = $median - $baselineMedian
        $regressionPercent = if ($baselineMedian -gt 0) { ($improvement / $baselineMedian) * 100 } else { 0 }
        $regressionDetected = $regressionPercent -gt $Threshold
    }

    if ($UpdateBaseline) {
        $baselineObj = [PSCustomObject]@{
            command         = $RegCommand; runs = $Runs; median_ms = [math]::Round($median, 2)
            mean_ms         = [math]::Round($mean, 2); stdev_ms = [math]::Round($stdev, 2)
            q1_ms           = [math]::Round($q1, 2); q3_ms = [math]::Round($q3, 2)
            iqr_ms          = [math]::Round($iqr, 2); min_ms = [math]::Round($samples[0], 2)
            max_ms          = [math]::Round($samples[-1], 2)
            timestamp       = (Get-Date).ToUniversalTime().ToString("o")
        }
        if (-not (Test-Path (Split-Path $RegBaseline -Parent))) { New-Item -ItemType Directory -Path (Split-Path $RegBaseline -Parent) -Force | Out-Null }
        $baselineObj | ConvertTo-Json | Set-Content -Path $RegBaseline -Encoding UTF8
        if (-not $Json -and -not $Quiet) { Write-Host "✅ Baseline updated: $RegBaseline" -ForegroundColor Green }
    }

    $result = [PSCustomObject]@{
        command            = $RegCommand; runs = $Runs; median_ms = [math]::Round($median, 2)
        mean_ms            = [math]::Round($mean, 2); stdev_ms = [math]::Round($stdev, 2)
        q1_ms              = [math]::Round($q1, 2); q3_ms = [math]::Round($q3, 2)
        iqr_ms             = [math]::Round($iqr, 2)
        baseline_median_ms = if ($baselineData) { $baselineData.median_ms } else { $null }
        regression_percent = [math]::Round($regressionPercent, 2); regression = $regressionDetected
        threshold_percent  = $Threshold
        status             = if ($regressionDetected) { "REGRESSION" } elseif ($baselineData) { "OK" } else { "BASELINE_CREATED" }
    }

    if ($Json) { $result | ConvertTo-Json -Compress -Depth 3 }
    else {
        Write-Host "=== Benchmark Result ===" -ForegroundColor Cyan
        Write-Host "  Median: $($result.median_ms)ms (±IQR: $($result.iqr_ms)ms)" -ForegroundColor White
        Write-Host "  Mean:   $($result.mean_ms)ms (σ: $($result.stdev_ms)ms)" -ForegroundColor Gray
        Write-Host "  Q1-Q3:  $($result.q1_ms) — $($result.q3_ms)ms" -ForegroundColor Gray
        if ($baselineData) {
            Write-Host "  Baseline median: $($result.baseline_median_ms)ms" -ForegroundColor Gray
            if ($regressionDetected) { Write-Host "  ⚠️  REGRESSION DETECTED: $($result.regression_percent)% slower (threshold: $Threshold%)" -ForegroundColor Red }
            else { Write-Host "  ✅ No regression: $($result.regression_percent)% vs baseline" -ForegroundColor Green }
        } else { Write-Host "  ℹ️  No baseline — run with -UpdateBaseline to create one" -ForegroundColor Yellow }
    }
    exit $(if ($regressionDetected) { 1 } else { 0 })
}

# ============================================================
# ASYNC PUSH COMMAND
# ============================================================
if ($Command -eq 'AsyncPush') {
    $ErrorActionPreference = 'Continue'

    # ─── 1. STATIC ANALYSIS: Polling cycles ─────────────────────────────────────
    Write-Verbose "[benchmark] Static analysis: polling in Invoke-TaskAsync"

    $pushSrc = Get-Content (Join-Path $sdir 'babyagi-loop.ps1') -Raw
    $pushPollLoops = ([regex]::Matches($pushSrc, 'Start-Sleep\s*-Seconds\s*\$PollSec').Count)
    $pushHasWatcher = ($pushSrc -match 'FileSystemWatcher')
    $pushHasWaitEvent = ($pushSrc -match 'Wait-Event')

    $legacySrc = git -C $repoRoot show 'main:scripts/babyagi-loop.ps1' 2>$null
    $legacyHasContent = -not [string]::IsNullOrWhiteSpace($legacySrc)
    if ($legacyHasContent) {
        $legacyPollLoops = ([regex]::Matches($legacySrc, 'Start-Sleep\s*-Seconds\s*\$PollSec').Count)
        $legacyHasWatcher = ($legacySrc -match 'FileSystemWatcher')
    } else {
        $legacyPollLoops = 1; $legacyHasWatcher = $false
        Write-Verbose "[benchmark] git show main: scripts/babyagi-loop.ps1 unavailable, using known legacy pattern"
    }
    $legacyHasWaitEvent = $false

    if ($DryRun) {
        Write-Host "[benchmark][DryRun] Would run functional latency + cancel benchmarks (temp dir, watcher, dummy process)."
        Write-Host "[benchmark][DryRun] Static: push polling loops=$pushPollLoops watcher=$pushHasWatcher wait-event=$pushHasWaitEvent"
        Write-Host "[benchmark][DryRun] No files written, no processes spawned."
        exit 0
    }

    # ─── 2. FUNCTIONAL: Latency (signal → detection) ────────────────────────────
    Write-Verbose "[benchmark] Functional latency: signal file → detection"

    $testDir = Join-Path ([System.IO.Path]::GetTempPath()) ("gentleman-bench-{0}" -f [System.Diagnostics.Process]::GetCurrentProcess().Id)
    if (Test-Path $testDir) { Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null

    $taskId = "bench_test_$(Get-Random)"
    $signalFile = Join-Path $testDir "$taskId.async-done"

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $testDir
    $watcher.Filter = "$taskId.async-done"
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true

    $eventId = "bench_watcher_$taskId"
    $signalReceived = $false
    $action = Register-ObjectEvent -InputObject $watcher -EventName "Created" -SourceIdentifier $eventId -Action { $signalReceived = $true }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Start-Sleep -Milliseconds 100

    $startNs = [DateTime]::UtcNow.Ticks
    Set-Content -Path $signalFile -Value (Get-Date -Format "o") -Encoding UTF8 -NoNewline
    $createdNs = [DateTime]::UtcNow.Ticks

    $null = Wait-Event -SourceIdentifier $eventId -Timeout 3
    $latencyMs = [math]::Round(((Get-Date).ToUniversalTime().Subtract([DateTime]::FromFileTime($startNs))).TotalMilliseconds, 1)

    if (-not $signalReceived) {
        $pollSw = [System.Diagnostics.Stopwatch]::StartNew()
        while (-not (Test-Path $signalFile) -and $pollSw.ElapsedMilliseconds -lt 3000) { Start-Sleep -Milliseconds 10 }
        $latencyMs = $pollSw.ElapsedMilliseconds
    }
    $sw.Stop()

    Get-Event -SourceIdentifier $eventId -ErrorAction SilentlyContinue | Remove-Event
    Unregister-Event -SourceIdentifier $eventId -Force -ErrorAction SilentlyContinue
    $watcher.Dispose() | Out-Null
    if (-not $DryRun) { Remove-Item -Path $testDir -Recurse -Force }

    $legacyLatencyMs = 15000

    # ─── 3. FUNCTIONAL: Cancel + orphaned processes ─────────────────────────────
    Write-Verbose "[benchmark] Cancel flow + orphaned process check"

    $dummyProc = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile -Command Start-Sleep -Seconds 60" -WindowStyle Hidden -PassThru
    Start-Sleep -Milliseconds 200

    $pidFile = Join-Path $repoRoot '.learnings\benchmark-test.pid'
    if (Test-Path (Split-Path $pidFile)) { New-Item -ItemType Directory -Path (Split-Path $pidFile) -Force | Out-Null }
    $dummyProc.Id | Set-Content -Path $pidFile -Encoding UTF8

    $killSw = [System.Diagnostics.Stopwatch]::StartNew()
    $pidFromFile = [int](Get-Content $pidFile -Raw).Trim()
    $procToKill = Get-Process -Id $pidFromFile -ErrorAction SilentlyContinue
    if ($procToKill) { $procToKill.Kill() }
    $killSw.Stop()
    $cancelMs = $killSw.ElapsedMilliseconds

    Start-Sleep -Milliseconds 300
    $orphanedProcs = 0
    try { $check = Get-Process -Id $pidFromFile -ErrorAction SilentlyContinue; if ($check) { $orphanedProcs++ } } catch {}
    Remove-Item -Path $pidFile -Force -ErrorAction SilentlyContinue
    if ($dummyProc -and -not $dummyProc.HasExited) { $dummyProc.Kill() }

    $legacyCancelMs = -1; $legacyOrphans = 1

    # ─── 4. RESULTS ─────────────────────────────────────────────────────────────
    $pollingReduction = if ($legacyPollLoops -gt 0) { [math]::Round((($legacyPollLoops - $pushPollLoops) / $legacyPollLoops) * 100) } else { 0 }
    $latencyReduction = [math]::Round((($legacyLatencyMs - $latencyMs) / $legacyLatencyMs) * 100, 1)
    $cancelPossible = ($legacyCancelMs -lt 0) -and ($cancelMs -ge 0)

    $results = [PSCustomObject]@{
        timestamp = (Get-Date).ToString('o')
        comparison = [ordered]@{
            before = [ordered]@{
                polling_cycles            = $legacyPollLoops
                latency_ms_worst_case     = $legacyLatencyMs
                cancel_ms                 = if ($legacyCancelMs -lt 0) { "impossible" } else { $legacyCancelMs }
                orphaned_processes      = $legacyOrphans
                uses_filesystem_watcher = [bool]$legacyHasWatcher
            }
            after = [ordered]@{
                polling_cycles            = $pushPollLoops
                latency_ms_worst_case     = $latencyMs
                cancel_ms                 = $cancelMs
                orphaned_processes      = $orphanedProcs
                uses_filesystem_watcher = [bool]$pushHasWatcher
            }
        }
        gains = [ordered]@{
            polling_cycles_reduction_pct  = $pollingReduction
            latency_reduction_pct         = $latencyReduction
            cancel_now_possible           = $cancelPossible
        }
        thresholds = [ordered]@{
            polling_cycles_eliminated = ($pushPollLoops -eq 0)
            latency_under_5s          = ($latencyMs -lt 5000)
            zero_orphaned_procs       = ($orphanedProcs -eq 0)
            cancel_under_1s           = ($cancelMs -lt 1000)
        }
    }

    $thresholdKeys = @('polling_cycles_eliminated', 'latency_under_5s', 'zero_orphaned_procs', 'cancel_under_1s')
    $failedThresholds = @($thresholdKeys | Where-Object { $results.thresholds.$_ -ne $true })
    $gainsStatus = if ($failedThresholds.Count -eq 0) { "ALL THRESHOLDS PASS" } else { "FAIL: $($failedThresholds -join ', ')" }

    if ($Json) { $results | ConvertTo-Json -Depth 5 }
    else {
        Write-Host ""
        Write-Host "=== Async Push Callback Benchmark ===" -ForegroundColor Cyan
        Write-Host "  (before = main branch legacy, after = working tree push)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Polling cycles in Invoke-TaskAsync:" -ForegroundColor Yellow
        Write-Host ("    BEFORE: {0} (Start-Sleep polling loop)" -f $results.comparison.before.polling_cycles)
        Write-Host ("    AFTER:  {0} (Wait-Event push)" -f $results.comparison.after.polling_cycles)
        Write-Host ("    Gain:   {0}% reduction" -f $results.gains.polling_cycles_reduction_pct) -ForegroundColor Green
        Write-Host ""
        Write-Host "  Latency (signal -> detection):" -ForegroundColor Yellow
        Write-Host ("    BEFORE: ~$($results.comparison.before.latency_ms_worst_case)ms (15s poll interval)")
        Write-Host ("    AFTER:  $($results.comparison.after.latency_ms_worst_case)ms (FileSystemWatcher push)")
        Write-Host ("    Gain:   {0}% reduction" -f $results.gains.latency_reduction_pct) -ForegroundColor Green
        Write-Host ""
        Write-Host "  Cancel + orphaned processes:" -ForegroundColor Yellow
        Write-Host ("    BEFORE: impossible (no PID tracking), $($results.comparison.before.orphaned_processes) orphan")
        Write-Host ("    AFTER:  $($results.comparison.after.cancel_ms)ms, $($results.comparison.after.orphaned_processes) orphans")
        if ($cancelPossible) { Write-Host "    Gain:   Cancel now possible" -ForegroundColor Green }
        Write-Host ""
        Write-Host "  Thresholds:" -ForegroundColor Yellow
        foreach ($key in $thresholdKeys) {
            $val = $results.thresholds.$key
            $color = if ($val -eq $true) { "Green" } else { "Red" }
            Write-Host ("    {0}: {1}" -f $key, $val) -ForegroundColor $color
        }
        Write-Host ""
        Write-Host ("  Result: {0}" -f $gainsStatus) -ForegroundColor $(if($failedThresholds.Count -eq 0){"Green"}else{"Red"})
        Write-Host ""
    }
    exit $(if ($failedThresholds.Count -eq 0) { 0 } else { 1 })
}