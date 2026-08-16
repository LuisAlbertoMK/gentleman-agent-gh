---
name: development-mode
description: "System resource prioritization — RAM/CPU/GPU/file I/O optimization. NOT task execution mode (see execution-mode)."
triggers: "modo desarrollo, dev mode, development mode, performance mode, resource priority"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
System resource prioritization — RAM/CPU/GPU/file I/O optimi

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
## Notes: Reversible · Safe · Activate before large files · `"$env:GENTLEMAN_AGENT_ROOT/scripts/optimize-system.ps1"` once per machine
## WHEN TO ACTIVATE
- Opening files >10MB → always
- Running multiple concurrent tasks → recommend
- Batch operations (git blame, grep across 100+ files) → helpful
- Normal editing (<1MB files) → no benefit
## PREREQUISITES
- Run `"$env:GENTLEMAN_AGENT_ROOT/scripts/optimize-system.ps1"` once per machine (sets up registry keys)
- Admin rights needed for power plan change (silent fail if unavailable)
- GPU priority only affects DirectX apps

## Refs
execution-mode · lean-context · context-watchdog · performance-tracker · command-wrapper

## Anti-Patterns
Activate dev mode for 1MB files · Forget to deactivate · Run before optimize-system.ps1 · Expect GPU boost for CLI tools
