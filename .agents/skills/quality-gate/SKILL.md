---
name: quality-gate
description: "Pre-commit gate — TDD tests pass, secrets scan, conventional commit, PSSA gate"
triggers: "Quality gate, pre-commit, PSSA gate"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "2.1"
  changelog: "2.1: karpathy compress"
---
## Trigger: Before ANY `git commit`/`push`/`gh pr create` — ALL gates MUST pass
## 1. TDD Gate: Runner auto-detect (go.mod→`go test` · package.json→`npm/pnpm/bun test` · Cargo.toml→`cargo test` · pyproject→`pytest`). Fail→DO NOT commit. Report file:line:error.
## 2. Secrets Scan: `git diff --cached` for (api_key|secret|token|password|credential|private_key|-----BEGIN) + {20,}+ · AKIA/ASIA keys · ghp_ tokens. Match→BLOCK.
## 3. Conventional Commit: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`. Invalid→BLOCK+show format.
## 4. PSSA Gate: `scripts/pssa-gate.ps1 -Mode Check`. Auto-fixable→`-Mode Fix`. Manual MUST be 0 or user-approved.
## Decision Tree
```
Tests fail?
  Pre-existing OK? → allow ONLY with user OK
  New failures? → fix or revert → re-run
Secret found?
  False positive? → allow with user OK
  Real? → remove → env/vault → re-scan
Commit invalid?
  Show: type(scope): desc
PSSA manual?
  Auto-fixable? → -Mode Fix → re-check
  Remaining? → review+fix → re-check
```
## Commands
`go test ./...` · `npm/pnpm/yarn test` · `cargo test` · `pytest`
`git diff --cached | Select-String -Pattern '(api[_-]?key|secret|token|-----BEGIN)'`
`scripts/pssa-gate.ps1 -Mode Check`
