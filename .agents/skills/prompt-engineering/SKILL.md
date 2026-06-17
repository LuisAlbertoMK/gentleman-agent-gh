---
name: prompt-engineering
description: "Design effective prompts using SPEARS framework — scope, principles, examples, assertions, refinements, with ReAct and multi-agent patterns"
triggers: "Improve prompt, security, ReAct, multi-agent"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.1"
---

Trigger: "improve prompt", "ReAct", "security", "multi-agent".
## SPEARS: Scope — "for [ctx], in:[types], out:[format]"P: Principles — max 4 non-negotiable (security/quality/performance)E: Examples — 1 valid + 1 edge + 1 contraA: Assertions — ASSERT constraints | NEVER prohibitedR: Refinements — post-impl iterations
## PATTERNS
### ReActThought:[reason]→Action:[tool]→Observation:[result]...repeat→Final Answer
### ReflexionTask:[task]→Attempt:[attempt]→Reflection:[crit]→Revision:[improved]...repeat
### Multi-AgentRouter→Planner→Executor→CriticAgent: role, scope, tools, limitsComm: request→response, errors→reportingOrchestrator: routing→fallback→timeout
## SECURITYINPUT: types/ranges/sanitizationOUTPUT: no-autoexec/rate limits/timeoutsDATA: no-creds/no-PII/no-tokensAGENT: least-privilege/tools schema/sandbox/human-in-loop
