---
name: cross-project-forge
description: "Manual pipeline promoting a recurring pattern to an auto-generated skill when it hits severity threshold."
triggers: "forge, promote pattern, auto-skill, forjar, convertir patrón, skill desde patrón, cross-project-forge"
changelog: docs/ciclos/cycle28-20260815.md
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
- Forging patterns that are project-specific, not cross-project
- Forging without validating the generalized rule works in reverse (false positives)

## Examples

### Example 1: Auth Middleware Pattern (CRITICAL)
**Pattern**: `auth/middleware-missing-role-check`
- Occurrences: 3 projects (hoa, finance, inventory)
- Severity: CRITICAL (1 occurrence, 1 project minimum)
- Generalized rule: "All protected routes must validate role claim before handler executes"
- Forged skill: `cross-project-auth-role-guard`
- Trigger: `auth`, `middleware`, `role`, `rbac`, `protected route`

### Example 2: SQL Injection Prevention (HIGH)
**Pattern**: `db/raw-query-user-input`
- Occurrences: 4 projects (api, billing, reporting, analytics)
- Severity: HIGH (2 occurrences, 2 projects minimum)
- Generalized rule: "Never concatenate user input into raw SQL; use parameterized queries"
- Forged skill: `cross-project-sql-injection-guard`
- Trigger: `sql`, `raw query`, `parameterized`, `injection`, `db`

### Example 3: N+1 Query Detection (MEDIUM)
**Pattern**: `orm/n-plus-one-loop`
- Occurrences: 3 projects (e-commerce, crm, dashboard)
- Severity: MEDIUM (3 occurrences, 2 projects minimum)
- Generalized rule: "Fetch related data in batch before loop; never query inside iteration"
- Forged skill: `cross-project-nplusone-detector`
- Trigger: `n+1`, `orm`, `loop`, `query`, `batch`, `eager load`

### Example 4: Secret Leak in Logs (HIGH)
**Pattern**: `logging/secret-exposure`
- Occurrences: 2 projects (payment, auth-service)
- Severity: HIGH (2 occurrences, 2 projects minimum)
- Generalized rule: "Sanitize sensitive fields (password, token, key, secret) before logging"
- Forged skill: `cross-project-secret-sanitizer`
- Trigger: `logging`, `secret`, `password`, `token`, `sanitize`, `pii`

### Example 5: Async Error Swallowing (MEDIUM)
**Pattern**: `async/uncaught-promise-rejection`
- Occurrences: 5 projects (worker, queue, scheduler, webhook, notification)
- Severity: MEDIUM (3 occurrences, 2 projects minimum)
- Generalized rule: "All async operations must have .catch() or try/catch with proper error handling"
- Forged skill: `cross-project-async-error-guard`
- Trigger: `async`, `promise`, `catch`, `error handling`, `unhandled rejection`

## Testing Patterns

### Pattern 1: Positive Detection Test
```json
{
  "name": "detects violation",
  "input": "code with the anti-pattern",
  "expect": "skill triggers and reports violation"
}
```
- Feed known-bad code samples from each originating project
- Verify skill triggers on ALL samples (no false negatives)
- Assert rule message matches generalized rule text

### Pattern 2: Negative Detection Test (False Positive Guard)
```json
{
  "name": "allows correct code",
  "input": "code that looks similar but is correct",
  "expect": "skill does NOT trigger"
}
```
- Feed known-good variants (parameterized queries, batched fetches, sanitized logs)
- Verify skill stays silent (zero false positives)
- Edge: code that uses pattern keywords legitimately (e.g., "password" in variable name)

### Pattern 3: Cross-Project Regression Test
```json
{
  "name": "regression across projects",
  "input": "all project codebases at promotion time",
  "expect": "same violation count as original pattern detection"
}
```
- Run forged skill against ALL indexed projects (not just originating ones)
- Compare violation count to original pattern occurrences
- New violations in non-originating projects = skill generalizes correctly
- Zero violations in originating projects = regression (skill broken)

## Edge Cases

### Edge Case 1: Pattern Exists But Uses Different Terminology
- Project A: "JWT middleware", Project B: "Token validator", Project C: "Auth guard"
- Solution: Include ALL synonyms in `triggers` field; use semantic_query in skill-graph

### Edge Case 2: Pattern Fixed Differently Across Projects
- Project A: Parameterized queries, Project B: ORM only, Project C: Stored procedures
- Solution: Generalize to "use safe query method" not specific implementation; rules check OUTCOME not METHOD

### Edge Case 3: Severity Threshold Met But Pattern Is Project-Specific
- 5 occurrences in 1 monorepo (different packages), 0 in other repos
- Solution: Check `min projects` NOT just `min occurrences`; abort if single-repo pattern

### Edge Case 4: Forged Skill Conflicts With Existing Skill
- New skill triggers overlap with `auth-hardening` or `security-scanner`
- Solution: Run `skill-graph` resolver check before register; if conflict → merge or defer

## Resources

`wisdom-store.ps1` · `wisdom-loader.ps1` · `pattern-guard.ps1` · `skill-graph.ps1`
`docs/cross-project/patterns/*.json` · `docs/cross-project/PLAN.md`

## Refs
cross-project-wisdom · opencode-skill-creator · skill-registry · skill-graph · dreaming
