---
name: quality-gate
description: "Pre-commit quality gate -- TDD tests pass, secrets scan, conventional commit validation, and PSSA gate before commit/push/PR"
triggers: "Quality gate, pre-commit, PSSA gate"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "2.0"
---

## Trigger

Before any "git commit", "git push", "gh pr create" -- MUST run ALL gates.

## Gates (ALL must pass)

### 1. TDD Gate -- tests MUST pass
Detect runner: go.mod -> `go test`, package.json -> `npm/pnpm/yarn/bun test`, Cargo.toml -> `cargo test`, pyproject.toml -> `pytest`.
Fail -> DO NOT commit. Report file:line:error. Fix or ask user.

### 2. Secrets Scan -- diff MUST be clean
Scan staged diff: `git diff --cached` for patterns:
```
(api[_-]?key|secret|token|password|credential|private[_-]?key|-----BEGIN)\b
[A-Za-z0-9_-]{20,}\b
\b(?:AKIA|ASIA)[A-Z0-9]{16}\b
ghp_[A-Za-z0-9]{36,}\b
```
Match -> BLOCK commit. Report file:line. NEVER commit secrets.

### 3. Conventional Commit -- message MUST be valid
Regex: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`
Invalid -> BLOCK. Show format + example.

### 4. PSSA Gate -- PowerShell scripts MUST pass
Run `scripts/pssa-gate.ps1 -Mode Check` before commit.
- Auto-fixable (use `-Mode Fix`): PSUseBOMForUnicodeEncodedFile, PSAvoidDefaultValueSwitchParameter
- Tracked/info: PSAvoidUsingWriteHost (intentional for colored output)
- Manual review remainder: MUST be 0 or user-approved
- Fail -> DO NOT commit. Report rule counts and manual items.

## Decision Tree
```
Tests fail?
  +-- Pre-existing (not your changes)? -> report, allow ONLY with user OK
  +-- New failures? -> fix or revert -> re-run
Secret found?
  +-- False positive (test data)? -> allow with user OK
  +-- Real secret? -> remove from code -> use env/vault -> re-scan
Commit invalid?
  +-- Show: feat(scope): desc | fix(scope): desc | chore: desc
PSSA violations (manual review)?
  +-- All auto-fixable? -> run `scripts/pssa-gate.ps1 -Mode Fix` -> re-run Check
  +-- Manual items remain? -> review and fix -> re-run Check
```

## Commands
```bash
go test ./...                    # Go
npm test / pnpm test / yarn test # Node
cargo test                       # Rust
pytest                           # Python
git diff --cached | Select-String -Pattern '(api[_-]?key|secret|token|-----BEGIN)'
echo "{message}" | Select-String -Pattern '^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+'
scripts/pssa-gate.ps1 -Mode Check  # PowerShell Script Analyzer
```
