---
name: skill-graph
description: Sparse loading — resolve only relevant skills + dependencies for any task using dependency graph.
triggers: "sparse loading, skill resolution, relevant skills, skill dependencies, which skill, skill-graph, resolver skill, minimo skills, solo skills needed"
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

# Skill Graph — Sparse Loading Resolver

Instead of loading all 54 skills, resolve only the relevant ones plus 1-hop dependencies.

## Usage

```powershell
.\scripts\skill-graph.ps1 -Task "<task description>"
                              [-Expand N]   # dependency depth (default 1, max 3)
                              [-Format Json|Csv]  # machine-readable output
```

## Resolution strategy

1. **Match** — task keywords matched against skill triggers (fuzzy, min 3 chars)
2. **Expand** — BFS 1-hop through dependency + related edges
3. **Output** — matched skills + their dependencies with load commands

## Examples

```
Input:  -Task "security audit"
Output: security-scanner + best-practices (depends_on)

Input:  -Task "implement feature from spec"
Output: sdd-tasks + sdd-design (depends_on) + sdd-spec (depends_on)
```

## When to use

- **Task start**: resolve skills before requesting any `skill` tool call
- **Unfamiliar task**: let the graph find related skills you might miss
- **Token budget tight**: skip loading skills that don't match

## When NOT to use

- Single-step Q&A (cheaper to just use the skill directly)
- When you already know exactly which skill you need

## Cost

| Step | Tokens | Notes |
|------|--------|-------|
| Script execution | ~5-50 | One PS process, returns text |
| Reading output | ~10-100 | Minimal — just skill names |
| Loading matched skills | Varies | Only what resolves, not all 54 |

vs loading all 54 skills: typically 4-8 instead of 54 = −85-92% skill tokens.

## Cross-References
- **SKILLS-INDEX.md**: full trigger table (fallback when graph can't match)
- **session-resume**: uses skill-graph for context-aware resume
- **execution-mode**: QUICK mode prefers graph resolution over full index scan
