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

# Skill Graph — Sparse Loading Resolver

Instead of loading all skills, resolve only the relevant ones + dependencies, then load per context budget.

---

## PHASE 1: RESOLVE — Which skills?

```powershell
.\scripts\skill-graph.ps1 -Task "<task description>"
                              [-Expand N]     # dep depth (default 1, max 3)
                              [-Format Json|Csv]
```

### Resolution strategy

1. **Match** — task keywords matched against skill triggers (fuzzy, min 3 chars)
2. **Expand** — BFS 1-hop through dependency + related edges
3. **Output** — matched skills + dependencies

### Examples
```
Input:  -Task "security audit"
Output: security-scanner + best-practices (depends_on)

Input:  -Task "implement feature from spec"
Output: sdd-tasks + sdd-design + sdd-spec
```

---

## PHASE 2: DIGEST — How much to load?

After resolving WHICH skills, decide HOW MUCH to load based on context:

| Context | Load strategy | Token target |
|---------|--------------|--------------|
| <60% | Full skill | No limit |
| 60-80% (YELLOW) | Rules + decision tree only | ~300 tokens |
| >80% (RED) | 1-line summary + critical rules | ~100 tokens |
| <40% (first load) | Full skill (no usage data yet) | No limit |

**Always check context % before loading.** If YELLOW/RED, truncate output.

---

## PHASE 3: RESOLUTION FEEDBACK (post-task)

Log to Engram after task if skill was loaded:

```yaml
title: "Skill resolution: {name}"
type: learning
content: |
  Skill: {name}
  Trigger: {trigger}
  Applied: Y/N
  Effective: Y/P/N
  Notes: ...
```

---

## AUTO-IMPROVEMENT TRIGGERS

| Signal | Action |
|--------|--------|
| Loaded but NOT applied | Trigger too broad? Narrow it |
| Applied but NOT effective | Update skill patterns |
| Improvised missing guidance | Create new skill |
| Same skill loaded 3+ times | Flag heavy — digest more |

---

## When to use
- **Task start**: resolve before requesting any `skill` tool call
- **Unfamiliar task**: let the graph find related skills you might miss
- **Token budget tight**: skip loading skills that don't match

## When NOT to use
- Single-step Q&A (cheaper to use skill directly)
- When you already know exactly which skill you need

## Cross-References
- **SKILLS-INDEX.md**: full trigger table (fallback)
- **session-resume**: uses skill-graph for context-aware resume
- **execution-mode**: QUICK mode prefers graph resolution
