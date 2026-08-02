---
description: Compact the Engram memory DB without losing information — backup, dedupe, purge stale sync, VACUUM
---

You are executing `!engram-compact`. Optimize the Engram memory database (`~\.engram\engram.db`) without losing information.

`$ARGUMENTS` = optional `-Yes` to apply, or extra flags (e.g. `-PurgeSyncOlderThanDays 14`). Without `-Yes` the script runs in dry-run mode.

Steps:

1. **Resolve root**: `$root = $env:GENTLEMAN_AGENT_ROOT; if (-not $root) { $root = Split-Path $PSScriptRoot -Parent }`
2. **Dry-run first (mandatory)**: run `& "$root\scripts\engram-compact.ps1" -DryRun -Quiet`. Report before/after sizes, dedupe counts, purge count.
3. **Apply**: if the user confirmed or auto mode allows, run `& "$root\scripts\engram-compact.ps1" -Yes -Quiet`. This creates a timestamped backup in `~\.engram\backups\` and exports stale sync mutations to CSV **before** deleting anything.
4. **Verify**: run `engram doctor` (or `mem_doctor` MCP) — expect `sqlite_lock_contention: ok` and 4/4 checks ok.
5. **Report**: file size before → after, rows removed per table, backup path.

Do NOT run against a DB while an engram MCP server is mid-write; retry once if `busy_timeout` errors appear. Do NOT use `-PurgeSyncOlderThanDays 0` unless the user explicitly asks to skip purge.
