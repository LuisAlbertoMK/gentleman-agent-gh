---
name: development-mode
description: System resource prioritization mode — RAM, CPU, GPU, file I/O optimization. Asks before activating.
triggers: "modo desarrollo, dev mode, development mode, performance mode, resource priority, high performance, dar prioridad, maximizar rendimiento"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1", changelog: "1.1: compressed"
---

Trigger: "modo desarrollo", "dev mode", "resource priority", "modo rendimiento"

## COMPLEMENTARY PLUGINS
| Plugin | Install | Impact |
|--------|---------|--------|
| opencode-skillful (lazy skill loading) | `npm i -g @zenobius/opencode-skillful` | -30-50% tokens |
| opencode-dcp (dynamic context pruning) | `opencode plugin @tarquinen/opencode-dcp@latest --global` | -50-70% tokens |
| context-mode (context virtualization) | `npx -y context-mode` as MCP server | up to -98% context |
| opencode-lazy-loader | `npm i -g opencode-lazy-loader` | -varies |

## AUTO-ACTIVATION
On performance request: "Activar modo desarrollo? Prioriza recursos y optimiza I/O."
→ yes → ENTER below | no → skip

## ENTER
### 1. Process Priority
```powershell
Get-Process -Name "opencode*","node*","bun*" -ErrorAction SilentlyContinue |
  ForEach-Object { $_.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High }
```
### 2. CPU Affinity
```powershell
Get-Process -Name "opencode*" -ErrorAction SilentlyContinue |
  ForEach-Object { $_.ProcessorAffinity = [IntPtr]::new([int]::MaxValue) }
```
### 3. Power Plan
```powershell
powercfg /SETACTIVE "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
```
### 4. GPU Priority
```powershell
$reg = "HKLM:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences"
Set-ItemProperty -Path $reg -Name "opencode.exe" -Value "High" -ErrorAction SilentlyContinue
```
### 5. Plugin Recommendations
```powershell
Write-Host "[DEV] Plugins: opencode-skillful | opencode-dcp | context-mode"
Write-Host "Install: opencode plugin <name>@latest --global"
```

## FILE READ OPTIMIZATION

| Size | Method | Code | vs Get-Content |
|------|--------|------|----------------|
| <1 MB | `Get-Content -Raw` | `Get-Content $path -Raw -Encoding Utf8` | 1× |
| 1-50 MB | StreamReader | `[System.IO.StreamReader]::new($path).ReadToEnd()` | 2-5× |
| 50-500 MB | File.ReadAllBytes | `[System.IO.File]::ReadAllBytes($path)` | 5-10× |
| >500 MB | Memory-mapped | See below | 10-50× |

### Memory-Mapped File Reader (>500 MB)
```powershell
function Read-FileFast($Path, $BufKB=64) {
  $buf = [byte[]]::new($BufKB*1024); $mmf = [System.IO.MemoryMappedFiles.MemoryMappedFile]::CreateFromFile($Path, [System.IO.FileMode]::Open)
  $view = $mmf.CreateViewAccessor(); $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $total = (Get-Item $Path).Length; $offset = [long]0
  while ($offset -lt $total) {
    $r = [Math]::Min($buf.Length, $total - $offset); $view.ReadArray($offset, $buf, 0, $r) | Out-Null; $offset += $r
  }
  $sw.Stop(); $view.Dispose(); $mmf.Dispose()
  "Read $([math]::Round($total/1MB,1)) MB in $($sw.Elapsed.TotalSeconds)s"
}
```
### Parallel Batch Reader
```powershell
Get-ChildItem "*.log" -Recurse | ForEach-Object -Parallel { [System.IO.File]::ReadAllText($_.FullName) } -ThrottleLimit 8
```

## EXIT
```powershell
Get-Process -Name "opencode*" -ErrorAction SilentlyContinue |
  ForEach-Object { $_.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal }
powercfg /SETACTIVE "381b4222-f694-41f0-9685-ff5bb260df2e"
```

## VERIFICATION
```powershell
Get-Process -Name "opencode*" | Select-Object Name,
  @{N='Prio';E={$_.PriorityClass}}, @{N='MB';E={[math]::Round($_.WorkingSet64/1MB,1)}}
powercfg /GETACTIVESCHEME
```

## NOTES
- Reversible: EXIT restores Normal + Balanced
- Safe for all file types (binary/text/large/small)
- Activate before large file processing, deactivate after
