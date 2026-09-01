---
name: dreaming
description: "Cross-session pattern extraction via Engram. Run via !dream — not automatic."
triggers: "!dream, dreaming, patrones, memory review, session end, !close, pattern extraction"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2553
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
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/dreaming/reference.md

---
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Skill without verification" | Doing work without checking output format | Output matches skill ## Output contract + file:line citaton |
| "Save time skipping this skill" | Using skill directly without resolving deps | skill-graph resolution + cross-ref check |
| "Output is self-evident" | No file:line or confidence marker | Cite file:line or flag confidence: unvalidated |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
Cross-Refs: engram-protocol | session-resume

