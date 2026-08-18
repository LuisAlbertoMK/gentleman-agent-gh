# development-mode — Reference Materials

> **Externalized from** .agents/skills/development-mode/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples

### Example 1: Large Log Analysis (500MB+ logs)
```powershell
# Activate dev mode first
& "$env:GENTLEMAN_AGENT_ROOT/scripts/optimize-system.ps1"
Get-Process "opencode*","node*" | ForEach-Object { $_.PriorityClass = "High" }
powercfg /SETACTIVE "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

# Parallel read with memory-mapped files
$logs = Get-ChildItem "logs/*.log" -Recurse | Where-Object { $_.Length -gt 500MB }
$errors = $logs | ForEach-Object -Parallel {
    $mmf = [System.IO.MemoryMappedFiles.MemoryMappedFile]::CreateFromFile($_.FullName)
    $stream = $mmf.CreateViewStream()
    $reader = [System.IO.StreamReader]::new($stream)
    $reader.ReadToEnd() -split "`n" | Where-Object { $_ -match "ERROR|FATAL" }
} -ThrottleLimit 8

# Deactivate after
Get-Process "opencode*" | ForEach-Object { $_.PriorityClass = "Normal" }
powercfg /SETACTIVE "381b4222-f694-41f0-9685-ff5bb260df2e"
```

### Example 2: Concurrent Build + Test Pipeline
```powershell
# Activate before starting concurrent workloads
Get-Process "opencode*","node*","bun*","dotnet*","java*" | ForEach-Object { $_.PriorityClass = "High" }

# Run builds in parallel with CPU affinity
$jobs = @(
    { & dotnet build src/ServiceA --configuration Release },
    { & dotnet build src/ServiceB --configuration Release },
    { & npm run build --prefix frontend },
    { & cargo build --release --manifest-path rust/Cargo.toml }
)
$jobs | ForEach-Object -Parallel { & $_ } -ThrottleLimit 4

# Verify resource allocation
Get-Process "dotnet*","node*","cargo*" | Select-Object Name, PriorityClass, CPU, @{N='MB';E={[math]::Round($_.WorkingSet64/1MB,1)}}
```

### Example 3: Large Repository Grep/Index Operations
```powershell
# Activate for I/O-heavy operations
Get-Process "opencode*","rg*","git*" | ForEach-Object { $_.PriorityClass = "High" }
powercfg /SETACTIVE "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"

# Parallel grep across 1000+ files
$patterns = @("TODO", "FIXME", "HACK", "BUG", "XXX")
$results = $patterns | ForEach-Object -Parallel {
    rg --files-with-matches $_ . | ForEach-Object { "$_ $_" }
} -ThrottleLimit 12

# Memory-efficient git blame on large files
git ls-files | Where-Object { (Get-Item $_).Length -gt 10MB } | ForEach-Object -Parallel {
    git blame --line-porcelain $_
} -ThrottleLimit 8
```

### Example 4: GPU-Accelerated ML/Compute Workloads
```powershell
# Activate GPU priority (requires optimize-system.ps1 first)
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" "python.exe" "High" -EA SilentlyContinue
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" "node.exe" "High" -EA SilentlyContinue

# Verify GPU scheduling
Get-Process "python*","node*" | Where-Object { $_.Modules.ModuleName -match "nvcuda|nvml|dxgi" } | 
    Select-Object Name, @{N='GPU';E={$_.Modules | Where-Object { $_.ModuleName -match "nvcuda|dxgi" }}}
```

### Example 5: Container Build Optimization
```powershell
# Activate for docker build with BuildKit
Get-Process "docker*","buildkit*","containerd*" | ForEach-Object { $_.PriorityClass = "High" }
$env:DOCKER_BUILDKIT=1
$env:BUILDKIT_PROGRESS=plain

# Parallel multi-stage builds
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:latest --push . &
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:dev --target dev --push . &
Wait-Job
```

## Testing Scenarios

### Test 1: Priority Persistence Across Process Spawn
```powershell
# Verify child processes inherit High priority
Get-Process "opencode*" | ForEach-Object { $_.PriorityClass = "High" }
Start-Process pwsh -ArgumentList "-c", "Get-Process -Id $PID | Select PriorityClass" -Wait
# Expected: Child process shows High priority
```

### Test 2: Power Plan Restore on Failure
```powershell
# Simulate crash mid-operation, verify restore works
$originalPlan = powercfg /GETACTIVESCHEME
try {
    powercfg /SETACTIVE "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    Get-Process "opencode*" | ForEach-Object { $_.PriorityClass = "High" }
    throw "Simulated crash"
} finally {
    Get-Process "opencode*" | ForEach-Object { $_.PriorityClass = "Normal" }
    powercfg /SETACTIVE $originalPlan
}
# Verify: powercfg /GETACTIVESCHEME matches $originalPlan
```

### Test 3: Memory-Mapped vs StreamReader Benchmark
```powershell
# Benchmark different read methods on 100MB file
$file = "test-100mb.log"
$methods = @{
    "Get-Content -Raw" = { Get-Content $file -Raw }
    "StreamReader" = { [System.IO.StreamReader]::new($file).ReadToEnd() }
    "File.ReadAllBytes" = { [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($file)) }
    "MemoryMapped" = { 
        $mmf = [System.IO.MemoryMappedFiles.MemoryMappedFile]::CreateFromFile($file)
        $stream = $mmf.CreateViewStream()
        [System.IO.StreamReader]::new($stream).ReadToEnd()
    }
}
$methods.GetEnumerator() | ForEach-Object {
    $name = $_.Key; $action = $_.Value
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $action
    $sw.Stop()
    "$name: $($sw.ElapsedMilliseconds)ms"
}
# Expected: MemoryMapped fastest for >50MB, StreamReader best for 1-50MB
```

## Edge Cases

### Edge Case 1: Non-Admin Power Plan Change
```powershell
# Admin rights required for powercfg /SETACTIVE on some systems
try {
    powercfg /SETACTIVE "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
} catch {
    Write-Warning "Power plan change requires Admin. Continuing with process priority only."
    # Fallback: Set PROCTHROTTLEMIN/MAX via registry if available
}
```

### Edge Case 2: GPU Priority No-Op for Non-DirectX Apps
```powershell
# GPU priority only affects DirectX/Vulkan apps, not CUDA/OpenCL/CLI tools
# For CUDA workloads, use: nvidia-smi -pl <watts> or nvidia-smi -ac <clock>
# For OpenCL: clSetDevicePriority (requires vendor SDK)
# Verify: Check if process loads d3d11.dll, dxgi.dll, or vulkan-1.dll
```

### Edge Case 3: Process Priority Reset on Restart
```powershell
# PriorityClass reverts to Normal when process restarts
# Solution: Wrap in a monitor loop or use Job objects
$job = Start-Job {
    while ($true) {
        Get-Process "opencode*","node*" -EA SilentlyContinue | 
            ForEach-Object { if ($_.PriorityClass -ne "High") { $_.PriorityClass = "High" } }
        Start-Sleep 30
    }
}
# Cleanup: Stop-Job $job on deactivate
```

### Edge Case 4: ThrottleLimit Starvation on Low-Core Machines
```powershell
# -ThrottleLimit 8 on 4-core machine causes contention
$coreCount = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
$throttle = [math]::Min(8, $coreCount * 2)
$files | ForEach-Object -Parallel { ... } -ThrottleLimit $throttle
```

## Anti-Patterns

1. **Activate dev mode for 1MB files** — No measurable benefit, adds complexity
2. **Forget to deactivate** — Leaves system in High priority, drains battery, starves other apps
3. **Run before optimize-system.ps1** — Registry keys missing, GPU priority no-op, power plan may not exist
4. **Expect GPU boost for CLI tools** — GPU priority only applies to DirectX/Vulkan graphics pipelines
5. **Hardcode ThrottleLimit** — Causes thread starvation on low-core or hyperthreaded CPUs
6. **Assume priority inheritance works everywhere** — Some process launchers (cmd.exe, certain shells) reset priority

## Refs
execution-mode · lean-context · context-watchdog · performance-tracker · command-wrapper
