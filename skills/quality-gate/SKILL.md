---
name: quality-gate
description: >
  quality-gate skill
triggers: "Quality gate, pre-commit"
  Trigger: Before any "git commit", "git push", "gh pr create".
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.1"
---

## When
Before `git commit` · `git push` · `gh pr create` — MUST run BEFORE these commands.

## Gates (ALL must pass)

### 1. TDD Gate — tests MUST pass
Detect runner: go.mod→`go test`, package.json→`npm/pnpm/yarn/bun test`, Cargo.toml→`cargo test`, pyproject.toml→`pytest`.
Fail → DO NOT commit. Report file:line:error. Fix or ask user.

### 2. Secrets Scan — diff MUST be clean
Scan staged diff: `git diff --cached` for patterns:
```
(api[_-]?key|secret|token|password|credential|private[_-]?key|-----BEGIN)
\b[A-Za-z0-9_-]{20,}\b
\b(?:AKIA|ASIA)[A-Z0-9]{16}\b
ghp_[A-Za-z0-9]{36,}\b
```
Match → BLOCK commit. Report file:line. NEVER commit secrets.

### 3. Conventional Commit — message MUST be valid
Regex: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`
Invalid → BLOCK. Show format + example.

## Decision Tree
```
Tests fail?
├── Pre-existing (not your changes)? → report, allow ONLY with user OK
└── New failures? → fix or revert → re-run

Secret found?
├── False positive (test data)? → allow with user OK
└── Real secret? → remove from code → use env/vault → re-scan

Commit invalid? → Show: feat(scope): desc | fix(scope): desc | chore: desc
```

## Commands
```bash
go test ./...                    # Go
npm test / pnpm test / yarn test # Node
cargo test                       # Rust
pytest                           # Python
git diff --cached | Select-String -Pattern '(api[_-]?key|secret|token|-----BEGIN)'
echo "{message}" | Select-String -Pattern '^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+'
```

