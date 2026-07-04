---
name: dreaming
description: "Cross-session pattern extraction via Engram. Run via !dream — not automatic."
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "1.3"
  changelog: "1.3: opt-in only (!dream). No auto mini-dream every 5 tools. No MANDATORY scan at session start."
triggers: "!dream, dreaming, patrones, 'memory review', session end via !close"
---
## TRIGGER
Only on explicit request (!dream) or user asking. Recommended weekly or after milestone.
No automatic mini-dream every 5 tools — eliminated to reduce ceremony.

## MODES
| Mode | When | Action |
|------|------|--------|
| **Quick scan** | !dream quick | `mem_context` + `mem_search(keywords=recent work)` + scan anti-patterns |
| **Harvest** | !close | `mem_session_summary` + extract patterns (error→catalog, workflow→skill) |
| **Full dream** | !dream (weekly) | `mem_search(type="error|bugfix|pattern|decision")` across sessions. ≥2→anti-pattern. ≥3→AGENTS.md rule. |

## PROACTIVE RECALL
BEFORE any task: extract 3-5 keywords, `mem_search(query="<keywords>", limit=3)`. If found → apply past learnings.

## PROJECT FINGERPRINT
First interaction per project: detect lang/framework/arch, save to engram.
On subsequent sessions: `mem_search(query="project/{name}", scope=project)` to reload.

## ANTI-PATTERNS
❌ Isolated sessions · fix-only-no-document · every session fresh · no memory scan before work
✅ Cross-session patterns · permanent immunity · curate signal/drop noise · scan memory first
