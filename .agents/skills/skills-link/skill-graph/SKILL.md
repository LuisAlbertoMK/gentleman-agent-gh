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
.\scripts\skill-graph.ps1 -Task "<task>" [-Expand N] [-Format Json|Csv] [-PatternsFile <path>]
```
1. **Match** — task keywords vs skill triggers (fuzzy, min 3 chars)
2. **Boost** — apply external patterns from dreaming feed (if `-PatternsFile` provided)
3. **Expand** — BFS 1-hop through dependency + related edges
4. **Output** — matched skills + dependencies

Ex: `-Task "security audit"` → security-scanner + best-practices. `-Task "implement feature"` → sdd-tasks + sdd-design + sdd-spec.

### Patterns Integration
Load patterns from dreaming to boost resolution:
```powershell
.\scripts\skill-graph.ps1 -Task "fix auth bug" -PatternsFile .learnings\skill-graph-patterns.json
```
Patterns boost matching skills by +2 score when task keywords match pattern keywords.

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
| **Dreaming patterns available** | **Load via `-PatternsFile` for smarter resolution** |

## When to use
- **Task start**: resolve before any `skill` tool call
- **Unfamiliar task**: find related skills you might miss
- **Token tight**: skip non-matching skills

## When NOT to use
- Single-step Q&A (cheaper to use skill directly)
- Already know exact skill needed

## Top 18 Skills
karpathy-loop · lean-context · quality-gate · auto-metrics · session-resume · cross-project-wisdom · skill-creator · immune-system · dreaming · metricas · commit-crafter · code-review-agent · bitacora · triple-verify · self-improvement · visual-testing · image-pipeline · pdf-utils

### Anti-Pattern Catalog
`{file:ANTI-PATTERN-CATALOG.md}` — scan BEFORE any task.

### Fallback Routing
Resume→session-resume · Write→skill-creator, sdd-*, quality-gate · Fix→recovery-protocol, immune-system, sdd-verify · Review→quality-gate, judgment-day, triple-verify · UI→baseline-ui, web-quality-audit, performance, accessibility, visual-testing · System→development-mode, execution-mode, skill-graph · Commit→commit-crafter · Secure→security-scanner · Wisdom→cross-project-wisdom · Images→image-pipeline · Documents→pdf-utils · Unknown→skill-creator, research, recovery-protocol

**Avoid**: Q&A→sdd-*,judgment-day · Setup→judgment-day · Bug fix→sdd-propose · Hotfix→triple-verify

### Load Order
1) ANTI-PATTERN-CATALOG 2) Behavioral match 3) Trigger match 4) Default-FAIL 5) Mini-dream every 5th

## Cross-Ref
- SKILLS-INDEX.md: full trigger table
- session-resume: uses skill-graph for context-aware resume
- execution-mode: QUICK mode prefers graph resolution
