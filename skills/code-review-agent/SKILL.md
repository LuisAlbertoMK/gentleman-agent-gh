---
name: code-review-agent
description: >
  code-review-agent skill
triggers: "Code review, CR, revisar código, criticar"
  Structured code review with checklist, acceptance criteria, and evidence gates.
  Trigger: "code review", "revisar código", "review this", "cr", "criticar", "code-review".
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## When
User asks for code review. Before committing on complex changes.

## Critical Patterns

### Review dimensions (score 1-10 each)

| Dimension | What it checks | Weight |
|-----------|---------------|--------|
| **Correctness** | Logic, edge cases, off-by-one, nil safety | 30% |
| **Architecture** | Coupling, cohesion, abstraction level | 20% |
| **Performance** | N+1, unnecessary allocs, hot paths | 15% |
| **Security** | Injection, secrets, input validation | 15% |
| **Readability** | Naming, comments, structure, complexity | 10% |
| **Testability** | Mock boundaries, test coverage gaps | 10% |

### Verdicts
- ✅ **APPROVED** — all dims ≥ 7, no blockers
- 🔶 **CHANGES REQUESTED** — any dim < 5, or 1-2 specific issues
- ❌ **REJECTED** — correctness/security < 4, or fundamental design flaw

### Workflow
```
Request → read diff/file → evaluate 6 dims → assign scores → verdict → actionable fix
```

### Output format
```
## CR: {file/summary}

**Score**: X.X/10
**Verdict**: ✅ / 🔶 / ❌

| Dimension | Score | Issues |
|-----------|-------|--------|
| Correctness | 8/10 | Edge case: empty input |
| Architecture | 7/10 | Handler >200 lines, extract validation |
| ... | | |

### Fixes
1. `file.go:42` — handle nil map before range
2. `file.go:88` — extract `validateInput()` to separate fn

### Evidence
- `go test ./...` — 142/142 pass
- `go vet ./...` — no warnings
```

### Rules
1. Always score BEFORE suggesting fix. No anchoring bias.
2. If score <5: explain WHY, not "needs work"
3. Each fix: line ref + what + why
4. If no issues: say "Clean. Approved." No false positives.
5. Evidence required for correctness + testability (run tests)

### Anti-patterns
| ❌ | ✅ |
|----|-----|
| Vague "looks good" | Score + evidence |
| Only praise, no critique | Balance: what's good + what needs work |
| Nitpicking style | Only substantive concerns |

