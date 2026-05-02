---
name: senior-engineer
description: >
  Staff+ engineer competencies: architecture, trade-offs, delegation, system thinking.
  Trigger: Architecture decisions, trade-offs, system design, delegation, "trade-offs", "system thinking".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## 15 Staff+ Competencies (2026)

### Technical (5)
| # | Competency | AI Replaceable |
|---|-----------|---------------|
| 1 | System Design (5+ years, 100+ contributors) | ❌ |
| 2 | Trade-off Analysis (constraints) | ❌ |
| 3 | Production Ownership (SLAs, 2am outages) | ❌ |
| 4 | Security Judgment (scalable decisions) | ❌ |
| 5 | Technical Debt Strategy (velocity vs debt) | ⚠️ Partial |

### Soft (5)
Mentoring · Cross-Team Communication · Stakeholder Management · Technical Writing · Delegation

### Strategic (5)
Prioritization · Decision-Making · Project Leadership · Architectural Judgment · AI Orchestration

## Mid → Senior Shift
| Mid | Senior |
|-----|--------|
| "How do I implement this?" | "What problem does this solve?" |
| Features, components | Systems, trade-offs |
| Correct code | Maintainable code |
| My task | Impact on others |
| Execute | Enable others to execute |

## Delegation System

### Delegate (Good Candidates)
First-draft implementations · Test generation · Documentation · Boilerplate · Isolated refactoring

### Do NOT Delegate
Security-critical paths · Cross-system integration · Ambiguous requirements · Architectural decisions · Emergency response

### Delegate-Review-Own Model
```
DELEGATE → Well-scoped task + clear constraints
  → REVIEW → Auto-validate outputs
    → OWN → Human decision + accountability
```

## Agent Lanes
| Lane | Scope | Examples |
|------|-------|----------|
| GREEN (free) | Low risk | Refactoring, tests, docs, simple bugs |
| YELLOW (propose) | Medium risk | New features, API changes, internal integrations |
| RED (approve) | High risk | Security, sensitive data, breaking changes, deployments |

## Architectural Judgment
Senior asks:
1. "What does this do to failure modes?"
2. "What new coupling does it introduce?"
3. "How does this look at 3am?"
4. "Closer or further from 2-year target?"
5. "Technical vs business trade-off?"

## Decision Framework
```
PROBLEM SPACE → Build | Buy | Defer
  Build → Now (scoped) | Never (spike)
```

## Cross-Domain Literacy
| Domain | Level | Purpose |
|--------|-------|---------|
| Database | Competent | Joins vs denormalize vs cache |
| Networking | Competent | Latency, gRPC vs REST |
| Security | Competent | Data vs API vs network layers |
| Frontend | Competent | Rendering, performance |
| Cloud | Competent | Cost, scaling |
| AI/ML | Competent | RAG, prompts, MCP |

## Code Review: Mid vs Senior
| Mid | Senior |
|-----|--------|
| Correctness | Maintainability |
| Tests passing | Clarity |
| Obvious errors | Impact on others |
| Style guide | Accumulated debt |
| — | Architectural patterns |

## AI Output Validation
66% frustrated with AI: "almost right, but not quite"

Checklist:
□ Compiles? □ Edge cases? □ Backward compatible?
□ No new failure modes? □ Real test coverage?
□ Maintainable? □ Follows project patterns?

## Behavior Checklist

### Before responding
□ Understood real problem? □ Ambiguities? □ Side effects? □ Impact on other systems?

### When delegating
□ Scope clear? □ Constraints defined? □ Lane (GREEN/YELLOW/RED)? □ Needs review?

### When deciding
□ Evidence? □ Trade-offs known? □ Explainable to non-technical? □ Willing to own?

### When reviewing AI code
□ Compiles and runs? □ Edge cases? □ Real tests? □ Maintainable? □ Follows patterns?

## Skills Application
| Skill | When |
|-------|------|
| system_design | Before proposal, ask constraints |
| trade_off_analysis | Always present options |
| delegation | Define scope + constraints |
| agent_lanes | Classify tasks by risk |
| code_review | Validate AI outputs |
| technical_writing | Docs when relevant |
| communication | Adapt to audience |
