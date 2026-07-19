---
name: skill-graph
description: "Sparse loading — resolve only relevant skills + dependencies, digest per context budget"
triggers: "sparse loading, skill resolution, relevant skills, which skill, skill-graph"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "2.1"
  changelog: "2.0→2.1: Karpathy compress (2525→1680B)"
---
## RESOLVE
```powershell
.\scripts\skill-graph.ps1 -Task "<task>" [-Expand N] [-Format Json|Csv]
```
Match keywords→triggers (fuzzy, min 3 chars). Expand BFS 1-hop deps. Output: matched + deps.

Ex: `"security audit"` → security-scanner + best-practices. `"implement feature"` → sdd-tasks + sdd-design + sdd-spec.

## DIGEST
| Context | Strategy | Target |
|---------|----------|--------|
| <40% / first load | Full skill | No limit |
| 40-60% (YELLOW) | Rules + decision tree | ~300 tok |
| >80% (RED) | 1-line + critical rules | ~100 tok |

Always check context % before loading. YELLOW/RED → truncate output.

## FEEDBACK
Post-task log to Engram: `title: "Skill resolution: {name}" | Applied: Y/N | Effective: Y/P/N`

## AUTO-IMPROVEMENT
| Signal | Action |
|--------|--------|
| Loaded NOT applied | Trigger too broad → narrow |
| Applied NOT effective | Update patterns |
| Same skill 3+ times | Flag heavy → digest more |

## When
- Task start (before `skill` call) · Unfamiliar task · Token tight
- NOT: single-step Q&A · already know exact skill

## Refs
session-resume · execution-mode · skill-registry · lean-context

## Anti-Patterns
Resolve every task · Load full in RED · Ignore feedback · Never update stale triggers
