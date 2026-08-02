---
description: Switch permission mode to AUTO — all commands auto-approved except push + deletes
---

You are executing `!auto`. Switch the current project to AUTO permission mode.

Steps:

1. **Resolve script root**:
   `$root = $env:GENTLEMAN_AGENT_ROOT; if (-not $root -or -not (Test-Path "$root\scripts\switch-mode.ps1")) { $root = "$env:USERPROFILE\.config\opencode" }`
2. **Switch via script when available**:
   if `Test-Path "$root\scripts\switch-mode.ps1"` → run `& "$root\scripts\switch-mode.ps1" -Mode auto`.
3. **Fallback** (script missing): resolve the current PROJECT root (walk-up from cwd to the first `.git`; if none, use cwd) and write the mode file there:
   `$projRoot = (Get-Location).Path; $cur = $projRoot; while ($true) { if (Test-Path (Join-Path $cur '.git')) { $projRoot = $cur; break }; $p = Split-Path -Parent $cur; if (-not $p -or $p -eq $cur) { break }; $cur = $p }; Set-Content -LiteralPath (Join-Path $projRoot '.gentleman-mode') -Value 'auto' -NoNewline -Encoding Ascii`
4. **Verify**: run `& "$root\scripts\switch-mode.ps1" -Status`. Note: the script resolves the CURRENT PROJECT root (walk-up from cwd to the git root) and reads/writes `.gentleman-mode` THERE — NOT next to itself. If the fallback ran, `Get-Content (Join-Path $projRoot '.gentleman-mode')` must equal `auto`.

Report the mode summary: AUTO = git/file/scripts/commit auto-approved; push ASKS; destructive (rm, curl, ssh, docker, python, node) DENIED. Remind that delegation will use the `-auto` routing suffix and log to `.gentleman/audit.log` in the project root.
