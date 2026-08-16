---
name: skill-graph
description: "Sparse loading — resolve only relevant skills + dependencies, digest per context budget"
triggers: "sparse loading, skill resolution, relevant skills, which skill, skill-graph"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Sparse loading — resolve only relevant skills + dependencies

## RESOLVE
```powershell
.\scripts\skill-graph.ps1 -Task "<task>" [-Expand N] [-Format Json|Csv]
```
Match keywords→triggers (fuzzy, min 3 chars). Expand BFS 1-hop deps. Output: matched + deps.

Ex: `"security audit"` → security-scanner + best-practices. `"implement feature"` → sdd-tasks + sdd-design + sdd-spec.

## Output Format
### JSON (default)
```json
{ "matched": ["security-scanner", "best-practices"],
  "deps": ["lean-context"],
  "skill_count": 2, "dep_count": 1,
  "expand_chain": ["security-scanner", "best-practices"] }
```
### CSV (`-Format Csv`)
```
matched,dep_count,expand_chain
security-scanner;best-practices,1,security-scanner>best-practices
```
Use JSON for programmatic consumption; CSV for human review or spreadsheets.

## BFS Expansion Example
`-Expand 2` resolves 2 hops deep:
```
hop 0: "performance"        → perf-profiling
hop 1: perf-profiling       → [command-wrapper, lean-context]
hop 2: command-wrapper      → [bash-safe]
```
`-Expand 1` (default) stops at direct deps only. Expand >3 is rarely needed.

## Troubleshooting
| Symptom | Likely Cause | Fix |
|---------|-------------|------|
| "No skills matched" | Task too vague | Use 2-3 specific terms: "security audit JWT" not "check stuff" |
| Empty deps | No `dependencies` field | Check skill metadata frontmatter |
| Wrong match | Trigger overlap | Narrow task: "python async" vs "python django" disambiguates |
| Same item in loop | Circular dep | Report to skill-registry; BFS capped at 10 unique |
| Empty task (`-Task ""`) | No input | Defaults to `"task"` scan — rarely useful; always pass a real task |


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
