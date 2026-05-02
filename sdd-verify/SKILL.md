---
name: sdd-verify
description: >
  Validate implementation matches specs, design, and tasks. Quality gate.
  Trigger: Orchestrator launches verification of a completed change.
license: MIT
metadata:
  author: gentleman-programming
  version: "3.0"
---

## Purpose
Quality gate. Prove — with execution evidence — that implementation is complete, correct, and spec-compliant. Static analysis NOT enough.

## Persistence Contract
- **engram**: Read all artifacts from engram. Save `sdd/{change}/verify-report`
- **openspec**: Save to `openspec/changes/{change}/verify-report.md`
- **hybrid**: BOTH
- **none**: Inline report only

## Steps

### 1: Load Skills
Per `_shared/sdd-phase-common.md` Section A.

### 2: Resolve TDD Mode
```
Cached testing capabilities → strict_tdd?
├─ true + runner → STRICT TDD VERIFY (load strict-tdd-verify.md)
└─ false/no runner → STANDARD (skip TDD checks, zero tokens)
```
Orchestrator says "STRICT TDD MODE IS ACTIVE" → authoritative, proceed directly.

### 3: Completeness
Count tasks: total, completed [x], incomplete [ ]. CRITICAL if core incomplete, WARNING if cleanup incomplete.

### 4: Correctness (Static)
For each spec requirement/scenario, search codebase for structural evidence. CRITICAL if requirement missing, WARNING if partial.

### 5: Coherence (Design)
For each design decision: was chosen approach used? Do file changes match table? WARNING if deviation (may be valid).

### 5a: TDD Compliance (Strict TDD only)
Skip if not active. Follow `strict-tdd-verify.md` Step 5a.

### 6: Testing
**6a: Static** — Test files exist? Cover happy paths, edge cases, errors? WARNING if scenarios lack tests.

**6b: Run Tests** — Detect runner (cached capabilities → config → package.json → fallback). Execute. Capture: total, passed, failed, skipped, exit code. CRITICAL if exit != 0.

**6c: Build/Type Check** — Detect (cached → config → package.json). Execute. CRITICAL if fails. WARNING if type errors.

**6d: Coverage** — If tool available: run, parse. Strict TDD → per-file coverage + uncovered ranges. Standard → total only. WARNING if below threshold.

**6e: Quality Metrics (Strict TDD only)** — Skip if not active. Follow `strict-tdd-verify.md` Step 5e.

### 7: Spec Compliance Matrix (Behavioral)
Cross-reference EVERY spec scenario vs test results from Step 6b:

| Status | Meaning |
|--------|---------|
| ✅ COMPLIANT | Test exists AND passed |
| ❌ FAILING | Test exists BUT failed → CRITICAL |
| ❌ UNTESTED | No test found → CRITICAL |
| ⚠️ PARTIAL | Test covers only part → WARNING |

Scenario is COMPLIANT only when a test proves behavior at runtime. Code existing ≠ sufficient.

### 7a: Test Layer Validation (Strict TDD only)
Skip if not active. Follow `strict-tdd-verify.md` (Step 5 Expanded).

### 8: Persist Report
Per `_shared/sdd-phase-common.md` Section C. artifact: `verify-report`, topic_key: `sdd/{change}/verify-report`.

### 9: Return Summary
```markdown
## Verification Report
**Change**: {name} | **Mode**: {Strict TDD | Standard}

### Completeness
Tasks: {total} total | {completed} done | {incomplete} pending
{List incomplete}

### Build & Tests
Build: ✅/❌
Tests: ✅ {N} passed / ❌ {N} failed / ⚠️ {N} skipped
Coverage: {N}% → ✅/⚠️/➖

{TDD tables if Strict TDD active}

### Spec Compliance Matrix
| Requirement | Scenario | Test | Result |
| {REQ} | {Scenario} | `{file} > {test}` | ✅ COMPLIANT |
| {REQ} | {Scenario} | (none) | ❌ UNTESTED |

**Compliance**: {N}/{total} scenarios

### Correctness (Static)
| Requirement | Status | Notes |

### Coherence (Design)
| Decision | Followed? | Notes |

### Issues
CRITICAL: {list or None}
WARNING: {list or None}
SUGGESTION: {list or None}

### Verdict
{PASS / PASS WITH WARNINGS / FAIL}
{One-line summary}
```

## Rules
- Read actual code, don't trust summaries
- Execute tests — static ≠ verification
- COMPLIANT only when test PASSED
- Specs first (behavioral), Design second (structural)
- CRITICAL = must fix pre-archive | WARNING = should fix | SUGGESTION = improvements
- DO NOT fix — only report
- openspec: ALWAYS save verify-report.md
- Strict TDD: load + execute ALL strict-tdd-verify.md steps
- NOT Strict TDD: NEVER load strict-tdd-verify.md
- Use cached testing capabilities
- Return envelope per `_shared/sdd-phase-common.md` Section D.
