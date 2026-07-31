---
name: cross-project-forge
description: "Manual pipeline to promote a recurring pattern to an auto-generated skill — triggered when a pattern hits its severity threshold."
triggers: "forge, promote pattern, auto-skill, forjar, convertir patrón, skill desde patrón, cross-project-forge"
---

## When to Use
Is this pattern ready to forge?

Check severity threshold:

| Severity | Min ocurrences | Min projects |
|----------|---------------|--------------|
| CRITICAL | 1 | 1 |
| HIGH | 2 | 2 |
| MEDIUM (default) | 3 | 2 |
| LOW | 5 | 3 |

If threshold NOT met → abort. Inform user: "Pattern needs {N} more occurrences across {M} more projects."

## Pipeline

### 1. GENERATE

From pattern JSON → SKILL.md structure:

```
name: cross-project-{pattern.id.slug}
description: "{pattern.rule.summary}" (≤120 chars)
triggers: "{pattern.tags + pattern.signal.keywords}"
rules: "{pattern.rule.fix generalized} + {pattern.rule.check generalized}"
```

### 2. QUALITY GATES (all mandatory)

- [ ] YAML frontmatter parses
- [ ] `name` has `cross-project-` prefix (avoids collision)
- [ ] `description` ≤ 120 chars
- [ ] `triggers` not empty, no dupe with existing skill triggers
- [ ] `rules` ≥ 1 executable rule (imperative verb + condition)
- [ ] No contradictions with existing skills
- [ ] SKILL.md ≤ 2KB (auto-Karpathy-compress if exceeds)
- [ ] `skill-graph` resolves this skill for its triggers
- [ ] No secrets, no absolute paths

### 3. REGISTER

1. Create `.agents/skills/cross-project-{name}/SKILL.md`
2. `skill-registry` scan → detects new skill
3. `skill-graph` re-scan → adds to resolver (lazy-load, not auto-load)
4. Update AGENTS.md: add to Skill Router if appropriate

### 4. PERSIST

```powershell
mem_save(topic_key="forge/{name}", content="forge metadata here", type="architecture", scope="personal")
```

Update pattern JSON:
- `status` → `"promoted"`
- Add `skill_ref: "cross-project-{name}"`

## Rollback

If the forged skill causes issues:

```powershell
# 1. Remove skill directory
Remove-Item -Recurse .agents/skills/cross-project-{name}/
# 2. Revert AGENTS.md if changed
git checkout AGENTS.md
# 3. Demote pattern back to active
# Edit pattern JSON: status=active, skill_ref=null
# 4. mem_save(topic_key="forge/rollback/{name}")
```

## Anti-Patterns

- Forging a pattern with < 3 occurrences / 1 project (premature)
- Forging LOW severity patterns (clutter)
- Auto-loading forged skills (they should be lazy-load only)
- Skipping quality gates to save time
- Forging without user approval

## Resources

`wisdom-store.ps1` · `wisdom-loader.ps1` · `pattern-guard.ps1` · `skill-graph.ps1`
`docs/cross-project/patterns/*.json` · `docs/cross-project/PLAN.md`

## Refs
cross-project-wisdom · opencode-skill-creator · skill-registry · skill-graph · dreaming
