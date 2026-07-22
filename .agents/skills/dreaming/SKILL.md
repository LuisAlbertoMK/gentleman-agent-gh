---
name: dreaming
description: "Cross-session pattern extraction via Engram. Run via !dream — not automatic."
triggers: "!dream, dreaming, patrones, memory review, session end, !close, pattern extraction"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "1.6"
  changelog: "1.6: auto-dream trigger on session close / 10th error. 1.5: karpathy compress. 1.4: added auto-pattern-detector + learning-stats."
---
## TRIGGER
Only on explicit request (`!dream`) or user asking. Recommended weekly or after milestone.
**Auto-pattern trigger**: same error 3x → `auto-pattern-detector.ps1` → propose anti-pattern to immune-system.

## MODES
| Mode | When | Action |
|------|------|--------|
| **Quick scan** | `!dream quick` | `mem_context` + `mem_search` + `auto-pattern-detector.ps1` |
| **Harvest** | `!close` | `mem_session_summary` + extract patterns |
| **Full dream** | `!dream` (weekly) | `mem_search` + detector + stats. ≥2→anti-pattern. ≥3→AGENTS.md rule |
| **Feed** | `!dream feed` | Extract patterns → JSON for skill-graph |
| **Wisdom review** | `!dream full` (monthly) | `wisdom-demote.ps1 -All -DryRun` → report → ask → proceed |

## SCRIPTS
| Script | Purpose |
|--------|---------|
| `run-dreaming.ps1` | Full dreaming orchestrator |
| `session-miner.ps1` | Mine session histories for error patterns |
| `auto-pattern-detector.ps1` | Scan learnings + errors → anti-pattern proposals |
| `learning-stats.ps1` | Pattern health metrics |
| `wisdom-store.ps1` | Save/migrate patterns |
| `wisdom-loader.ps1` | Retrieve by domain/tech/keywords |
| `wisdom-forge.ps1` | Promote pattern→skill (9 gates) |
| `wisdom-demote.ps1` | Periodic demote/remove/archive |
| `pattern-guard.ps1` | LAZY pre-flight detection |

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
When `auto-pattern-detector.ps1` returns `PATTERNS_FOUND`:
1. Each proposal → immune-system (detect→diagnose→document→immunize)
2. Same error 3+ times → mandatory catalog + AGENTS.md rule
3. Cross-ref with `learning-stats.ps1` before promotion

## Auto-Dream Trigger
At session close (via `!close`), count new memories since last dream:
1. `mem_search(type="error|bugfix|decision|discovery", limit=10)` — filter results timestamped after the last dream timestamp.
2. If **>5 new memories**: auto-execute the dreaming protocol (Quick scan mode).
3. If **≤5 new memories**: skip — no overhead.
4. After auto-dream, record the timestamp via `mem_save(type="config", topic_key="dreaming/last-auto-dream", content="Last auto-dream: {timestamp}")`.

This ensures cross-session patterns are extracted when memory volume signals enough new signal to harvest, without wasting cycles on low-activity sessions.

## Refs
immune-system · cross-project-wisdom · auto-metrics · session-resume · bitacora
