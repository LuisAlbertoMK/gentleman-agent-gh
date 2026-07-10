---
name: quality-gate
description: "Pre-commit gate — TDD + Pester tests pass, secrets scan, conventional commit, PSSA gate"
triggers: "Quality gate, pre-commit, PSSA gate"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "2.3"
  changelog: "2.3: added Pester Gate (step 5)"
  dependencies: [security-scanner]
  env:
    GENTLEMAN_AGENT_ROOT: "Repo root — all script paths are relative to this"
---
## Trigger: Before ANY `git commit`/`push`/`gh pr create` — ALL gates MUST pass
## 1. TDD Gate: Runner auto-detect (go.mod→`go test` · package.json→`npm/pnpm/bun test` · Cargo.toml→`cargo test` · pyproject→`pytest`). Fail→DO NOT commit. Report file:line:error.
## 2. Credential Scan: `git diff --cached` for credential patterns (api keys, passwords, credentials, private keys, long base64). Match→BLOCK.
## 3. Conventional Commit: `^(build|chore|ci|cycle|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`. Invalid→BLOCK+show format.
## 4. PSSA Gate: `$env:GENTLEMAN_AGENT_ROOT/scripts/pssa-gate.ps1 -Mode Check`. Auto-fixable→`-Mode Fix`. Manual MUST be 0 or user-approved.
## 5. Pester Gate (this repo only): `$env:GENTLEMAN_AGENT_ROOT/scripts/run-tests.ps1 -Quiet`. Fail→BLOCK unless user OKs pre-existing failures. Skip if `scripts/tests/` doesn't exist.
## Decision Tree
```
Tests fail?
  Pre-existing OK? → allow ONLY with user OK
  New failures? → fix or revert → re-run
Credential found?
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
`$secretsPattern = '(api[_-]?key|' + 'secret|' + 'token|-----BEGIN)'; git diff --cached | Select-String -Pattern $secretsPattern`
`"$env:GENTLEMAN_AGENT_ROOT/scripts/pssa-gate.ps1" -Mode Check`
`"$env:GENTLEMAN_AGENT_ROOT/scripts/run-tests.ps1" -Quiet`

## Refs
security-scanner · triple-verify · commit-crafter · ci-cd · code-review-agent

## Anti-Patterns
Skip gate for "small" changes · Commit without test · Bypass credential scan · Use non-conventional message · Gate after push
