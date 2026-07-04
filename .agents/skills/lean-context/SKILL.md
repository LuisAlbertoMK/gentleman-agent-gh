---
name: lean-context
description: "Unified compression levels — LEAN, ULTRA, and CAVEMAN modes for token-efficient responses with acronyms and budget gates"
triggers: "Ultra-lean default, compact responses, caveman, /caveman"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.0"
  changelog: "1.1→2.0: merged caveman as CAVEMAN level"
---

LEAN/ULTRA: default. CAVEMAN: on-demand extreme.Trigger: "modo normal", /lean-off, "stop caveman". Reactivate: new session.
## LEVELS- **LEAN** (default): drop disclaimers/transitions/unsolicited suggestions/closures- **ULTRA**: above + examples/background/"why"/"as mentioned"- **CAVEMAN**: ULTRA + fragments, no articles (a/an/the), acronyms allowed, no filler/hedging
### CAVEMAN sub-levels (on-demand only)| Level | Rules ||-------|-------|| lite | no filler/hedging, sentences || full | drop articles, fragments || ultra | abbr, 1-word enough |
### Acronyms (CAVEMAN only)auth/cfg/ctx/db/env/err/fn/impl/msg/pkg/prop/req/res/spec/usr
### BoundariesCode/PRs → normal level. "stop caveman" → revert to LEAN.
## LENGTH| REQ | LEAN | ULTRA | CAVEMAN ||-----|------|-------|---------|| Simple | 1-line | ≤5 words | 1-3 words || Code | code | code | code || Explain | 3-5sent | 1-2sent | 1 sent || Compare | table | compact | compact || Debug | cause+fix | fix | fix-word |
## FILE OPS- Existing → Edit (str_replace), NO Write- Read → Grep + Read(offset,limit), never full read >100 lines- After edit → NEVER full re-read
## BUDGET GATE| Model | Window | Alert || Opus/Sonnet4 | 200k | >120k || Haiku4 | 200k | >100k |>@threshold: [context:growing — /compress or session-end]Same file 3+ edits → suggest /compress
## TALE (Token-Aware Load Estimation)Estimate ~200 tokens per loaded skill. When skill-graph loads 4-8 skills → budget ~1-1.6K tokens. When loading a full skill for execution → budget ~skill-size + 200. This keeps total skill overhead <10% of context window.
## SELF-CHECK1. first word = answer? 2. 30% cut without loss? 3. level correct?
## NEVER CUTsafety(1-line) · critical caveats(1x) · func code · security warnings · irreversible confirmations
## WHEN TO USE EACH LEVEL
| Situation | Level |
|-----------|-------|
| First response to simple Q | LEAN |
| Mid-session, context >40% | ULTRA |
| Token budget critical (<10 turns left) | CAVEMAN lite |
| Emergency compression (RED zone) | CAVEMAN ultra |
