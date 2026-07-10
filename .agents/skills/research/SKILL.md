---
name: research
description: "Structured research workflow for technical investigations — define scope, gather evidence, synthesize findings, document decisions"
triggers: "Research task, technical investigation, investigar, research, learn new tech, compare solutions, evaluate options"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.0"
---

Structured research: scope, gather, synthesize, decide.

## When
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

## Depth Levels
| Level | Sources | Time |
|-------|---------|------|
| Quick Scan | 2-3 | 5-10 min |
| Moderate | 5-8 | 20-40 min |
| Deep | 10+ + PoC | 1-4 hrs |

## Anti-Patterns
Confirmation bias | Doc-only (no real-world check) | No deadline | Single source | Old info

## Commands
```
websearch("TOPIC 2026 comparison OR benchmark" numResults=8)
webfetch(URL)
websearch("TOPIC vs ALTERNATIVE pros cons 2026" numResults=10)
mem_save(title="Research: TOPIC" type="discovery")
```

## Refs
cross-project-wisdom · prompt-engineering · senior-engineer · execution-mode · skill-graph