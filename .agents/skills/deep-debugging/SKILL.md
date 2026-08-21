---
name: deep-debugging
description: "Trigger: deep debug, root cause, hypothesis, multi-file bug, ambiguous failure. Hypothesis-driven debugging."
triggers: "deep debug, root cause, hypothesis, multi-file bug, ambiguous failure, debug, RCA"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1941
---
## When to Use
Multi-file bugs, ambiguous failures. NOT for 1-file edits (→ quick-executor), architecture decisions (→ sdd), or refactors (→ refactoring-planner).
## METHODOLOGY: Hypothesis-Driven Debugging
Output each step name as completed:
1. **OBSERVE**: Quote exact error/symptom. If no error, describe behavioral difference.
2. **HYPOTHESIZE**: 2-3 root causes. Rank by: (1) direct evidence, (2) structural proximity, (3) frequency.
3. **TEST**: One cycle = one hypothesis. **Methods (escalate):** grep/read (static) → add print/logging → run test harness → use debugger/profiler → minimal repro. After 2 grep cycles with no answer → escalate to runtime tools.
4. **DIAGNOSE**: Pick strongest evidence. Cite file:line.
5. **PLAN**: Before/after for each affected file. Check cascading impacts. If fix requires structural changes → note it, continue fix first, refactor after.
6. **EXECUTE**: One logical change per edit.
7. **VERIFY**: Tests first → typecheck/lint → syntax parse → escalate.
Read order + OUTPUT template → reference.
## Rules
1. Max 5 hypotheses before narrowing. Max 3 cycles total.
2. Unclear after 3 cycles → STOP, ask human.
3. Never refactor during bug fix.
4. Verify with evidence, not assumptions.
## Refs
refactoring-planner · code-review-agent
## Anti-Patterns
Skip OBSERVE step · Refactor during fix · >3 cycles without diagnosis · Assume without grep evidence · Skip tool escalation
Chase symptoms not root cause · Add logging without hypothesis · Rewrite instead of bisect · Ignore shared state
## Reference
Read order + OUTPUT template → docs/skills/deep-debugging/reference.md