---
name: skill-testing
description: "Test and verify skill quality — syntax, coverage, integration, and token budget assessment before production use"
triggers: "Test/verify skill, coverage"
changelog: docs/ciclos/cycle28-20260815.md
---

Trigger: After creating/modifying skill, before production use.

## When to Use

- After new/edited skill
- Pre-critical-task verification
- Periodic active skill checks

## Framework

`Test → Verify → Score → Approve/Reject`

## Test Types

1. **Syntax**: frontmatter complete · Headers correct · Assets exist · Triggers unique
2. **Coverage**: primary use case · edge cases · templates · anti-patterns
3. **Integration**: Load via trigger → Apply → Verify output
4. **Tokens**: Avg prompt < X · Longest template < Y · Decision tree legible

## Checklist by Type

| Type | Check |
|------|-------|
| Prompt | Frontmatter · Framework · Templates · Anti-patterns · Examples · Triggers |
| Workflow | Sequential steps · Decisions · Error handling · Commands · Test cases |
| Template | Structure · Placeholders · Examples · Variations |

## Scoring

| Criteria | Weight |
|----------|--------|
| Syntax | 20% |
| Coverage | 30% |
| Integration | 30% |
| Usability | 20% |

**Thresholds**: 9-10: ✅ Production | 7-8: ⚠ Needs work | <7: ❌ Reject

## Default Tests (ALL skills)

1. Syntax: frontmatter parses
2. Structure: required sections exist
3. Links: assets exist (if referenced)
4. Triggers: clear and unique
5. Format: valid markdown

**Prompt skills (+):** Token budget OK · ≥3 templates · Anti-patterns · Decision tree
**Workflow skills (+):** Sequential steps · Error handling · Executable commands · ≥1 example
## Report Template
```markdown
## Skill Test Report | {name} | {version}| Test | Status || Syntax | ✅/❌ |
### Verdict: ✅ APPROVED / ⚠ NEEDS WORK / ❌ REJECTED
```

## Refs
skill-registry · opencode-skill-creator · skill-improver · quality-gate · karpathy-loop

## Testing Patterns

### Pattern 1: Golden Prompt Suite
Maintain a `tests/prompts/` directory with 5-10 real user prompts covering primary + edge cases. Run each against the skill via the load-apply-verify loop. Compare output to golden snapshots. Fail if diff > threshold.
```bash
# Example test script
for prompt in tests/prompts/*.txt; do
  skill load skill-testing < "$prompt" > actual.out
  diff -u tests/golden/$(basename "$prompt") actual.out || exit 1
done
```

### Pattern 2: Trigger Collision Matrix
Build a matrix of all registered skills × their triggers. Verify no two skills fire on the same natural-language query. Use `skill-registry` to dump triggers, then cross-check with `comm -12`.
```bash
skill-registry dump --triggers | sort | uniq -d  # Should be empty
```

### Pattern 3: Token Budget Regression
Record `avg_prompt_tokens` and `max_template_tokens` in the skill's frontmatter. On every test run, measure actuals and assert `< recorded * 1.1`. Fail if growth exceeds 10%.
```javascript
// In test runner
const budget = JSON.parse(fs.readFileSync('skill.json')).token_budget;
assert(actual_avg < budget.avg * 1.1);
assert(actual_max < budget.max * 1.1);
```

## Edge Cases

| # | Edge Case | Test Approach |
|---|-----------|---------------|
| 1 | **Ambiguous trigger** — user query matches 2+ skills | Feed ambiguous prompts; verify orchestrator asks clarifying question, doesn't pick randomly |
| 2 | **Missing asset** — skill references file that doesn't exist | Parse frontmatter `assets:`, verify each path exists via `glob` before approval |
| 3 | **Circular dependency** — skill A loads skill B loads skill A | Build load graph from `skill load` calls; run cycle detection (DFS) |
| 4 | **Template injection** — placeholder receives malicious input | Fuzz placeholders with `{{7*7}}`, `<script>`, `$(rm -rf /)` — verify no code execution, only string substitution |

## Anti-Patterns

| # | Anti-Pattern | Why It Fails | Fix |
|---|--------------|--------------|-----|
| 1 | **Test only syntax, skip integration** | Catches typos, misses broken workflows, wrong outputs | Always run load-apply-verify with real prompts |
| 2 | **Never verify triggers** | Skills fire on wrong queries, silently corrupt results | Run Trigger Collision Matrix (Pattern 2) on every change |
| 3 | **Ship with <7 score** | Low-quality skills degrade user trust, increase support burden | Enforce threshold in CI: `score >= 7` gate |
| 4 | **Skip token budget check** | Prompt bloat pushes context over limit, truncates silently | Record budgets in frontmatter, assert on every test (Pattern 3) |
| 5 | **Test without real prompts** | Synthetic tests miss real-world phrasing, edge cases | Maintain Golden Prompt Suite (Pattern 1) from actual user queries |
| 6 | **No negative tests** | Only verifies happy path; errors, timeouts, partial failures untested | Add failure-injection tests: missing files, malformed input, timeouts |

## Examples

### Example 1: Prompt Skill Test (e.g., `code-review-agent`)
```markdown
## Skill Test Report | code-review-agent | 2.1
| Test | Status |
| Frontmatter valid | ✅ |
| Required sections (4R + templates) | ✅ |
| Triggers unique (code review, PR feedback) | ✅ |
| Token budget (avg < 800, max < 2000) | ✅ (avg 620, max 1840) |
| Templates: 4 (risk, readability, reliability, resilience) | ✅ |
| Anti-patterns documented: 5 | ✅ |
| Decision tree legible | ✅ |
| Golden prompts (8/8 pass) | ✅ |
| Integration (load + apply on real PR) | ✅ |
### Verdict: ✅ APPROVED (9.5/10)
```

### Example 2: Workflow Skill Test (e.g., `sdd`)
```markdown
## Skill Test Report | sdd | 1.3
| Test | Status |
| Frontmatter valid | ✅ |
| Required sections (9 phases + quick path) | ✅ |
| Triggers unique (sdd init, sdd spec, sdd verify) | ✅ |
| Token budget (avg < 1200, max < 3000) | ⚠ (avg 1150, max 3100) |
| Sequential steps: 9 phases, each with decision gates | ✅ |
| Error handling: rollback per phase | ✅ |
| Executable commands: all scripts exist | ✅ |
| Examples: 3 (init, spec, verify) | ✅ |
| Golden prompts (6/6 pass) | ✅ |
| Integration (full SDD cycle on demo feature) | ✅ |
### Verdict: ⚠ NEEDS WORK (7.8/10) — token budget exceed
```

### Example 3: Template Skill Test (e.g., `commit-crafter`)
```markdown
## Skill Test Report | commit-crafter | 1.0
| Test | Status |
| Frontmatter valid | ✅ |
| Structure: template + placeholders + variations | ✅ |
| Placeholders: {type}, {scope}, {subject}, {body} | ✅ |
| Variations: 3 (feat, fix, chore) | ✅ |
| Token budget (template < 300) | ✅ (245) |
| Anti-patterns: 3 (vague subject, missing scope, no body) | ✅ |
| Golden prompts (5/5 pass) | ✅ |
### Verdict: ✅ APPROVED (9.0/10)
```

### Example 4: Integration Failure (Anti-Pattern Demo)
```markdown
## Skill Test Report | broken-skill | 0.1
| Test | Status |
| Frontmatter valid | ✅ |
| Required sections | ❌ (missing Workflow) |
| Triggers unique | ❌ (collides with code-review-agent) |
| Token budget | ❌ (not measured) |
| Integration (load + apply) | ❌ (loads but produces empty output) |
### Verdict: ❌ REJECTED (3.2/10)
```

### Example 5: Edge Case Coverage (Ambiguous Trigger)
```markdown
## Skill Test Report | ambiguous-trigger-test | 1.0
| Test | Status |
| Ambiguous prompt "review this" | ✅ (orchestrator asks: "code review or PR review?") |
| Missing asset `templates/missing.md` | ✅ (detected in Syntax check) |
| Circular dependency (A→B→A) | ✅ (detected in Integration) |
| Template injection `{{7*7}}` in placeholder | ✅ (outputs literal "{{7*7}}", no eval) |
### Verdict: ✅ APPROVED (9.0/10) — all edge cases handled
```

## Example: Test Report
```markdown
## Skill Test Report | server-commands | 1.0
| Test | Status |
| Frontmatter valid | ✅ |
| Required sections | ✅ |
| Triggers unique | ✅ |
| Token budget (<500 tokens) | ✅ (~180) |
| Integration (load + apply) | ✅ |
### Verdict: ✅ APPROVED (9.2/10)
```
