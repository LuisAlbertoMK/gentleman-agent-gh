---
name: dreaming
description: "Cross-session pattern extraction via Engram. Run via !dream — not automatic."
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "1.4"
  changelog: "1.4: added auto-pattern-detector + learning-stats integration. 1.3: opt-in only (!dream). No auto mini-dream every 5 tools. No MANDATORY scan at session start."
triggers: "!dream, dreaming, patrones, 'memory review', session end via !close"
---
## TRIGGER
Only on explicit request (!dream) or user asking. Recommended weekly or after milestone.
No automatic mini-dream every 5 tools — eliminated to reduce ceremony.
**Auto-pattern trigger**: same error 3x → run `auto-pattern-detector.ps1` → propose anti-pattern to immune-system.

## SCRIPTS
| Script | Purpose | When |
|--------|---------|------|
| `scripts/auto-pattern-detector.ps1` | Scan learnings + errors, propose new anti-patterns | !dream, same error 3x |
| `scripts/learning-stats.ps1` | Pattern counts, trends, health metrics | !dream, !score |
| `scripts/session-miner.ps1` | Mine session histories for error patterns | !dream full |
| `scripts/run-dreaming.ps1` | Full dreaming cycle orchestrator | !dream |

## MODES
| Mode | When | Action |
|------|------|--------|
| **Quick scan** | !dream quick | `mem_context` + `mem_search(keywords=recent work)` + `auto-pattern-detector.ps1` |
| **Harvest** | !close | `mem_session_summary` + extract patterns (error→catalog, workflow→skill) |
| **Full dream** | !dream (weekly) | `mem_search(type="error|bugfix|pattern|decision")` + `auto-pattern-detector.ps1` + `learning-stats.ps1`. ≥2→anti-pattern. ≥3→AGENTS.md rule. |

## PROACTIVE RECALL
BEFORE any task: extract 3-5 keywords, `mem_search(query="<keywords>", limit=3)`. If found → apply past learnings.

## PROJECT FINGERPRINT
First interaction per project: detect lang/framework/arch, save to engram.
On subsequent sessions: `mem_search(query="project/{name}", scope=project)` to reload.

## ANTI-PATTERNS
❌ Isolated sessions · fix-only-no-document · every session fresh · no memory scan before work
✅ Cross-session patterns · permanent immunity · curate signal/drop noise · scan memory first

## IMMUNE-SYSTEM INTEGRATION
When `auto-pattern-detector.ps1` returns `Status: PATTERNS_FOUND`:
1. For each proposal → invoke immune-system protocol (detect→diagnose→document→immunize)
2. If same error 3+ times → mandatory catalog entry + AGENTS.md prevention rule
3. Cross-reference with `learning-stats.ps1` to validate trend before promotion
4. Flow: `auto-pattern-detector.ps1` → immune-system detect → ANTI-PATTERN-CATALOG.md → AGENTS.md rule
