---
name: dreaming
description: > Cross-session pattern extraction. Review Engram memory, find recurring patterns, curate memory, update skills.
  Trigger: Session start, session end, periodic self-check, "dream", "patrones", "memory review", every ~5 tool calls.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## Core Concept

Dreaming = scheduled review of past sessions to find patterns and self-improve.
Inspired by Claude Managed Agents Dreaming (research preview) + Memento-Skills Read-Write Reflective Learning.

## Protocol

### SESSION START — quick scan
```
1. `mem_context` — what was done in last session
2. `mem_search(query="error|bug|fix|wrong|mistake")` — unresolved issues?
3. Scan ANTI-PATTERN-CATALOG.md — active immunizations
4. Check: is current task similar to past failure? → apply prevention
```

### SESSION END — reflection harvest
```
1. `mem_session_summary` — structured close (mandatory)
2. Extract patterns from session:
   - Recurring error? → add to ANTI-PATTERN-CATALOG.md
   - New workflow? → create/update skill
   - Architecture decision? → `mem_save`
3. Cross-session pattern check:
   - Same error across 2+ sessions? → permanent rule in AGENTS.md
   - Same tool misused 2+ times? → update tool description in skill
```

### PERIODIC (~5 tool calls) — mini-dream
```
1. Self-check: Quality? Efficiency? Reusability? Improvement?
2. Auto-improve: identify skill gap → create/update
3. Immune check: any error repeated? → document in catalog
```

### FULL DREAM (after major milestone) — deep curation
```
1. `mem_search(type="error|bugfix")` across ALL sessions
2. Cluster errors by root cause:
   └── Same root cause ≥2 → document as anti-pattern
   └── Same root cause ≥3 → promote to AGENTS.md rule
3. `mem_search(type="decision|architecture")` across ALL sessions
   └── Contradicting decisions? → flag for user review
   └── Recurring pattern? → extract to skill
4. Curation:
   └── Stale observations (no relevance) → note for cleanup
   └── Critical observations → ensure topic_key is set
```

## Workflow Diagram
```
Session Start
├── Quick dream (mem_context + anti-pattern scan)
├── Work...
├── Every ~5 tools → mini-dream
├── Work...
└── Session End → reflection harvest → commit to catalog

Milestone → Full dream → skill updates → AGENTS.md improvements
```

## Triggers
| Trigger | Action |
|---------|--------|
| Session starts | Quick scan: context + anti-patterns |
| Session ends | Reflection harvest + catalog update |
| Every 5 tool calls | Mini-dream self-check |
| Major milestone | Full dream: cross-session curation |
| Same error 2x | Anti-pattern entry |
| Same error 3x | AGENTS.md rule |

## Anti-Patterns
| ❌ Don't | ✅ Do |
|----------|-------|
| Each session is isolated | Cross-session pattern extraction |
| Only fix current error | Document for permanent immunity |
| Let Engram grow unbounded | Curate: promote signal, drop noise |
| Treat every session as new | Scan memory before starting |
