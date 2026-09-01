---
name: ralph-loop
description: Start Ralph Loop - auto-continues until task completion
triggers: "ralph, ralph loop, auto-continue, iterative loop, /ralph-loop, continuous task, autonomous loop"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 3000
---

## When to Use
Start Ralph Loop - auto-continues until task completion

# Ralph Loop

Start an iterative development loop that automatically continues until the task is complete.

## Starting the Loop

When you invoke this skill, create the state file in the project directory:

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

Then inform the user and begin working on the task.

## Completion Promise - CRITICAL RULES

When you have FULLY completed the task, signal completion by outputting:

```
<promise>DONE</promise>
```

**IMPORTANT CONSTRAINTS:**

- ONLY output `<promise>DONE</promise>` when the task is COMPLETELY and VERIFIABLY finished
- The statement MUST be completely and unequivocally TRUE
- Do NOT output false promises to escape the loop, even if you think you're stuck
- Do NOT lie even if you think you should exit for other reasons
- If you're blocked, explain the blocker and request help instead of falsely completing

The loop can only be stopped by:
1. Truthful completion promise
2. Max iterations reached
3. User running `/cancel-ralph`

## Lifecycle Hooks (R2-6 — wiggumdev/ralph + dynamic-workflows crash-resume)

| Hook | When | What |
|------|------|------|
| `pre-close` | before `close-session.ps1` | flush batch, validate `mem_save` |
| `post-close` | after close | if `<promise>DONE</promise>` → `inter-track -Reset` (explicit COMPLETE) |
| `check-complete` | on demand | checks `.opencode/ralph-loop.local.md`, last commit, `.ralph/promise` |

Wired: `close-session.ps1` calls `& scripts/ralph-lifecycle.ps1 -Hook post-close` after G7 auto-reset.

## Checking Status

Check current iteration:
```bash
grep '^iteration:' .opencode/ralph-loop.local.md
```

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
cancel-ralph · help · execution-mode · context-watchdog · recovery-protocol
---

docs/skills/ralph-loop/reference.md
---

