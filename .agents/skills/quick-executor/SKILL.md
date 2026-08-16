---
name: quick-executor
description: "Trigger: quick edit, single file, atomic edit, fast fix, one-line fix. Single-file low-risk changes."
triggers: "quick edit, single file, atomic edit, fast fix, one-line fix, small change, quick fix"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
1 file, clear before/after, low risk. SCOPE GUARD: >1 file → STOP, report to orchestrator or delegate to plan-execution.

## WORKFLOW
1. **READ** target file. Not exists → delegate to code-generation. Never create files directly.
2. **PLAN** minimal edit. Risk check: >20 lines OR >2 functions OR new deps → STOP, over-scoping.
3. **EDIT** in one atomic operation.
4. **VERIFY**: Test exists → run it. Build exists → run it. Language check:
   - Python: `python -c "import ast; ast.parse(open('file').read())"`
   - JS/TS: `node --check file.js` / `npx tsc --noEmit`
   - Go: `go vet ./...`
   - Rust: `cargo check`
   - Java: `javac -d /tmp File.java`
   - Ruby: `ruby -c file.rb`
   - PHP: `php -l file.php`
   - Shell: `bash -n script.sh`
   - Other: Read, verify syntax manually, note in report.
5. **REPORT**: One line.

## FAILURE
- Parse/compile fail → `git checkout -- <file>` (if git), suggest deep-debugging
- Test fail → 1 fix attempt. Still fails → STOP, escalate
- Unclear requirements → STOP, 1 question

## STANDALONE MODE
If invoked directly (not via orchestrator): report issues as findings, do not escalate. Apply fixes if clear.

## SEVERITY
| P0 | Blocks other work | P1 | User-facing bug | P2 | Improvement | P3 | Cleanup |

## OUTPUT
```
Changed [file] (lines N-M). Verified: [pass/fail].
```

## Rules
1. Max 1 file. No exceptions. 2. No rename/extract/refactor adjacent code. 3. No new dependencies. 4. Risk heuristic: size + complexity + deps → if any borderline → STOP.

## Refs
code-generation · commit-crafter · deep-debugging

## Anti-Patterns
Multi-file scope creep · Refactor adjacent code · Add dependencies · Skip verification · Create files (delegate to code-generation)

## Examples

### Example 1: Fix typo in error message
```python
# Before
raise ValueError("Invlid input")  # typo

# After  
raise ValueError("Invalid input")
```
- File: `src/validators.py` line 42
- Risk: P3 (cleanup), 1 line change
- Verification: `python -c "import ast; ast.parse(open('src/validators.py').read())"`

### Example 2: Add missing null check
```javascript
// Before
function getUserName(user) {
  return user.name.toUpperCase();
}

// After
function getUserName(user) {
  if (!user || !user.name) return "Unknown";
  return user.name.toUpperCase();
}
```
- File: `src/utils/user.js` lines 10-14
- Risk: P1 (user-facing bug), 3 lines added
- Verification: `node --check src/utils/user.js`

### Example 3: Fix off-by-one in loop
```go
// Before
for i := 0; i <= len(items); i++ {  // off-by-one
  process(items[i])
}

// After
for i := 0; i < len(items); i++ {
  process(items[i])
}
```
- File: `internal/processor/processor.go` line 27
- Risk: P0 (blocks other work), 1 char change
- Verification: `go vet ./internal/processor/...`

### Example 4: Update config constant
```typescript
// Before
const MAX_RETRIES = 3;

// After
const MAX_RETRIES = 5;  // increased per ticket #234
```
- File: `src/config/constants.ts` line 12
- Risk: P2 (improvement), 1 line
- Verification: `npx tsc --noEmit src/config/constants.ts`

### Example 5: Fix regex pattern
```python
# Before
EMAIL_RE = r"[\w.]+@[\w.]+"

# After
EMAIL_RE = r"^[\w\.-]+@[\w\.-]+\.\w+$"  # RFC-5322 compliant
```
- File: `src/validators/email.py` line 8
- Risk: P1 (user-facing bug), 1 line
- Verification: `python -m pytest tests/validators/test_email.py -v`

## Testing Patterns

### Pattern 1: Unit test exists → run targeted test
```bash
# Python
python -m pytest tests/path/to/test_file.py::test_function -v

# JavaScript/TypeScript
npx vitest run tests/path/to/test_file.test.ts -t "test name"

# Go
go test -v -run TestFunction ./path/to/...

# Rust
cargo test test_function -- --nocapture
```

### Pattern 2: No unit test → syntax/type check only
```bash
# Python
python -c "import ast; ast.parse(open('target_file.py').read())"

# JavaScript
node --check target_file.js

# TypeScript
npx tsc --noEmit target_file.ts

# Go
go vet ./path/to/package

# Rust
cargo check --package crate_name
```

### Pattern 3: Integration-affecting change → run related test suite
```bash
# Change touches API handler → run API tests
python -m pytest tests/api/ -v -k "handler"

# Change touches auth → run auth tests
npx vitest run tests/auth/ -v

# Change touches DB layer → run integration tests
go test -v -tags=integration ./internal/db/...
```

## Edge Cases

### Edge Case 1: File has syntax error before edit
- **Signal**: Language check fails on READ step
- **Action**: STOP. Do not edit broken code. Escalate to deep-debugging with "pre-existing syntax error at line X"
- **Reason**: Editing broken code masks root cause; verification would always fail

### Edge Case 2: Change triggers cascade in same file (e.g., rename variable used 15 times)
- **Signal**: Edit affects >20 lines OR >3 references in same file
- **Action**: STOP. This exceeds atomic-edit scope. Delegate to plan-execution or refactoring-planner
- **Reason**: Single atomic edit should be ~1-5 lines; widespread renames need multi-step verification

### Edge Case 3: File is generated/derived (protobuf, GraphQL codegen, etc.)
- **Signal**: File header contains "DO NOT EDIT" or "Generated by"
- **Action**: STOP. Edit the source definition (.proto, .graphql, schema) instead
- **Reason**: Generated files are overwritten on next build; fix won't persist

### Edge Case 4: Change requires new import/dependency
- **Signal**: Edit adds `import X from 'new-package'` or `require('new-module')`
- **Action**: STOP. Adding deps violates "no new dependencies" rule. Delegate to plan-execution
- **Reason**: Dependency changes need lockfile updates, security review, CI validation

## Anti-Patterns (Expanded)

| Anti-Pattern | Why It Fails | Correct Approach |
|--------------|--------------|------------------|
| **Multi-file scope creep** | Violates single-file guard; creates untracked coupling | Stop at 1 file boundary; delegate multi-file to plan-execution |
| **Refactor adjacent code** | "While I'm here" edits compound risk; no test coverage for incidental changes | Only touch the exact lines needed for the fix |
| **Add dependencies** | Breaks "no new deps" rule; supply-chain risk; CI breaks | Use existing stdlib/approved deps; escalate if genuinely needed |
| **Skip verification** | Unverified edits = production bugs; defeats skill purpose | Always run language check + available tests |
| **Create files** | Wrong skill for file creation; no scaffold/templates | Delegate to code-generation skill |
| **Edit generated files** | Changes lost on regeneration; masks source-of-truth issue | Find and edit the source definition instead |
| **Large refactor in one edit** | Exceeds atomic-edit threshold; hard to verify/rollback | Break into multiple quick-executor calls or use refactoring-planner |

(End of file - total ~180 lines)