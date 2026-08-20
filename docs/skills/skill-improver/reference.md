# skill-improver - Reference Materials

> **Externalized from** .agents/skills/skill-improver/SKILL.md to keep the skill under the 2KB token budget (ADR-007).

## Testing
1. Frontmatter intact: 3 keys parse (`^name:|^description:|^triggers:`) → True. 2. Audit-only default: audit with no fixes → `git status --short` empty. 3. Healing logged: `mem_search(["skill:xyz"])` returns `(skill, session, why, fix)`.


## Externalized Sections (ADR-007 compression)
## Drift
Trigger: same bug 2x · unused 5+ · correction 2x · loss >5%.

| Signal | Action |
|---|---|
| Same bug 2+ | Update skill |
| Not loaded 5+ sessions | Flag or merge |
| Corrects same 2+ | Clarify rules |
| Loss >5% | Revert, rewrite |

**Healing**: Engram log `(skill, session, why, fix)`.


