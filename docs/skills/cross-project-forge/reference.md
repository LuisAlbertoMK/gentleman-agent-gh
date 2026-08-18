# cross-project-forge — Reference Materials

> **Externalized from** .agents/skills/cross-project-forge/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
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
