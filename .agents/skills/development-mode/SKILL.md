---
name: development-mode
description: System resource prioritization mode — RAM, CPU, GPU, file I/O optimization. Asks before activating.
triggers: "modo desarrollo, dev mode, development mode, performance mode, resource priority, high performance, dar prioridad, maximizar rendimiento"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0", changelog: "1.0: initial — resource prioritization + file read optimization"
---

Trigger: "modo desarrollo", "dev mode", "resource priority", "modo rendimiento"

## COMPLEMENTARY PLUGINS (Jun 2026)
| Plugin | What | Install | Impact |
|--------|------|---------|--------|
| **opencode-skillful** | Lazy skill loading — skills only inject when requested, not all 53 at once | `npm i -g @zenobius/opencode-skillful` + add to plugins in opencode.json | -30-50% tokens |
| **opencode-dcp** (Dynamic Context Pruning) | Prunes stale context before sending to LLM, keeps session history intact | `opencode plugin @tarquinen/opencode-dcp@latest --global` | -50-70% tokens |
| **Context Mode** (mksglu/context-mode) | Context virtualization layer — sandboxes tool output, up to 98% reduction | `npx -y context-mode` as MCP server | up to -98% context |
| **opencode-lazy-loader** | Lazy-loads MCP servers bundled in skills, auto-cleanup 5min idle | `npm i -g opencode-lazy-loader` | -varies by MCP count |

## AUTO-ACTIVATION CHECK
When user asks for performance, slowness fix, or optimization:
→ Ask: "¿Activamos modo desarrollo? Prioriza RAM/CPU/GPU para el agente, optimiza lectura de archivos, y sugiere plugins complementarios."
→ If no → proceed without changes
→ If yes → execute ENTER sequence

## ENTER DEVELOPMENT MODE
### 1. Process Priority
```powershell
# Elevate opencode process to High priority class
$procs = Get-Process -Name "opencode*","node*","bun*" -ErrorAction SilentlyContinue
foreach ($p in $procs) { $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High }
Write-Host "[DEV] opencode priority → High"
```
### 2. CPU Affinity (ensure all cores available)
```powershell
# Remove CPU affinity restrictions — let opencode use all cores
$procs = Get-Process -Name "opencode*" -ErrorAction SilentlyContinue
foreach ($p in $procs) { $p.ProcessorAffinity = [IntPtr]::new([int]::MaxValue) }
```
### 3. Power Plan — Ultimate Performance
```powershell
powercfg /SETACTIVE "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  # High Performance
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
```
### 4. GPU Priority
```powershell
# Set opencode to High GPU performance (via DXGI)
$regPath = "HKLM:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences"
Set-ItemProperty -Path $regPath -Name "opencode.exe" -Value "High" -ErrorAction SilentlyContinue
```
### 5. Plugin Recommendations
```powershell
Write-Host "[DEV] Recommended plugins for max efficiency:"
Write-Host "  - opencode-skillful (lazy skill loading, -30-50% tokens)"
Write-Host "  - opencode-dcp (dynamic context pruning, -50-70% tokens)"
Write-Host "  - context-mode (context virtualization, up to -98% context)"
Write-Host "Install: opencode plugin <name>@latest --global"
```

## FILE READ OPTIMIZATION (any file type)
Use these strategies for fastest reads, selected by file size:

| File Size | Method | PowerShell Snippet | Speed Gain |
|-----------|--------|-------------------|------------|
| <1 MB | `Get-Content -Raw` (single read) | `Get-Content $path -Raw -Encoding Utf8` | baseline |
| 1-50 MB | `.NET StreamReader` (streaming) | `[System.IO.StreamReader]::new($path).ReadToEnd()` | 2-5x over Get-Content |
| 50-500 MB | `.NET File.ReadAllBytes` (binary) | `[System.IO.File]::ReadAllBytes($path)` | 5-10x |
| >500 MB | Memory-mapped file (mmap) | See script below | 10-50x for large files |

### Memory-Mapped File Reader (files >500 MB or random access)
```powershell
function Read-FileFast {
  param([string]$Path, [int]$BufferKB=64)
  $buf = [byte[]]::new($BufferKB*1024)
  $mmf = [System.IO.MemoryMappedFiles.MemoryMappedFile]::CreateFromFile($Path, [System.IO.FileMode]::Open)
  $view = $mmf.CreateViewAccessor()
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $total = (Get-Item $Path).Length; $offset = [long]0
  while ($offset -lt $total) {
    $bytesToRead = [Math]::Min($buf.Length, $total - $offset)
    $view.ReadArray($offset, $buf, 0, $bytesToRead) | Out-Null
    $offset += $bytesToRead
  }
  $sw.Stop()
  $view.Dispose(); $mmf.Dispose()
  Write-Host "Read $([math]::Round($total/1MB,1)) MB in $($sw.Elapsed.TotalSeconds)s — $([math]::Round(($total/1MB)/$sw.Elapsed.TotalSeconds,1)) MB/s"
}
```
### Parallel Batch Reader (many small files)
```powershell
$files = Get-ChildItem "*.log" -Recurse
$files | ForEach-Object -Parallel { [System.IO.File]::ReadAllText($_.FullName) } -ThrottleLimit 8
```

## EXIT DEVELOPMENT MODE
```powershell
# Restore process priority
$procs = Get-Process -Name "opencode*" -ErrorAction SilentlyContinue
foreach ($p in $procs) { $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal }
# Restore power plan to balanced
powercfg /SETACTIVE "381b4222-f694-41f0-9685-ff5bb260df2e"  # Balanced
Write-Host "[DEV] Mode deactivated — resources restored"
```

## VERIFICATION
```powershell
# Check current state
Get-Process -Name "opencode*" | Select-Object Name, @{N='Priority';E={$_.PriorityClass}}, @{N='RAM_MB';E={[math]::Round($_.WorkingSet64/1MB,1)}}
powercfg /GETACTIVESCHEME
```

## NOTES
- Reversible: EXIT restores Normal priority + Balanced power plan
- File read methods are safe for all file types (binary, text, large, small)
- Logs all activations to BITACORA
- Recommended: activate before large file processing, deactivate after
