# Skill Resolver Protocol

> Referenced by `prompts/sdd-orchestrator.md`.
> Orchestrator calls this ONCE per session, caches result, injects into sub-agents.

## Resolution (session start)

1. `mem_search(query: "skill-registry", project: "{project}")`
2. `mem_get_observation(id)` → full registry
3. Fallback: read `.atl/skill-registry.md`
4. Cache: Compact Rules + User Skills trigger table
5. No registry? → warn + proceed without project standards

## Injection (per sub-agent)

Match relevant skills by:
- **Code context**: file extensions/paths sub-agent touches
- **Task context**: review, PR, testing, etc.

Inject BEFORE task instructions:
```markdown
## Project Standards (auto-resolved)
{compact rule blocks}
```

## Compact Rules Format

Per `skills/skill-registry/`:
- 5-15 lines per skill
- Actionable, NO fluff
- Trigger → Skill → Path
- Convention files paths

## Feedback Loop

After delegation, check `skill_resolution`:
- `injected` → OK
- `fallback-registry` / `fallback-path` / `none` → re-read registry, re-inject next delegation

## Skip list

Per `skill-registry/SKILL.md`:
- SDD sub-agents (sdd-*)
- `_shared`
- `skill-registry` itself

---

*Part of gentleman-vMK-agent-gh. Created Sprint 4.*
