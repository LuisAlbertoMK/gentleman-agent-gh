---
name: quality-gate
description: >
  Pre-commit quality gate: TDD pass, secrets scan, conventional commits.
  Trigger: Before any "git commit", "git push", "gh pr create".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.1"
---

## When
Before `git commit` · `git push` · `gh pr create`

## Gates (ALL must pass)

### 1. TDD Gate — tests MUST pass
Detect runner: `go.mod`→`go test`, `package.json`→`npm/pnpm/yarn/bun test`, `Cargo.toml`→`cargo test`, `pyproject.toml`→`pytest`.
Run BEFORE staging. Fail → report file:line:err → STOP.

### 2. Secrets Scan — staged diff MUST be clean
Patterns checked:
```
(api[_-]?key|secret|token|password|private[_-]?key|-----BEGIN)
\b[A-Za-z0-9_-]{20,}\b
\b(?:AKIA|ASIA)[A-Z0-9]{16}\b
ghp_[A-Za-z0-9]{36,}\b
```
Match → BLOCK. Report file:line. NEVER commit secrets.

### 3. Conventional Commit — message MUST match
Regex: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`
Invalid → BLOCK + show format w/ example.

## Flow
```
git commit / push / pr create
  → 1. Test gate → fail? STOP
  → 2. Secrets scan → found? STOP
  → 3. Commit msg → invalid? STOP
  → ALLOW
```

## Edge Cases
| Case | Action |
|------|--------|
| Pre-existing test failures | Report, allow ONLY w/ user OK |
| Secret false positive | Allow w/ user acknowledgment |
| No test runner detected | Skip TDD gate, warn user |

## Resources
- **TDD patterns**: [sdd-apply/strict-tdd.md](../sdd-apply/strict-tdd.md)
