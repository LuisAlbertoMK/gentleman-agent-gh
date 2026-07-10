---
name: skill-graph
description: "Sparse loading — resolve only relevant skills + dependencies AND digest them per context budget. Unified skill resolution + loading strategy."
triggers: "sparse loading, skill resolution, relevant skills, skill dependencies, which skill, skill-graph, resolver skill, minimo skills, solo skills needed, skill digestion, compact on load"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.0"
  changelog: "2.0: merged skill-digestion (context-aware loading strategy + resolution feedback)"
---
## PHASE 1: RESOLVE
```powershell
.\scripts\skill-graph.ps1 -Task "<task>" [-Expand N] [-Format Json|Csv]
```
1. **Match** — task keywords vs skill triggers (fuzzy, min 3 chars)
2. **Expand** — BFS 1-hop through dependency + related edges
3. **Output** — matched skills + dependencies

Ex: `-Task "security audit"` → security-scanner + best-practices. `-Task "implement feature"` → sdd-tasks + sdd-design + sdd-spec.

## PHASE 2: DIGEST
| Context | Load strategy | Target |
|---------|--------------|--------|
| <60% | Full skill | No limit |
| 60-80% (YELLOW) | Rules + decision tree | ~300 tok |
| >80% (RED) | 1-line + critical rules | ~100 tok |
| <40% (first load) | Full skill | No limit |
Always check context % before loading. If YELLOW/RED, truncate output.

## PHASE 3: RESOLUTION FEEDBACK
Log to Engram post-task:
```yaml
title: "Skill resolution: {name}"
type: learning
content: |
  Skill: {name} | Trigger: {trigger} | Applied: Y/N | Effective: Y/P/N | Notes: ...
```

## AUTO-IMPROVEMENT
| Signal | Action |
|--------|--------|
| Loaded but NOT applied | Trigger too broad? Narrow |
| Applied but NOT effective | Update skill patterns |
| Improvised missing guidance | Create new skill |
| Same skill loaded 3+ times | Flag heavy — digest more |

## When to use
- **Task start**: resolve before any `skill` tool call
- **Unfamiliar task**: find related skills you might miss
- **Token tight**: skip non-matching skills

## When NOT to use
- Single-step Q&A (cheaper to use skill directly)
- Already know exact skill needed

## Cross-Ref
- SKILLS-INDEX.md: full trigger table
- session-resume: uses skill-graph for context-aware resume
- execution-mode: QUICK mode prefers graph resolution

## Refs
session-resume · execution-mode · skill-registry · skill-testing · lean-context

## Anti-Patterns
Resolve every task · Skip resolution for known skills · Load full skills in RED zone · Ignore resolution feedback · Never update stale triggers
