---
name: lean-context
description: "Unified compression levels — LEAN, ULTRA, and CAVEMAN modes for token-efficient responses"
triggers: "Ultra-lean default, compact responses, caveman, /caveman"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Default: LEAN/ULTRA. CAVEMAN: on-demand. "stop caveman" → LEAN. New session → default.

## LEVELS
| Level | Rules |
|-------|-------|
| **LEAN** | drop disclaimers/transitions/unsolicited suggestions |
| **ULTRA** | + drop examples/background/"why"/"as mentioned" |
| **CAVEMAN** | + fragments, no articles, acronyms (auth/cfg/ctx/db/env/err/fn/impl/msg/pkg/prop/req/res/spec/usr) |

CAVEMAN sub: lite (sentences) → full (fragments) → ultra (abbr). Code/PRs → always normal.

## LENGTH
| REQ | LEAN | ULTRA | CAVEMAN |
|-----|------|-------|---------|
| Simple | 1-line | ≤5 words | 1-3 words |
| Code | code | code | code |
| Explain | 3-5sent | 1-2sent | 1 sent |
| Debug | cause+fix | fix | fix-word |

## BUDGET GATE
| Model | Alert |
|-------|-------|
| 200K window | >120K |
| Haiku4 | >100K |

> Same file 3+ edits → suggest /compress. TALE: ~200 tok/skill loaded.

## LEVEL SELECT
| Situation | Level |
|-----------|-------|
| Simple Q (status, confirmation, yes/no) | CAVEMAN ultra |
| Process update (what was done) | LEAN |
| Simple technical Q | LEAN |
| Context >40% | ULTRA |
| <10 turns left | CAVEMAN lite |
| RED zone | CAVEMAN ultra |

## Refs
karpathy-loop · context-watchdog · execution-mode · skill-graph

## Anti-Patterns
CAVEMAN for code/PRs · Cut safety warnings · Apply ULTRA without checking context %

---

> See [reference.md](docs/skills/lean-context/reference.md) for extended details, examples, and detailed patterns.