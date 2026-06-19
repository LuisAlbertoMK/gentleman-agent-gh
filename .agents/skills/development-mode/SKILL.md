---
name: development-mode
description: "System resource prioritization — RAM, CPU, GPU, file I/O optimization"
triggers: "modo desarrollo, dev mode, development mode, performance mode, resource priority"
license: Apache-2.0
metadata:
  tags: [tools]
  author: gentleman-vMK
  version: "1.2"
  changelog: "1.2: karpathy compress"
---
## Complementary: opencode-skillful (-30-50%) · opencode-dcp (-50-70%) · context-mode (-98%) · opencode-lazy-loader
## Activate (on user approval)
**Process Priority**: `Get-Process "opencode*","node*","bun*" | ForEach-Object { $_.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High }`
**Power Plan**: `powercfg /SETACTIVE "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"` + PROCTHROTTLEMIN/MAX 100
**GPU**: `Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" "opencode.exe" "High" -EA SilentlyContinue`
## File Read Optimization
| Size | Method | vs Get-Content |
|------|--------|----------------|
| <1MB | Get-Content -Raw | 1x |
| 1-50MB | StreamReader | 2-5x |
| 50-500MB | File.ReadAllBytes | 5-10x |
| >500MB | Memory-mapped | 10-50x |
Multi-read: `Get-ChildItem "*.log" -Recurse | ForEach-Object -Parallel { [System.IO.File]::ReadAllText($_.FullName) } -ThrottleLimit 8`
## Deactivate (restore)
`Get-Process "opencode*" | ForEach-Object { $_.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal }`
`powercfg /SETACTIVE "381b4222-f694-41f0-9685-ff5bb260df2e"`
## Verify: `Get-Process "opencode*" | Select-Object Name, PriorityClass, @{N='MB';E={[math]::Round($_.WorkingSet64/1MB,1)}}`
## Notes: Reversible · Safe · Activate before large files · `scripts/optimize-system.ps1` once per machine
