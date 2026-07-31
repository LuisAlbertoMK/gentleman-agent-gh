---
name: lean-context
description: "Unified compression levels — LEAN, ULTRA, and CAVEMAN modes for token-efficient responses"
triggers: "Ultra-lean default, compact responses, caveman, /caveman"
---

## When to Use
Unified compression levels — LEAN, ULTRA, and CAVEMAN modes


LEAN/ULTRA: default. CAVEMAN: on-demand. Trigger: "stop caveman" → LEAN. New session → default.

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

## LIVE EXAMPLE
| Request | LEAN | ULTRA | CAVEMAN |
|---------|------|-------|---------|
| "Explain JWT" | "Server signs payload → client sends in Authorization header → verify with secret" | "Sign→header→verify" | "srv sign→auth hdr→vrfy" |
| "Fix auth.go bug" | "Line 42: missing `return` after failed validation" | "L42: missing return" | "L42: no ret" |
| "What's context %?" | "112k/200k (56%) — YELLOW zone" | "112k/200k 56% YLW" | "112k 56% YLW" |

## ESCALATION
Context crosses 40% mid-conversation? Move LEAN→ULTRA immediately.
Crosses 80%? → CAVEMAN lite. Under 10 turns remaining? → CAVEMAN full.
**Never escalate mid-code-block** — finish the thought first, then switch on next turn.

## NEVER CUT EXAMPLES
- Safety: "This command will DELETE ALL DATA in production — are you sure?"
- Caveat: "Works on Node ≥18; fails silently on 16"
- Confirmation: "Proceed? (y/N)" — always show before destructive ops

## WHEN

| Situation | Level |
|-----------|-------|
| Simple Q | LEAN |
| Context >40% | ULTRA |
| <10 turns left | CAVEMAN lite |
| RED zone | CAVEMAN ultra |

## Refs
karpathy-loop · context-watchdog · execution-mode · skill-graph

## Anti-Patterns
CAVEMAN for code/PRs · Cut safety warnings · Apply ULTRA without checking context %
