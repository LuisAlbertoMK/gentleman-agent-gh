---
name: ralph-loop
description: "Start Ralph Loop - auto-continues until task completion"
triggers: "ralph, ralph loop, auto-continue, iterative loop, /ralph-loop, continuous task, autonomous loop"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2200
---
## Starting the Loop
Create state file:
```bash
mkdir -p .opencode && cat > .opencode/ralph-loop.local.md << 'EOF'
---
active: true
iteration: 0
maxIterations: 100
---
[The user's task prompt goes here]
EOF
```
Then inform user and begin.

## Completion — CRITICAL
Output `<promise>DONE</promise>` ONLY when task is COMPLETELY and VERIFIABLY finished. Must be unequivocally TRUE. Blocked→explain blocker, don't lie.
Loop stops: 1. Truthful completion 2. Max iterations 3. `/cancel-ralph`

## Lifecycle Hooks (R2-6)
| Hook | When | What |
|------|------|------|
| `pre-close` | before close-session.ps1 | flush batch, validate mem_save |
| `post-close` | after close | if DONE→`inter-track -Reset` |
| `check-complete` | on demand | checks ralph-loop.local.md, last commit, .ralph/promise |

Wired: `close-session.ps1` calls `& scripts/ralph-lifecycle.ps1 -Hook post-close` after G7.

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "maxIterations infinitos" | >100 sin justificación | Default 100; validate file:line |
| "COMPLETE sin evidencia" | Promise w/o task completeness | Verify completeness + check-complete hook |
| "saltar hooks" | pre/post-close omitted | Run ralph-lifecycle.ps1 before close |

## Verification
- Output matches contract; cross-ref-check.ps1 → OK

→ docs/skills/ralph-loop/reference.md · Refs: cancel-ralph · help · execution-mode · context-watchdog · recovery-protocol

