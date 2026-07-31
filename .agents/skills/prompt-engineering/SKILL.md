---
name: prompt-engineering
description: "Design effective prompts using SPEARS framework — scope, principles, examples, assertions, refinements, with ReAct and multi-agent patterns"
triggers: "Improve prompt, security, ReAct, multi-agent"
---

## When to Use
Design effective prompts using SPEARS framework — scope, principles, examples, assertions, refinements, with ReAct and multi-agent patterns

<!-- karpathy-compressed: 2026-07-09 -->
## Rules
1. **Scope first**: `for [X], in:[Y], out:[Z]` before writing
2. **Cap principles at 4**: More dilutes LLM attention
3. **3-example rule**: 1 valid + 1 edge + 1 counterexample
4. **Security mandatory**: Cover INPUT/OUTPUT/DATA/AGENT
5. **Refine don't rewrite**: Iterative, not one-shot
6. **Separation of roles**: Multi-agent needs distinct prompts per role

## SPEARS Framework
| Letter | Stands For | Rule |
|---|---|---|
| **S** | Scope | `for [context], in:[input_types], out:[format]` |
| **P** | Principles | Max 4 non-negotiable rules |
| **E** | Examples | 1 valid + 1 edge + 1 counterexample |
| **A** | Assertions | `ASSERT` constraints + `NEVER` things to avoid |
| **R** | Refinements | Post-implementation iteration loop |

## Patterns
### ReAct: Thought→Action→Observation→Final Answer
### Reflexion: Task→Attempt→Reflection→Revision
### Multi-Agent: Router → Planner → Executor → Critic. Each agent: role, scope, tools, limits. Orchestrator: routing → fallback → timeout.
## Security Rules
| Domain | Rules |
|---|---|
| INPUT | Types, ranges, sanitization |
| OUTPUT | No auto-exec, rate limits, timeout |
| DATA | No credentials, no PII, no tokens |
| AGENT | Least-privilege, tool validation, sandbox, human-in-loop |

## Example
```markdown
S: For a Node.js API, in:[HTTP request], out:[JSON response]
P: 1) Validate all inputs 2) Never expose stack traces 3) Log all errors
E: ✓ POST /users returns 201 + user
    ⚠ PUT /users/:id with missing body → 400
    ✗ DELETE /users returns stack trace → 500
A: ASSERT body.id matches :id | NEVER use eval()
R: Iterate on error message clarity
```

## Anti-Patterns
| Anti-Pattern | Why | Do Instead |
|---|---|---|
| Vague scope | LLM guesses wrong context | `for [X], in:[Y], out:[Z]` |
| Too many principles (7+) | Dilution, LLM ignores them | Cap at 4 |
| No counterexamples | Only learns what TO do | Add 1 counterexample |
| No security rules | Injection/PII risk | Always cover INPUT/OUTPUT/DATA/AGENT |
| No refinement | First attempt rarely best | Plan iteration |
| Mixed agent roles | Confusion, role bleed | Separate into distinct prompts |

## Refs
- [karpathy-loop](../karpathy-loop/SKILL.md) — iterative prompt optimization
- [code-review-agent](../code-review-agent/SKILL.md) — 4R review engine
- [senior-engineer](../senior-engineer/SKILL.md) — trade-off analysis
