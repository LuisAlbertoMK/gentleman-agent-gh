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

## Phase 2a — Zone Check
Before reviewing, determine the zone for changed files via `review-rules.jsonc → zones`:
- **ROJA** (high-risk: src/, scripts/, *.ps1, *.go, etc.) → Phase 2b — JD dual review
- **AMARILLA** (medium-risk: *.css, *.json, *.ts, etc.) → Phase 2c — single 4R review
- **VERDE** (low-risk: *.md, *.txt, images) → skip review, go to Phase 3

Zone is determined by first pattern match against each changed file path.

## Phase 2b — JD Dual Review (ROJA only)
Load `judgment-day` orchestrator. It resolves 2 profiles via `jd_profile_selector` (ordered array), launches 2 parallel `code-review-agent` instances with different profile lenses, then synthesizes verdicts. See `judgment-day/SKILL.md` for protocol details.

**Output to Phase 3**: `JD_PASSED=true` + confirmed findings + calibration result.

## Phase 2c — 4R Code Review (AMARILLA)
Load `code-review-agent`. Score by 4R.

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
