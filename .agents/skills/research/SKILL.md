---
name: research
description: "Structured research workflow - define scope, gather evidence, synthesize findings, document decisions."
triggers: "Research task, technical investigation, investigar, research, learn new tech, compare solutions, evaluate options"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1347
---

Structured research: scope, gather, synthesize, decide.

## When to Use
Tech evaluation | Library comparison | Architecture research | Security audit | Performance investigation | New domain | Pre-PoC

## Workflow

### 1. Scope (1-2 min)
Goal (1 sentence), Constraints (time/budget/stack/expertise), Output (table|rec|PoC plan|summary), Deadline

### 2. Gather (>=3 sources)
Official docs | Community (GitHub/SO/blogs - recent) | Benchmarks (perf/bundle/API) | Migration cost

### 3. Synthesize
Option table (Pros/Cons 2 max each, Cost) + Recommendation with confidence 1-5

### 4. Decide
Clear winner -> mem_save decision | Unclear -> define next evidence | Dead end -> document why + what NOT to pursue
---

## Reference Materials

The following material is externalized to keep this skill under the 3KB token budget (ADR-007).
Consult these when the skill needs detailed worked examples or guardrails:

- **Worked Examples, Testing Patterns, Edge Cases, Anti-Patterns, Quick Reference**
  → docs/skills/research/reference.md

---
## Refs
Cross-Refs: gap-analysis | project-mapper
