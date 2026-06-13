---
name: lean-context
description: >
  lean-context skill — unified compression (LEAN→ULTRA→CAVEMAN)
triggers: "Ultra-lean default, compact responses, caveman, /caveman"
  LEAN/ULTRA: default. CAVEMAN: on-demand extreme.
  Trigger: "modo normal", /lean-off, "stop caveman". Reactivate: new session.
license: Apache-2.0
metadata: author: gentleman-vMK, version: "2.0", changelog: "1.1→2.0: merged caveman as CAVEMAN level, added acronyms"
---

## LEVELS
- **LEAN** (default): drop disclaimers/transitions/unsolicited suggestions/closures
- **ULTRA**: above + examples/background/"why"/"as mentioned"
- **CAVEMAN**: ULTRA + fragments, no articles (a/an/the), acronyms allowed, no filler/hedging

### CAVEMAN sub-levels (on-demand only)
| Level | Rules |
|-------|-------|
| lite | no filler/hedging, sentences |
| full | drop articles, fragments |
| ultra | abbr, 1-word enough |

### Acronyms (CAVEMAN only)
auth/cfg/ctx/db/env/err/fn/impl/msg/pkg/prop/req/res/spec/usr

### Boundaries
Code/PRs → normal level. "stop caveman" → revert to LEAN.

## LENGTH
| REQ | LEAN | ULTRA | CAVEMAN |
|-----|------|-------|---------|
| Simple | 1-line | ≤5 words | 1-3 words |
| Code | code | code | code |
| Explain | 3-5sent | 1-2sent | 1 sent |
| Compare | table | compact | compact |
| Debug | cause+fix | fix | fix-word |

## FILE OPS
- Existing → Edit (str_replace), NO Write
- Read → Grep + Read(offset,limit), never full read >100 lines
- After edit → NEVER full re-read

## BUDGET GATE
| Model | Window | Alert |
| Opus/Sonnet4 | 200k | >120k |
| Haiku4 | 200k | >100k |

>@threshold: [context:growing — /compress or session-end]
Same file 3+ edits → suggest /compress

## SELF-CHECK
1. first word = answer? 2. 30% cut without loss? 3. level correct?

## NEVER CUT
safety(1-line) · critical caveats(1x) · func code · security warnings · irreversible confirmations
