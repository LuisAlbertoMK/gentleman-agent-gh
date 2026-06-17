# Phase Details

## Phase 0 — Load Review Profile
Before any gate, load the project's review profile from Engram:
```
mem_search("review-profile/{project}")
```
If profile exists: note previous 4R scores, pre-load sensitive files + patterns, focus on most common R failure.
If no profile: skip adaptive phase (will be created after Phase 2).

**Output to Phase 1**: `SENSITIVE_FILES` list + `FOCUS_R`.

## Phase 1 — Quality Gate
Load `quality-gate` skill. Tests MUST pass. Secrets scan MUST be clean. PSSA gate MUST pass.

**Output to Phase 2**: `GATE_RESULT=pass` + test evidence.

## Phase 2 — 4R Code Review
Load `code-review-agent` (+ `judgment-day` for high-risk). Score by 4R.

**Decision**:
- All 4R ≥ 6 → PASS → Phase 3
- Any 4R 4-5 → FAIL → STOP. User can override with confirmation (`review-override`).
- Any 4R < 4 → BLOCKED → STOP. Cannot override.

**After**: Save profile to Engram: `mem_save(topic_key: "review-profile/{project}", type: "pattern", content: "...")`.

**Output to Phase 3**: `REVIEW_PASSED=true` + key findings (informs commit scope).

## Phase 3 — Commit Craft
Load `commit-crafter`. Craft conventional commit from `git diff --cached` + 4R findings.
Scope injected from review: `fix` if Reliability issue, `refactor` if Readability, etc.

**Output**: Conventional commit message + 4R-informed scope.
