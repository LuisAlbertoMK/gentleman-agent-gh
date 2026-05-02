---
name: prompt-engineering
description: >
  Professional prompt engineering via SPEAR framework + advanced patterns.
  Trigger: Improve prompt, create robust prompt, cover gaps/security/scalability.
  Also: "ReAct", "Reflexion", "DSPy", "multi-agent", "agentic workflow".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When
Improve existing prompt · Complex software dev prompts · Need security/scalability/edge cases · Agentic tasks

## SPEAR Framework
**S — Scope:** "This prompt is for [context]. Input: [types]. Output: [format]."
**P — Principles:** Max 4 non-negotiable rules (security, quality, performance, maintainability)
**E — Examples:** 1 valid + 1 edge case + 1 counterexample
**A — Assertions:** `ASSERT: [verifiable constraint]` · `NEVER: [prohibited]`
**R — Refinements:** Post-implementation iterations

## Advanced Patterns

### ReAct
```
Thought: [reasoning about what to do]
Action: [tool to use]
Observation: [result]
...repeat until resolved...
Final Answer: [conclusion]
```

### Reflexion
```
Task: [task]
Attempt: [response]
Reflection: [critical evaluation]
Revision: [improved]
...repeat if needed...
```

### Multi-Agent Orchestration
```
Router → Planner → Executor → Critic

## Agent: [Name]
Role: [specialization] | Scope: [handles] | Tools: [available] | Limits: [constraints]

## Communication
Request: [format] | Response: [format] | Errors: [report how]

## Orchestrator
Routing: [how to decide] | Fallback: [if fails] | Timeout: [per step limit]
```

## Security Checklist
**INPUT:** Types specified · Valid ranges · Max lengths · Formats validated · Sanitization for injection
**OUTPUT:** No auto-execution · Output sanitization · Rate limiting · Response timeouts
**DATA:** No hardcoded creds · No PII in logs · No tokens in output
**AGENT:** Least privilege tools · Tool schema validation · Human-in-loop for sensitive · Sandbox generated code · Audit log without secrets

## Tool Definition Template
```
## [tool_name]
Description: [what, when to use]
Input: [schema type]
Output: [return type]
Constraints: [limit 1, limit 2]
Errors: [code]: [action]
```

## Lifecycle Coverage
Requirements: input/output types, constraints
Design: output format, errors defined, logging specs
Implementation: edge cases explicit, error behavior, logging
Testing: test cases, output validation, failure criteria
Production: rate limits, timeouts, retry policies, metrics

## Professional Template
```markdown
# ROL: [role] specialized in [domain]
# CONTEXTO: System: [name] | Stack: [tech] | Location: [where]
# PATTERN: [ReAct / Reflexion / Standard / Multi-Agent]
# TAREA: [clear description]
# INPUT: Type: [data] | Constraints: [limits]
# OUTPUT: [format + example]
# PRINCIPLES (max 4): 1. [security] 2. [quality] 3. [performance]
# TOOLS (if agentic): [tool definitions]
# EDGE CASES: | Case | Handling |
# ERRORS: | Error | Action |
# ASSERT: [verifiable constraint] | NEVER: [prohibited]
```
