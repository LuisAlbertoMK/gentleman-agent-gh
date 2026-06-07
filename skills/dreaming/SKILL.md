---
name: dreaming
description: > Cross-session pattern extraction. Review Engram memory, find recurring patterns, curate memory, update skills.
  Trigger: Session start, session end, periodic self-check, "dream", "patrones", "memory review", every ~5 tool calls.
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## Protocol

### SESSION START — quick scan
```
1. `mem_context` — last session context
2. `mem_search(query="error|bug|fix|wrong|mistake")` — unresolved?
3. Scan ANTI-PATTERN-CATALOG.md — active immunizations
4. Current task similar to past failure? → apply prevention
```

### SESSION END — reflection harvest
```
1. `mem_session_summary` — structured close
2. Extract patterns: recurring error? → catalog. New workflow? → skill. Arch decision? → mem_save.
3. Cross-session: same error 2+ sessions? → AGENTS.md rule. Same tool misuse 2x? → update skill.
```

### PERIODIC (~5 tool calls) — mini-dream
```
Self-check: Quality? Efficiency? Reusability? Improvement?
Auto-improve: skill gap → create/update
Immune check: error repeated? → catalog
```

### FULL DREAM (after milestone) — deep curation
```
1. `mem_search(type="error|bugfix")` across ALL sessions
2. Cluster by root cause: ≥2 → anti-pattern. ≥3 → AGENTS.md rule.
3. `mem_search(type="decision|architecture")`: contradictions? → flag. Recurring? → extract to skill.
4. Curation: stale obs → note cleanup. Critical obs → ensure topic_key.
```

## Triggers
| Trigger | Action |
|---------|--------|
| Session start | Quick scan: context + anti-patterns |
| Session end | Harvest + catalog update |
| Every 5 tools | Mini-dream self-check |
| Major milestone | Full dream curation |
| Same error 2x | Anti-pattern entry |
| Same error 3x | AGENTS.md rule |

## Anti-Patterns
| ❌ Don't | ✅ Do |
|----------|-------|
| Isolated sessions | Cross-session pattern extraction |
| Fix current error only | Document for permanent immunity |
| Engram grows unbounded | Curate: promote signal, drop noise |
| Treat every session as new | Scan memory before starting |
