---
name: development-mode
description: System resource prioritization mode — RAM, CPU, GPU, file I/O optimization. Asks before activating.
triggers: "modo desarrollo, dev mode, development mode, performance mode, resource priority, high performance, dar prioridad, maximizar rendimiento"
license: Apache-2.0
metadata:
  tags:
    - tools
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.1: compressed"
---

## COMPLEMENTARY PLUGINS
opencode-skillful (npm i -g, -30-50% tokens) | opencode-dcp (plugin --global, -50-70%) | context-mode (npx MCP, -98%) | opencode-lazy-loader (npm i -g)

## ENTER (activate on user approval)

### Process Priority
Get-Process -Name "opencode*","node*","bun*" -ErrorAction SilentlyContinue | ForEach-Object { .PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High }

### CPU Affinity
Get-Process -Name "opencode*" -ErrorAction SilentlyContinue | ForEach-Object { .ProcessorAffinity = [IntPtr]::new([int]::MaxValue) }

### Power Plan (Admin)
powercfg /SETACTIVE "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100
powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100

### GPU Priority
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" -Name "opencode.exe" -Value "High" -ErrorAction SilentlyContinue

## FILE READ OPTIMIZATION
| Size | Method | vs Get-Content |
|------|--------|----------------|
| <1 MB | Get-Content -Raw | 1x |
| 1-50 MB | StreamReader | 2-5x |
| 50-500 MB | File.ReadAllBytes | 5-10x |
| >500 MB | Memory-mapped | 10-50x |

### Large File Readers
`powershell
function Read-FileFast(, =64) {
   = [byte[]]::new(*1024)
   = [System.IO.MemoryMappedFiles.MemoryMappedFile]::CreateFromFile(, [System.IO.FileMode]::Open)
   = .CreateViewAccessor();  = (Get-Item ).Length
  for ( = [long]0;  -lt ;  += ) {
     = [Math]::Min(.Length,  - )
    .ReadArray(, , 0, ) | Out-Null
  }
  .Dispose(); .Dispose()
}
Get-ChildItem "*.log" -Recurse | ForEach-Object -Parallel { [System.IO.File]::ReadAllText(.FullName) } -ThrottleLimit 8
`

## EXIT
Get-Process -Name "opencode*" | ForEach-Object { .PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal }
powercfg /SETACTIVE "381b4222-f694-41f0-9685-ff5bb260df2e"

## VERIFICATION
Get-Process -Name "opencode*" | Select-Object Name, @{N='Prio';E={.PriorityClass}}, @{N='MB';E={[math]::Round(.WorkingSet64/1MB,1)}}
powercfg /GETACTIVESCHEME

## NOTES
Reversible (EXIT restores Normal+Balanced) | Safe for all file types | Activate before large files | Run scripts/optimize-system.ps1 once per machine
