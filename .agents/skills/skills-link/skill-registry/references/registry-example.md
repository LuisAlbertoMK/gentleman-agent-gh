# Registry Example

```markdown
# Registry

## Skills
| Trigger | Skill | Path |
|---------|-------|------|
| "explore codebase, pre-design" | sdd-explore | .agents/skills/sdd-explore/SKILL.md |
| "proposal, intent, approach" | sdd-propose | .agents/skills/sdd-propose/SKILL.md |
| "code review, 4R" | code-review-agent | .agents/skills/code-review-agent/SKILL.md |
| "commit, conventional commit" | commit-crafter | .agents/skills/commit-crafter/SKILL.md |

## Compact Rules
### sdd-explore
- Understand req → investigate → analyze options → persist → return
- Read actual code, not guess

### commit-crafter
- Analyze diff → categorize → write commit message
- Use conventional commits (feat/fix/chore/docs/refactor/test)

## Conventions
| File | Path |
|------|------|
| AGENTS.md | AGENTS.md |
| SKILLS-INDEX.md | SKILLS-INDEX.md |
```

## Scan Sources
| Source | Location | Priority |
|--------|----------|----------|
| Project skills | `.agents/skills/` | Highest |
| Global skills | `~/.config/opencode/skills/` | Medium |
| IDE config | `.cursorrules`, `GEMINI.md` | Low |
