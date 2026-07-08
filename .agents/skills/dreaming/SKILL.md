---
name: dreaming
description: "Cross-session pattern extraction via Engram. Run via !dream — not automatic."
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "1.4"
  changelog: "1.4: added auto-pattern-detector + learning-stats. 1.3: opt-in !dream only."
  triggers: "!dream, dreaming, patrones, 'memory review', session end via !close"
---
## TRIGGER
Only on explicit request (`!dream`) or user asking. Recommended weekly or after milestone.
**Auto-pattern trigger**: same error 3x → run `auto-pattern-detector.ps1` → propose anti-pattern to immune-system.

## MODES
| Mode | When | Action |
|------|------|--------|
| **Quick scan** | `!dream quick` | `mem_context` + `mem_search(recent work)` + `auto-pattern-detector.ps1` |
| **Harvest** | `!close` | `mem_session_summary` + extract patterns (error→catalog, workflow→skill) |
| **Full dream** | `!dream` (weekly) | `mem_search(error\|bugfix\|pattern\|decision)` + detector + stats. ≥2→anti-pattern. ≥3→AGENTS.md rule. |
| **Wisdom review** | `!dream full` (monthly) | `wisdom-demote.ps1 -All -DryRun` → report → ask → proceed. See `scripts/` below. |

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
| `forge-rollback.ps1` | Revert forge |
| `pattern-guard.ps1` | LAZY pre-flight detection |
| `wisdom-stats.ps1` | Store metrics |

## RECALL
Extract 3-5 keywords, `mem_search(query="<keywords>", limit=3)` → apply past learnings.

## FINGERPRINT
First interaction per project: detect lang/framework/arch, save to engram.
Subsequent: `mem_search(query="project/{name}", scope=project)` to reload.

## ANTI-PATTERNS
❌ Isolated sessions · fix-only-no-document · every session fresh · no memory scan before work
✅ Cross-session patterns · permanent immunity · curate signal/drop noise · scan memory first

## IMMUNE INTEGRATION
When `auto-pattern-detector.ps1` returns `Status: PATTERNS_FOUND`:
1. For each proposal → invoke immune-system (detect→diagnose→document→immunize)
2. Same error 3+ times → mandatory catalog entry + AGENTS.md rule
3. Cross-ref with `learning-stats.ps1` to validate trend before promotion
4. Flow: `auto-pattern-detector.ps1` → immune-system detect → ANTI-PATTERN-CATALOG.md → AGENTS.md rule
