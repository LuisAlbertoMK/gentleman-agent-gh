# opencode-skill-creator — Reference Materials

> **Externalized from** .agents/skills/opencode-skill-creator/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Anti-Patterns: Skip intake · One-shot · No baseline · Overfit evals · Install before validate

## Examples (4-5)

### Example 1: Code Review Skill
```
User: "Create a skill that reviews PRs for security issues"
Intake: 1. What languages? (TS/Python/Go) 2. Severity thresholds? 3. Output: inline comments or summary?
Draft: SKILL.md with triggers: "security review, code review, PR audit"
Test: 3 PRs (1 clean, 1 XSS, 1 SQLi) → with-skill catches 2/2, baseline catches 0/2
Iterate: Add CSP header check → re-run → install to .opencode/skills/security-review/
```

### Example 2: API Contract Testing Skill
```
User: "Skill to validate API responses match OpenAPI spec"
Intake: 1. REST + GraphQL? 2. Strict or lenient? 3. CI integration?
Draft: triggers: "api test, contract test, openapi validate"
Test: 3 endpoints (valid, missing field, type mismatch) → skill: 3/3, baseline: 1/3
Iterate: Handle nullable arrays → re-test 5 endpoints → install globally
```

### Example 3: Performance Profiling Skill
```
User: "Skill to find N+1 queries in SQLAlchemy code"
Intake: 1. Sync/async? 2. Detect in loops only? 3. Output: file:line or call graph?
Draft: triggers: "n+1, sqlalchemy, performance, slow query"
Test: 3 repos (1 with N+1, 1 clean, 1 false positive) → skill: 2/3 (missed async), baseline: 0/3
Iterate: Add async pattern → 3/3 → install
```

### Example 4: Migration Helper Skill
```
User: "Skill to migrate from Express to FastAPI"
Intake: 1. Auto-rewrite or guide? 2. Middleware mapping? 3. Test coverage target?
Draft: triggers: "express fastapi migration, framework migration"
Test: 2 apps (small, medium) → skill produces working FastAPI + tests pass, baseline: manual errors
Iterate: Add dependency injection mapping → re-test → install project-local
```

### Example 5: Documentation Generator Skill
```
User: "Generate README from code structure and docstrings"
Intake: 1. Template style? (minimal, comprehensive) 2. Include diagrams? 3. Update on commit?
Draft: triggers: "generate readme, docs from code, auto-documentation"
Test: 3 projects (TS, Python, Go) → skill: 3/3 readable, baseline: 1/3 (generic)
Iterate: Add Mermaid diagrams for architecture → re-test → install globally
```

## Testing Patterns (3)

### Pattern 1: Golden Master Regression
- Capture baseline output for known-good inputs → `evals/golden/`
- On iteration, diff new output against golden master
- Pass if semantic equivalence (AST diff for code, normalized text for docs)
- Fail on behavioral drift even if "looks better"

### Pattern 2: Adversarial Input Suite
- Curate 10-20 edge inputs per trigger: empty, malformed, huge, adversarial, unicode, concurrent
- Run with-skill + baseline on ALL → measure false positive/negative rates
- Target: <5% false positive, <2% false negative on adversarial set
- Document each adversarial case in `evals/adversarial.json` with expected behavior

### Pattern 3: Cross-Model Consistency
- Run same eval suite against 2+ models (e.g., gpt-4o, claude-3.5-sonnet)
- Skill must produce semantically equivalent results across models
- Variance threshold: <10% token count, <15% duration, zero functional diff
- Capture per-model timing in `timing-{model}.json`

## Edge Cases (4)

### Edge Case 1: Trigger Collision
- Two skills claim same trigger (e.g., "docker" matches both docker-best-practices and docker-security)
- Resolution: Skill with more specific trigger wins; document in SKILL.md `priority` field (1-10)
- Test: Fire ambiguous prompt → verify correct skill activates → log in `evals/trigger-collision.json`

### Edge Case 2: Skill Dependency Chain
- Skill A requires Skill B (e.g., `testing-strategy` needs `project-mapper` output)
- Draft: Declare `dependencies: ["project-mapper"]` in frontmatter
- Test: Run A without B → graceful degradation with warning, not error
- Test: Run A with B → full functionality → verify in `evals/deps.json`

### Edge Case 3: Large Context Overflow
- Skill input exceeds model context (e.g., 200KB codebase dump)
- Draft: Add `context_budget: "auto"` → triggers recursive summarization (L1/L2/L3)
- Test: Feed 500KB → verify output quality maintained, tokens <80% limit
- Document compression ratio in `evals/context-overflow.json`

### Edge Case 4: Partial Index / Stale Graph
- Codebase-memory index missing symbols (parse_partial) or stale after git pull
- Draft: Skill checks `index_status` first → warns if coverage <90% or age >1h
- Test: Corrupt index → skill degrades to grep/read fallback → logs warning
- Verify: Output quality within 15% of full-index run → `evals/stale-index.json`

## Anti-Patterns (2 Additional)

### Anti-Pattern: "MUST/ALWAYS" Over-Specification
- **Symptom**: Skill littered with `MUST`, `ALWAYS`, `NEVER` for subjective style choices
- **Why it fails**: Models interpret literally → brittle, fights valid alternatives, hallucinates compliance
- **Fix**: Use `PREFER`, `RECOMMEND`, `CONSIDER` + rationale. Reserve `MUST` for correctness/security only.
- **Test**: Run adversarial prompts → count false rejections of valid code

### Anti-Pattern: Eval Overfitting
- **Symptom**: Skill passes 100% on eval suite but fails on real user prompts
- **Why it fails**: Evals test known patterns; real world has distribution shift
- **Fix**:
  1. Hold-out set: 20% of evals NEVER seen during iteration
  2. Add 1 "wildcard" test per iteration (unseen prompt from user logs)
  3. Track `holdout_pass_rate` vs `train_pass_rate` → gap >15% = overfit
- **Metric**: `overfit_score = train_pass - holdout_pass` → target <0.15

## Externalized Sections (ADR-007 compression)
## Running evals (continuous)
Workspace: `<skill>-workspace/`. Results in `iteration-N/eval-ID/{with_skill,baseline}/outputs/`.

1. **Spawn all runs same turn**: Each test → 2 Task calls (with-skill + baseline). Baseline = `without_skill` (new) or snapshot (improvement).
2. **Draft assertions while running**: Objective → quantitative. Subjective → skip.
3. **Capture timing**: `total_tokens` + `duration_ms` → `timing.json`.
4. **Grade → Aggregate → Viewer**: Grade via `agents/grader.md` → `grading.json`. Aggregate: `skill_aggregate_benchmark(...)`. Analyze: `agents/analyzer.md`. Viewer: `skill_serve_review` or `skill_export_static_review`.
5. **Read feedback**: `feedback.json`. Stop via `skill_stop_review`.
