---
name: deep-debugging
description: "Trigger: deep debug, root cause, hypothesis, multi-file bug, ambiguous failure. Hypothesis-driven debugging methodology."
triggers: "deep debug, root cause, hypothesis, multi-file bug, ambiguous failure, debug, RCA"
---
## When to Use
Multi-file bugs, ambiguous failures. NOT for 1-file edits (→ quick-executor), architecture decisions (→ senior-engineer), or refactors (→ refactoring-planner).

## METHODOLOGY: Hypothesis-Driven Debugging

Output each step name as completed:

1. **OBSERVE**: Quote exact error/symptom. If no error, describe behavioral difference.
2. **HYPOTHESIZE**: 2-3 root causes. Rank by: (1) direct evidence, (2) structural proximity, (3) frequency.
3. **TEST**: One cycle = one hypothesis. **Methods (escalate):** grep/read (static) → add print/logging → run test harness → use debugger/profiler → minimal repro. After 2 grep cycles with no answer → escalate to runtime tools.
4. **DIAGNOSE**: Pick strongest evidence. Cite file:line.
5. **PLAN**: Before/after for each affected file. Check cascading impacts. If fix requires structural changes → note it, continue fix first, refactor after.
6. **EXECUTE**: One logical change per edit.
7. **VERIFY**: Tests first → typecheck/lint → syntax parse → escalate.

Read order: (1) error origin, (2) immediate caller, (3) shared state/config.

## TOOL ESCALATION
| Stage | When | Tools |
|-------|------|-------|
| Static | First 2 cycles | grep, read, git log |
| Dynamic | No answer after 2 cycles | print/logging, test harness |
| Runtime | Still stuck | debugger, profiler, strace/APM |
| Minimal repro | Complex bugs | Isolate to smallest reproducing case |

## CONTEXT CHECKPOINT
After 4+ hypothesis rounds: summarize findings, save progress, compress context before continuing.

## SEVERITY
| P0 | Production down, data loss | P1 | Major functionality broken | P2 | Degraded performance | P3 | Minor issue |

## OUTPUT
```
### Diagnosis
- Severity: P[N]
- Symptom: [quote error]
- Root cause: [file:line — why]
- Evidence: [grep/read/profiler output]
### Fix
- File: path → [before] → [after]
- Verification: [command + expected]
```

## Rules
1. Max 5 hypotheses before narrowing. Max 3 cycles total. 2. Unclear after 3 cycles → STOP, ask human. 3. Never refactor during bug fix. 4. Verify with evidence, not assumptions.

## Refs
senior-engineer · refactoring-planner · code-review-agent

## Anti-Patterns
Skip OBSERVE step · Refactor during fix · >3 cycles without diagnosis · Assume without grep evidence · Skip tool escalation
