---
name: prompt-engineering
description: > SPEAR framework, ReAct/Reflexion multi-agent patterns.
  Trigger: "improve prompt", "ReAct", "security", "multi-agent".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.1"
---

## SPEAR
S: Scope — "for [ctx], in:[types], out:[format]"
P: Principles — max 4 non-negotiable (security/quality/performance)
E: Examples — 1 valid + 1 edge + 1 contra
A: Assertions — ASSERT constraints | NEVER prohibited
R: Refinements — post-impl iterations

## PATTERNS
### ReAct
Thought:[reason]→Action:[tool]→Observation:[result]...repeat→Final Answer

### Reflexion
Task:[task]→Attempt:[attempt]→Reflection:[crit]→Revision:[improved]...repeat

### Multi-Agent
Router→Planner→Executor→Critic
Agent: role, scope, tools, limits
Comm: request→response, errors→reporting
Orchestrator: routing→fallback→timeout

## SECURITY
INPUT: types/ranges/sanitization
OUTPUT: no-autoexec/rate limits/timeouts
DATA: no-creds/no-PII/no-tokens
AGENT: least-privilege/tools schema/sandbox/human-in-loop