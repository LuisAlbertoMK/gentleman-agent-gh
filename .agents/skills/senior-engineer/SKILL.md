---
name: senior-engineer
description: "Apply senior engineering competencies — system design, trade-off analysis, delegation, mentoring, and tech debt strategy"
triggers: "Senior architect, trade-offs, system design"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "1.3"
  changelog: "1.3: initial tracked version"
---
<!-- karpathy-compressed: 2026-07-10 -->

# Senior Engineer

## Rules

1. **Problem first**: "What problem?" before "how?"
2. **Keep RED-zone**: security, breaking, deploys
3. **Prefer boring**: Simple > clever. YAGNI. Fewest files.
4. **Delegate**: Scope + constraints + lane + review
5. **Checklist**: Understand → Delegate → Decide → Review AI
6. **Trade-offs**: Explain every decision with evidence

## 15 Competencies

**Technical**: System Design · Trade-off Analysis · Production Ownership · Security Judgment · Tech Debt Strategy
**Soft**: Mentoring · Cross-Team Comms · Stakeholder Mgmt · Technical Writing · Delegation
**Strategic**: Prioritization · Decision-Making · Project Leadership · Architectural Judgment · AI Orchestration

## Mid → Senior

| Mid | Senior |
|---|---|
| "How do I implement?" | "What problem are we solving?" |
| Ships features | Ships systems with trade-offs |
| Correct code | Maintainable code |
| Owns task | Owns impact on others |
| Asks for specs | Asks clarifying questions |
| Follows patterns | Creates patterns |

## Delegation

| Delegate | Keep |
|---|---|
| First-draft implementations | Security-critical code |
| Test generation | Cross-system integration |
| Docs, boilerplate | Ambiguous requirements |
| Isolated refactors | Architecture decisions |
| Simple bug fixes | Emergency incident response |

**Lanes**: GREEN (refactors/tests/docs) · YELLOW (features/API, review) · RED (security/breaking/deploys)

## Pre-Response

1. **Understand**: Problem? Ambiguities? Side effects?
2. **Delegate**: Scope + constraints + lane?
3. **Decide**: Evidence? Trade-offs? Own it?
4. **Review AI**: Compiles? Edge cases? Tests?

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| Jump to solution | "What problem?" first |
| Delegate RED-lane | Keep security/auth/breaking |
| Complex when simple works | YAGNI, prefer boring |
| Never "I don't know" | "I'll find out" |
| Optimize before measuring | Measure first |
| Say yes to everything | Prioritize, say no |

## Refs

- [judgment-day](../judgment-day/SKILL.md) · [code-review-agent](../code-review-agent/SKILL.md) · [external-improvement](../external-improvement/SKILL.md) · [gap-analysis](../gap-analysis/SKILL.md)
