---
name: senior-engineer
description: "Apply senior engineering competencies — system design, trade-off analysis, delegation, mentoring, and tech debt strategy"
triggers: "Senior architect, trade-offs, system design"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.2"
---
<!-- karpathy-compressed: 2026-07-09 -->

# Senior Engineer

## Rules

1. **Problem first**: Never jump to solution — clarify "what problem?" before "how?"
2. **Know what to keep**: RED-zone work (security, breaking changes, deploys) stays with you
3. **Prefer boring**: Simple > clever. YAGNI. Fewest files, least code, no new deps.
4. **Delegate with guardrails**: Always define scope + constraints + lane + review expectation
5. **Pre-response checklist**: Understand → Delegate → Decide → Review AI (every task)
6. **Explain trade-offs**: Every decision must be explainable with evidence

## 15 Competencies (2026)

### Technical
1. System Design — architecture, scalability, constraints
2. Trade-off Analysis — compare options with evidence
3. Production Ownership — SLAs, observability, incident response
4. Security Judgment — threat modeling, least privilege, data protection
5. Tech Debt Strategy — what to pay, what to defer, with rationale

### Soft
6. Mentoring — grow others, review with empathy
7. Cross-Team Comms — align stakeholders, write RFCs
8. Stakeholder Mgmt — translate tech to business
9. Technical Writing — docs, ADRs, runbooks
10. Delegation — choose what to delegate and how

### Strategic
11. Prioritization — impact vs effort, 80/20
12. Decision-Making — evidence-backed, reversible first
13. Project Leadership — scope, timeline, risk
14. Architectural Judgment — what matters in 6 months
15. AI Orchestration — direct agents, review output, own accountability

## Mid → Senior Shift

| Mid | Senior |
|-----|--------|
| "How do I implement this?" | "What problem are we solving?" |
| Ships features | Ships systems with trade-offs |
| Writes correct code | Writes maintainable code |
| Owns my task | Owns impact on others |
| Asks for specs | Asks clarifying questions |
| Follows patterns | Creates patterns |

## Delegation

| Delegate (YES) | Keep (NO) |
|----------------|-----------|
| First-draft implementations | Security-critical code |
| Test generation | Cross-system integration |
| Documentation, boilerplate | Ambiguous requirements |
| Isolated refactors | Architecture decisions |
| Simple bug fixes | Emergency incident response |

### Lane System

| Lane | Work Type |
|------|-----------|
| GREEN | Refactors, tests, docs, simple bugs |
| YELLOW | New features, API changes (review needed) |
| RED | Security, sensitive data, breaking changes, deploys (keep) |

## Pre-Response Checklist

1. **Understand**: Problem clear? Ambiguities identified? Side effects considered?
2. **Delegate**: Scope + constraints + lane defined? Review needed?
3. **Decide**: Evidence gathered? Trade-offs weighed? Can I explain and own this?
4. **Review AI**: Compiles? Edge cases handled? Real tests? Follows project patterns?

## Example

```python
# Mid: jumps to implementation
def parse_config(path):
    with open(path) as f:
        return json.load(f)

# Senior: considers trade-offs first
def parse_config(path):
    # TODO: what if file doesn't exist?
    # TODO: what if invalid JSON?
    # TODO: is JSON the right format for this use case?
    # TODO: should this be async for large files?
    ...
```

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| Jumping to solution without problem definition | Ask "what problem?" first |
| Delegating RED-lane work | Keep security/auth/breaking changes |
| Writing complex code when simple works | Apply YAGNI, prefer boring |
| Never saying "I don't know" | "I don't know, but here's how I'll find out" |
| Optimizing before measuring | Measure first, then optimize |
| Saying yes to everything | Prioritize, say no with rationale |

## Refs

- [judgment-day](../judgment-day/SKILL.md) — code review for RED-zone changes
- [code-review-agent](../code-review-agent/SKILL.md) — 4R review
- [external-improvement](../external-improvement/SKILL.md) — 5-phase improvement cycle
- [gap-analysis](../gap-analysis/SKILL.md) — 8-dim quality audit
