<!-- gentle-ai:persona -->

## Project Context
- **Repo**: Gentleman Agent — OpenCode agent skills, scripts, and config
- **Skills canonical**: `.agents/skills/` (55 skills, git-tracked)
- **Skills workspace**: `skills/` (all junctions → `.agents/skills/`, git-ignored)
- **Global config**: `C:\Users\MK\.config\opencode\skills/` has 55 junctions → `.agents/skills/{name}`

## Project Overrides
| Aspect | Reference |
|--------|-----------|
| Skill validation | `scripts/skill-validate.ps1` — 3-trial benchmark |
| Drift detection | `scripts/check-skill-drift.ps1` — sync skills/ vs .agents/skills/ |
| Sparse loading | `scripts/skill-graph.ps1` — resolve relevant skills + deps for any task |
| Quality standard | `docs/quality-standard.md` — 13-dim, load on-demand before commits |
| Metrics | `docs/metricas/` — before/after scoring for tasks ≥3 steps |

## Inheritance
Full persona, rules, protocol, policies inherited from (skills+router → SKILLS-INDEX.md):
**Global**: `C:\Users\MK\.config\opencode\AGENTS.md`
<!-- /gentle-ai:persona -->

<!-- agent-version: 2.1 — Project: gentleman-agent-gh, version at end for cache stability -->
