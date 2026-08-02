# Shortcuts — Gentleman Agent

**Single source of truth** for all agent shortcuts. Use these in OpenCode chat.

---

## Workflow Shortcuts

| Shortcut | Action | When to Use |
|----------|--------|-------------|
| `!score` | Score auto-update + docs sync | After significant changes |
| `!health` | Full diagnostics (git, drift, cross-ref, score) | When something fails |
| `!close` | Session close pipeline (bitacora + inter-track++) | End of session |
| `!batch` | New batch with auto-increment + bitacora | Multiple tasks in sequence |
| `!cycle` | Cycle status summary | Check progress |
| `!sync` | Upstream check + drift + score update | Keep in sync |
| `!compress` | Karpathy compress skills >2.5KB | Skill optimization |
| `!engram-compact` | Compact Engram DB — backup, dedupe, purge stale sync, VACUUM (dry-run first) | Memory bloat, slow engram search |
| `!clean` | Leave repo clean — untracked, .bak/.tmp junk, dangling junctions, optional git gc (dry-run first) | Repo accumulated junk |
| `!analisis` | Multi-agent analysis (6 specialists, 8 dimensions) | Deep analysis |
| `!ejecutar` | Execute analysis findings with parallel subagents | After `!analisis` completes |

## Permission Modes

| Shortcut | Action |
|----------|--------|
| `!auto` | Switch to AUTO — all commands auto-approved except push + deletes |
| `!semi` | Switch to SEMI-AUTO — safe commands auto-approved, rest ask |
| `!manual` | Switch to MANUAL — every command asks (default) |
| `!mode` | Show current permission mode |

Mode file: `.gentleman-mode` in project root. Switch via `scripts/switch-mode.ps1`.

## Ponytail Mode

| Shortcut | Action |
|----------|--------|
| `!ponytail lite` | Default — minimal ceremony |
| `!ponytail full` | Complex/risky tasks |
| `!ponytail ultra` | Refactoring sessions |
| `!ponytail off` | Debugging only |

## Verification Modes

| Shortcut | Verify | Gate | Commit |
|----------|--------|------|--------|
| `!ship` | Triple verify | Quality gate + PSSA | ✅ auto |
| `!check` | Verify profiles | Quality gate | ❌ |
| `!fast` | Skip | Quality gate | ✅ auto |
| `!draft` | Skip | Skip | ❌ |

## SDD Pipeline

| Shortcut | Phase |
|----------|-------|
| `!sdd init` | Initialize SDD context |
| `!sdd propose` | Create change proposal |
| `!sdd spec` | Write specifications |
| `!sdd design` | Technical design |
| `!sdd tasks` | Break into tasks |
| `!sdd apply` | Implement changes |
| `!sdd verify` | Validate implementation |
| `!sdd archive` | Archive completed work |

## Setup & Dev

| Shortcut | Action |
|----------|--------|
| `!setup` | Setup machine (.ps1 or .sh) |
| `!dev` | Manage background dev servers |
| `!gentleman` | Inherit config in another project |

## Quick Reference

```
# Most common flow:
1. !health          ← check status
2. [do work]        ← agent executes
3. !score           ← measure result
4. !close           ← save and exit

# Quick analysis:
!analisis           ← deep multi-agent analysis
!ejecutar           ← execute findings in parallel (after !analisis)

# Emergency:
!health             ← diagnose issues
!ponytail off       ← disable ceremony gates
```

---

*Last updated: 2026-07-28*
*This is the single source of truth. Other docs should reference this file.*
