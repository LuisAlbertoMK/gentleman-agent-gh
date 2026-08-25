# immune-system — Reference Materials

> **Externalized from** .agents/skills/immune-system/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Anti-patterns
- Silent retry -> Document first | "I'll remember" -> Write catalog
- Fix symptom -> Trace root cause | Fix current case -> Generalize prevention

## Refs
dreaming · recovery-protocol · cross-project-wisdom · session-resume · bitacora

## Examples (4-5)

### Example 1: Silent Retry on FTS5 Query
**Symptom**: FTS5 MATCH throws "syntax error" on user input with special chars
**First occurrence**: User queries "fix auth bug" → crashes because FTS5 interprets `auth` as operator
**Root cause**: No input sanitization before passing to FTS5 MATCH
**Fix**: Wrap each search term in quotes via `sanitizeFTS()` helper
**Prevention rule**: "Always sanitize user input for FTS5 — never pass raw strings to MATCH"
**Catalog entry**: 2026-08-15: FTS5 syntax error on special chars
**Files**: `internal/store/store.go` — `sanitizeFTS()` function

### Example 2: Missing mem_save on Architectural Decision
**Symptom**: Switched auth from sessions to JWT but didn't persist decision
**Second occurrence**: New session asks "why JWT?" — no memory, had to re-explain
**Root cause**: Assumed decision was "obvious" — didn't call `mem_save` after decision
**Fix**: Added mandatory `mem_save` after every architectural decision (type: "decision")
**Prevention rule**: "Decision made → mem_save immediately. No exceptions."
**Catalog entry**: 2026-08-10: Missing mem_save on auth architecture decision
**Files**: `src/middleware/auth.ts`, `src/routes/login.ts`

### Example 3: Tool Misuse — Grep vs Codegraph
**Symptom**: Spent 15 min grep'ing for "loginUser" across 50 files
**Root cause**: Used grep instead of `codegraph_explore` / `search_graph` for symbol discovery
**Fix**: Default to code graph for symbol/relationship queries; grep only for literal text
**Prevention rule**: "Symbol search → codegraph. Literal text → grep. Never grep for function names."
**Catalog entry**: 2026-08-12: Tool misuse — grep for symbol discovery
**Files**: `.agents/skills/code-generation/SKILL.md` (updated guidance)

### Example 4: Premature Declaration — "Done" Before Verify
**Symptom**: Declared task complete; tests failed in CI 20 min later
**Root cause**: Skipped `triple-verify` / local test run; assumed syntax check = passing tests
**Fix**: Mandatory verification step before "done" — run tests, lint, typecheck
**Prevention rule**: "Done = tests pass + lint clean + typecheck clean. Not 'compiles'."
**Catalog entry**: 2026-08-08: Premature declaration without verification
**Files**: `.agents/skills/quick-executor/SKILL.md`, `.agents/skills/deep-debugging/SKILL.md`

### Example 5: Cross-Project Pattern Lost
**Symptom**: Solved N+1 query pattern in Project A; re-solved same in Project B 3 months later
**Root cause**: Saved as project-scoped memory (`scope: "project"`), not cross-project (`scope: "personal"` with `topic_key`)
**Fix**: Use `mem_save(topic_key="pattern/n-plus-one", scope="personal", type="pattern")` for reusable patterns
**Prevention rule**: "Reusable pattern → scope=personal + topic_key. Project-specific → scope=project."
**Catalog entry**: 2026-08-05: Cross-project pattern not saved for reuse
**Files**: `docs/mejoras/mejora-n-plus-one.md` (created)

## Testing Patterns (3)

### Pattern 1: Pre-Task Immunity Check (Unit)
```go
func TestImmunityCheck(t *testing.T) {
    catalog := LoadAntiPatternCatalog()
    task := "Add rate limiting to auth middleware"
    // Should detect "premature declaration" pattern from Example 4
    patterns := catalog.Match(task)
    assert.Contains(t, patterns, "premature-declaration")
    assert.Contains(t, patterns.Prevention, "tests pass")
}
```

### Pattern 2: Catalog Entry Completeness (Integration)
```python
def test_catalog_entry_has_all_fields():
    entry = create_entry(
        symptom="FTS5 syntax error",
        root_cause="no sanitization",
        fix="sanitizeFTS()",
        prevention="always sanitize"
    )
    assert entry.symptom
    assert entry.root_cause
    assert entry.fix
    assert entry.prevention
    assert entry.files  # At least one file path
    assert entry.date   # YYYY-MM-DD format
```

### Pattern 3: Cross-Project Retrieval (E2E)
```javascript
// Simulates new session in different project
const memory = await memSearch({
  query: "pattern: n+1 query",
  scope: "personal",
  type: "pattern"
});
assert(memory.length > 0, "Cross-project pattern should be retrievable");
const pattern = memory[0];
assert(pattern.topic_key === "pattern/n-plus-one");
assert(pattern.content.includes("Domain"));
assert(pattern.content.includes("Prevention"));
```

## Edge Cases (4)

### Edge Case 1: Concurrent Same-Error Detection
Two agents hit same error simultaneously in different tasks.
**Resolution**: First agent to complete catalog entry wins; second agent reads catalog on pre-check and applies prevention immediately. Use file lock on `ANTI-PATTERN-CATALOG.md` during write.

### Edge Case 2: False Positive Pattern Match
Task description contains keywords that match a catalog entry but context differs.
**Resolution**: Prevention rules must include context qualifier (e.g., "When using FTS5 MATCH..."). Pre-check shows matched rule + context; agent confirms applicability before applying.

### Edge Case 3: Catalog Bloat — Obsolete Patterns
Patterns from deprecated tools/versions accumulate.
**Resolution**: Quarterly review (triggered by `dreaming` skill). Mark obsolete with `status: "archived"`. Keep for history but exclude from pre-check matching.

### Edge Case 4: User Disagrees with Prevention Rule
User explicitly wants different approach than catalog prevention.
**Resolution**: Document exception in task context: `mem_save(type="preference", content="User override: {reason}")`. Catalog rule stays; exception is scoped to this task/user preference.

## Anti-patterns (Extended)

- **Silent retry** → Document first | "I'll remember" → Write catalog
- **Fix symptom** → Trace root cause | Fix current case → Generalize prevention
- **Assume obvious** → No mem_save → Next session forgets → "Why did we do X?"
- **Scope mismatch** → Project-scoped memory for reusable pattern → Cross-project re-work

## Externalized Sections (ADR-007 compression)
## YYYY-MM-DD: title
**Symptom**: | **Root cause**: | **Fix**: | **Prevention**: 1 rule | **Files**: paths
```

### 4. IMMUNIZE (both required)
- Catalog entry = loaded at session start (documents failure)
- Prevention rule -> AGENTS.md (changes behavior)
- Code/skill change -> `mem_save` + update SKILL.md
- Cross-project: also `mem_save(topic_key="pattern/{name}", type="pattern", scope="personal")` so wisdom loader can retrieve it
- Rule: "Catalog documents. AGENTS.md prevents. Both or not immunized."

#### Cross-Project Save Format
When saving to Engram for cross-project retrieval, use:
```
title: "pattern: {symptom}"
type: "pattern"
scope: "personal"
content: "**Domain**: {domain}\n**Symptom**: {symptom}\n**Root cause**: {root_cause}\n**Fix**: {fix}\n**Prevention**: {prevention}"
topic_key: "pattern/{normalized-title}"
```

### 5. VERIFY
Pre-task: "Seen this before?" If yes -> apply prevention BEFORE starting.
