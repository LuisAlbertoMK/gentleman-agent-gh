---
name: prompt-engineering
description: "Design effective prompts using SPEARS framework — scope, principles, examples, assertions, refinements, with ReAct and multi-agent patterns"
triggers: "Improve prompt, security, ReAct, multi-agent"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

Trigger: "improve prompt", "ReAct", "security", "multi-agent".
## SPEARS: Scope â€” "for [ctx], in:[types], out:[format]"P: Principles â€” max 4 non-negotiable (security/quality/performance)E: Examples â€” 1 valid + 1 edge + 1 contraA: Assertions â€” ASSERT constraints | NEVER prohibitedR: Refinements â€” post-impl iterations
## PATTERNS
### ReActThought:[reason]â†’Action:[tool]â†’Observation:[result]...repeatâ†’Final Answer
### ReflexionTask:[task]â†’Attempt:[attempt]â†’Reflection:[crit]â†’Revision:[improved]...repeat
### Multi-AgentRouterâ†’Plannerâ†’Executorâ†’CriticAgent: role, scope, tools, limitsComm: requestâ†’response, errorsâ†’reportingOrchestrator: routingâ†’fallbackâ†’timeout
## SECURITYINPUT: types/ranges/sanitizationOUTPUT: no-autoexec/rate limits/timeoutsDATA: no-creds/no-PII/no-tokensAGENT: least-privilege/tools schema/sandbox/human-in-loop
