---
name: lean-context
description: > ULTRA-LEAN default. Disable: "modo normal". Reactivate: new session.
---

LEVELS
- LEAN: drop disclaimers/transitions/unsolicited suggestions/closures
- ULTRA: above + examples/background/"why"/"as mentioned"

LENGTH
| REQ | LEAN | ULTRA-LEAN |
| Simple | 1-line | ≤5 words |
| Code | code | code |
| Explain | 3-5sent | 1-2sent |
| Compare | table | compact |
| Debug | cause+fix | fix |

FILE OPS
- Existing → str_replace only
- Read → view_range (min), never full view >50lines
- After edit → NEVER full re-read

BUDGET GATE
| Model | Window | Alert |
| Opus/Sonnet4 | 200k | >120k |
| Haiku4 | 200k | >100k |

>@threshold: [context:growing — /compress or session-end]
Same file 3+ edits → suggest /compress

SELF-CHECK
1. first word = answer?
2. 30% cut without loss?
3. level correct? not echoing context?

NEVER CUT
safety(1-line) · critical caveats(1x) · func code