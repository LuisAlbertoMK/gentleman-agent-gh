---
name: development-mode
description: "System resource prioritization — RAM/CPU/GPU/file I/O optimization. NOT task execution mode (see execution-mode)."
triggers: "modo desarrollo, dev mode, development mode, performance mode, resource priority"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2582
---

## When to Use
System resource prioritization — RAM/CPU/GPU/file I/O optimization. NOT task execution mode (see execution-mode).

## Complementary: opencode-skillful (-30-50%) · opencode-dcp (-50-70%) · context-mode (-98%) · opencode-lazy-loader

## Activate (on user approval)
**Process Priority**: `Get-Process "opencode*","node*","bun*" | ForEach-Object { $_.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High }`
**Power Plan**: `powercfg /SETACTIVE "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"` + PROCTHROTTLEMIN/MAX 100
**GPU**: `Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" "opencode.exe" "High" -EA SilentlyContinue`

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
---

docs/skills/development-mode/reference.md
---
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Modo dev = modo de ejecución" | Confusing dev-mode (RAM/CPU) with execution-mode (QUICK/THOROUGH) | dev-mode=PriorityClass/powercfg, execution-mode=SDD pipeline — check Refs |
| "Siempre High priority" | Activating for <1MB files | WHEN TO ACTIVATE: >10MB→always, <1MB→no benefit — check size first |
| "Admin innecesario" | Skipping optimize-system.ps1 prereq | Run `optimize-system.ps1` once — verify registry keys before power plan |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: performance | execution-mode

