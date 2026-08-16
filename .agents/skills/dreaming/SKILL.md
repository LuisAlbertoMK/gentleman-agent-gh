---
name: dreaming
description: "Cross-session pattern extraction via Engram. Run via !dream — not automatic."
triggers: "!dream, dreaming, patrones, memory review, session end, !close, pattern extraction"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Only on explicit request (`!dream`) or user asking. Recommended weekly or after milestone.
**Auto-pattern**: same error 3x → `auto-pattern-detector.ps1` → propose anti-pattern to immune-system.

## MODES
| Mode | Action |
|------|--------|
| **Quick** `!dream quick` | `mem_context` + `mem_search` + `auto-pattern-detector.ps1` |
| **Harvest** `!close` | `mem_session_summary` + extract patterns |
| **Full** `!dream` (weekly) | `mem_search` + detector + stats. ≥2→anti-pattern. ≥3→AGENTS.md rule |
| **Feed** `!dream feed` | Extract patterns → JSON for skill-graph |
| **Wisdom review** `!dream full` (monthly) | `wisdom-demote.ps1 -All -DryRun` → report → ask → proceed |

## SCRIPTS
`run-dreaming.ps1` · `session-miner.ps1` · `auto-pattern-detector.ps1` · `learning-stats.ps1` · `wisdom-store.ps1` · `wisdom-loader.ps1` · `wisdom-forge.ps1` · `wisdom-demote.ps1` · `pattern-guard.ps1`

## SKILL-GRAPH BRIDGE
```powershell
.\scripts\run-dreaming.ps1 -Mode feed -OutputPath .learnings\skill-graph-patterns.json
.\scripts\skill-graph.ps1 -Task "fix auth bug" -PatternsFile .learnings\skill-graph-patterns.json
```
Pattern format: `{ keywords: [], boost: "skill-name", reason: "..." }`

## RECALL
Extract 3-5 keywords → `mem_search(query="<keywords>", limit=3)` → apply past learnings.

## ANTI-PATTERNS
❌ Isolated sessions · fix-only-no-document · every session fresh · no memory scan
✅ Cross-session patterns · permanent immunity · curate signal/drop noise · scan memory first

## IMMUNE INTEGRATION
When `auto-pattern-detector.ps1` returns `PATTERNS_FOUND`: each proposal → immune-system (detect→diagnose→document→immunize). Same error 3+ times → mandatory catalog + AGENTS.md rule. Cross-ref with `learning-stats.ps1` before promotion.

## Auto-Dream Trigger
At session close (`!close`), count new memories since last dream:
1. `mem_search(type="error|bugfix|decision|discovery", limit=10)` — filter results after last dream timestamp.
2. If **>5 new memories**: auto-execute Quick scan protocol.
3. If **≤5**: skip.
4. After auto-dream, record timestamp: `mem_save(type="config", topic_key="dreaming/last-auto-dream", content="Last auto-dream: {timestamp}")`.

## Refs
immune-system · cross-project-wisdom · auto-metrics · session-resume · bitacora
