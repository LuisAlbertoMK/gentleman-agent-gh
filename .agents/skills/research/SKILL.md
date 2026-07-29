---
name: research
description: "Structured research workflow for technical investigations — define scope, gather evidence, synthesize findings, document decisions"
triggers: "Research task, technical investigation, investigar, research, learn new tech, compare solutions, evaluate options"
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

## Example: Library Evaluation
Search pattern combining both tools:
```
websearch("zustand vs jotai vs valtio 2026 benchmark" numResults=8)
→ webfetch(URL of top comparison)
→ websearch("zustand migration from redux experience" numResults=5)
→ webfetch(URL of migration guide)
```

| Criteria | Zustand | Jotai | Valtio |
|----------|---------|-------|--------|
| Bundle | 2.5 KB | 4.2 KB | 3.1 KB |
| API style | Single store | Atomic atoms | Proxy-based |
| Learning curve | Low | Medium | Medium |
| React 19 compat | ✅ | ✅ | ⚠️ pending |
| **Pick if** | Simple state | Fine-grained | Mutable style |

## Dead Ends
Document rejected paths to prevent future re-evaluation:
```
**Not pursuing**: {option}
**Why**: {licensing | perf below threshold | unmaintained since Y}
**Evidence**: {link/benchmark}
**Re-evaluate if**: {trigger condition}
```
Save via: `mem_save(title="Research: {topic} — rejected {option}" type="discovery")`

## Post-Research mem_save
```
title: "Research: {topic} — recommendation"
type: "decision"
content: |
  **What**: Selected {winner} over {alternatives}
  **Why**: {top 2 reasons}
  **Where**: {implementation files}
  **Rejected**: {option} because {fatal flaw}
  **Confidence**: {1-5}
```

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