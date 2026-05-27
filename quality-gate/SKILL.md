---
name: quality-gate
description: >
  Pre-commit quality gate: TDD pass, secrets scan, conventional commits.
  Trigger: Before any "git commit", "git push", "gh pr create".
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When
Before `git commit` · Before `git push` · Before `gh pr create`
Auto-trigger: the agent MUST run this skill BEFORE any of these commands.

## Critical Patterns

### 1. TDD Gate — tests MUST pass before commit
Detect test runner from project files (go.mod → `go test`, package.json → `npm/pnpm/yarn/bun test`, Cargo.toml → `cargo test`).
Run the test command BEFORE staging changes. If any test fails:
- DO NOT commit
- Report: file, line, error message
- Suggest fix or ask user

### 2. Secrets Scan — diff MUST be clean
Before commit, scan the staged diff for known secret patterns:
```
(api[_-]?key|api[_-]?secret|secret|token|password|passwd|pwd|credential|private[_-]?key|-----BEGIN)
\b[A-Za-z0-9_-]{20,}\b    # base64-like long strings
\b(?:AKIA|ASIA)[A-Z0-9]{16}\b  # AWS access keys
ghp_[A-Za-z0-9]{36,}\b         # GitHub tokens
```
If any match → BLOCK commit. Report the file and line. NEVER commit secrets.

### 3. Conventional Commit — message MUST be valid
Validate commit message against: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`
If invalid → BLOCK commit. Show the correct format with an example.

## Workflow
```
User or agent: "git commit -m ..."
  ↓
[quality-gate TRIGGERED]
  ↓
├── 1. TEST GATE
│   ├── Detect test runner (go.mod / package.json / Cargo.toml / pyproject.toml)
│   ├── Run: {test_command}
│   ├── ✅ Pass → continue
│   └── ❌ Fail → report errors → STOP (no commit)
│
├── 2. SECRETS SCAN
│   ├── Read `git diff --cached` (staged changes)
│   ├── Scan for secret patterns line by line
│   ├── ✅ Clean → continue
│   └── ❌ Found → list files + lines → STOP (no commit)
│
├── 3. COMMIT MESSAGE VALIDATION
│   ├── Parse the proposed commit message
│   ├── Match against conventional commit regex
│   ├── ✅ Valid → continue
│   └── ❌ Invalid → show format + example → STOP
│
└── All gates passed → ALLOW commit ✅
```

## Commands
```bash
# Test gate (auto-detect by project type)
go test ./...                    # Go
npm test / pnpm test / yarn test # Node/JS
cargo test                       # Rust
pytest                           # Python

# Secrets scan
git diff --cached | grep -Ein '(api[_-]?key|secret|token|-----BEGIN)'

# Commit message validation
echo "{message}" | Select-String -Pattern '^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+'
```

## Decision Tree
```
Tests fail?
├── Pre-existing failures (not from your changes)?
│   └── Report as "pre-existing", allow commit ONLY with user's explicit OK
└── New failures from your changes?
    └── Fix or revert → re-run tests

Secret found?
├── False positive (test data, example key)?
│   └── Allow with explicit user acknowledgment
└── Real secret?
    └── Remove from code → use env/ vault → re-scan

Commit message invalid?
└── Show correct format:
    feat(scope): description
    fix(scope): description
    chore: description
```

## Resources
- **TDD reference**: [sdd-apply/strict-tdd.md](../sdd-apply/strict-tdd.md) for full TDD cycle patterns
