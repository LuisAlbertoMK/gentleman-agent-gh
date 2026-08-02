---
description: Bootstrap Gentleman Agent in an external project — opencode.json + .gentleman-mode manual
---

You are executing `!global`. Bootstrap Gentleman Agent config into an external project directory so agents, skills, and MCPs work across projects.

`$ARGUMENTS` = target directory. If omitted, use the current workspace root.

Steps:

1. **Resolve target**: use `$ARGUMENTS` or the current workspace root. Validate it exists and is a project root (has a git root or is empty). If the argument is ambiguous, ask and STOP.
2. **Resolve gentleman root**: `$root = $env:GENTLEMAN_AGENT_ROOT; if (-not $root) { $root = Split-Path $PSScriptRoot -Parent }`
3. **Preferred path**: run `& "$root\scripts\gentleman-init.ps1" -TargetDir <target> -Yes` (alias). If it is missing, fall back to `& "$root\scripts\use-gentleman.ps1" -TargetDir <target> -Yes`. Both generate the target's `opencode.json` FROM THE CHAIN (scripts/lib/opencode-base.json + permission-templates.json) — never a byte-for-byte copy of the global config.
4. **Fallback** (script unavailable or fails): bootstrap manually:
   - Write `.gentleman-mode` = `manual` in the target root (`Set-Content -LiteralPath '<target>\.gentleman-mode' -Value 'manual' -NoNewline -Encoding Ascii`).
   - Generate a minimal `opencode.json` in the target: `default_agent: gentleman-vMK`, MCP servers (engram, context7), and a `permission.bash` deny floor re-asserting the shared deny rules. Do NOT copy the global agent section verbatim.
5. **Verify**: target has `.gentleman-mode` (content `manual`) and `opencode.json` parses with `Get-Content | ConvertFrom-Json`.
6. **Report**: what was created and the exact files. Do NOT modify anything else in the target unless the user asks.
