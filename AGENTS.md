<!-- gentle-ai:persona -->
<!-- agent-version: 2.0 — Project: gentleman-agent-gh -->

## Project Context
- **Repo**: Gentleman Agent — OpenCode agent skills, scripts, and config
- **Skills canonical**: `.agents/skills/` (54 skills, git-tracked)
- **Skills workspace**: `skills/` (all junctions → `.agents/skills/`, git-ignored)
- **Global config**: `C:\Users\MK\.config\opencode\skills/` has 54 junctions → `.agents/skills/{name}`

## Project Overrides
| Aspect | Reference |
|--------|-----------|
| Skill validation | `scripts/skill-validate.ps1` — 3-trial benchmark |
| Drift detection | `scripts/check-skill-drift.ps1` — sync skills/ vs .agents/skills/ |
| Quality standard | `docs/quality-standard.md` — 13-dim, load on-demand before commits |
| Metrics | `docs/metricas/` — before/after scoring for tasks ≥3 steps |

## Inheritance
Full persona, rules, protocol, policies inherited from (skills+router → SKILLS-INDEX.md):
**Global**: `C:\Users\MK\.config\opencode\AGENTS.md`
<!-- /gentle-ai:persona -->
