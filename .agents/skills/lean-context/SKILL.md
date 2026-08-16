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

## FILE OPS
Edit (str_replace) for existing. Grep+Read(offset,limit) for reading. Never full re-read after edit.

## BUDGET GATE
| Model | Alert |
|-------|-------|
| 200K window | >120K |
| Haiku4 | >100K |

> Same file 3+ edits → suggest /compress. TALE: ~200 tok/skill loaded.

## SELF-CHECK
1. first word = answer? 2. 30% cut without loss? 3. level correct?

**NEVER CUT**: safety(1-line) · critical caveats(1x) · func code · security warnings · irreversible confirmations
- Safety: "This command will DELETE ALL DATA in production — are you sure?"
- Caveat: "Works on Node ≥18; fails silently on 16"
- Confirmation: "Proceed? (y/N)" — always show before destructive ops

## LEVEL SELECT
| Situation | Level |
|-----------|-------|
| Simple Q (status, confirmation, yes/no) | CAVEMAN ultra |
| Process update (what was done) | LEAN |
| Simple technical Q | LEAN |
| Context >40% | ULTRA |
| <10 turns left | CAVEMAN lite |
| RED zone | CAVEMAN ultra |

## ESCALATION
Context crosses 40% mid-conversation? Move LEAN→ULTRA immediately. Crosses 80%? → CAVEMAN lite. Under 10 turns remaining? → CAVEMAN full. **Never escalate mid-code-block** — finish the thought first, then switch on next turn.

## USER RESPONSE POLICY
**Default for USER-facing responses**: CAVEMAN for yes/no/status, LEAN for process updates. **Protocol outputs** (analysis tables, verification results, recommendations): remain detailed per protocol. **Trigger words for user-facing LEAN**: "listo?", "funcionó?", "status?", "ok?", "gracias", "gg".

## Refs
karpathy-loop · context-watchdog · execution-mode · skill-graph

## Anti-Patterns
CAVEMAN for code/PRs · Cut safety warnings · Apply ULTRA without checking context %