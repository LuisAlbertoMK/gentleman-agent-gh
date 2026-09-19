# MCP Reconcile -FAIL- Report (2026-09-18)

## Decision Taken
FAIL — sync-global.ps1 -Force re-serialized the entire global config, destroying manual edits. Backup restored, byte-identical verified.

## Files Changed
- C:\Users\LuisOrozco\.config\opencode\opencode.jsonc — RESTORED from backup (no net change)
- C:\Users\LuisOrozco\.config\opencode\opencode.jsonc.bak-force-20260918-102004 — backup created, kept for audit

## Key Findings
1. **CRITICAL** Re-serialization destroys manual edits — sync-global.ps1 -Force rewrites the entire JSONC, changing key order (permission moved to top, mcp moved to bottom), adding new permission sections (ead, dit, write), and eliminating manual bash rules (Remove-Item *Temp*opencode*: allow, Remove-Item *.tmp-*: allow).
2. **CRITICAL** Agent section rewritten — despite "preserved 58 agents", the script re-serialized all agent definitions, changing description text (e.g., "Amdahl's Law" → "Amdahl's law"), adding 	ools: { "codebase-memory*": true } to agents that didn't have it, and restructuring permission blocks.
3. **HIGH** New top-level permission sections injected — ead, dit, write permission maps were added that didn't exist in the manual version, expanding the config surface beyond what was intentional.
4. **MEDIUM** Junction check code didn't detect Windows symlinks — the sync reported 101/101 valid junctions but the post-restore check using Get-ChildItem with ReparsePoint filter found 0 (platform-specific symlink detection issue, not a sync problem).
5. **LOW** No repo changes committed — sync did not git-commit any registry changes as expected per the guard a933774a.

## Pre-State vs Post-Restore (all match)
| Pattern | Pre | Post-Restore |
|---------|-----|--------------|
| Total lines | 1546 | 1546 |
| clean-worktree-temp | 1 | 1 |
| Temp.*opencode | 1 | 1 |
| Remove-Item.*allow | 2 | 2 |
| pwsh * deny | 0 | 0 |
| bash sections | 59 | 59 |

## What the Sync Actually Did (Evidence)
- Line 2 key: "mcp" → "permission" (reordered top-level)
- Added: ead, dit, write permission sections (not in original)
- Removed: Remove-Item *Temp*opencode*: allow, Remove-Item *.tmp-*: allow from bash
- Agent descriptions rewritten (case changes, added tools blocks)
- Net result: +117 lines (1546 → 1663) before restore

## Nuance
The sync script's -Force flag bypasses the agent drift guard (a933774a) but its JSON serialization is lossy — it doesn't preserve key ordering, comments, or manual edits that differ from its canonical representation. The script correctly reconciles MCP/agent definitions but as a side effect destroys any manual customizations. To reconcile MCPs safely, the script needs either: (a) a targeted MCP-only write path that doesn't touch permission/bash sections, or (b) a diff-and-patch approach instead of full rewrite.

## Recommendation
Do NOT run sync-global.ps1 -Force again until the script is fixed to:
1. Preserve manual bash permission rules (especially safe-path rules)
2. Preserve key ordering in JSON serialization
3. Only write MCP/agent sections, not permission.bash
