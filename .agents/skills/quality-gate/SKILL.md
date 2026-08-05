---
name: quality-gate
description: "Pre-commit gate — TDD + Pester tests pass, secrets scan, conventional commit, PSSA gate"
triggers: "Quality gate, pre-commit, PSSA gate"
---

## When to Use
Pre-commit gate — TDD + Pester tests pass, secrets scan, con

**Trigger**: Before ANY `git commit`/`push`/`gh pr create`—ALL gates MUST pass.
**Portable**: Steps 4/5/6 depend on repo scripts. Missing→`[SKIP]`+warn, continue.
## 1. TDD Gate
Auto-detect: `go.mod`→`go test`|`package.json`→`npm/pnpm/bun test`|`Cargo.toml`→`cargo test`|`pyproject`→`pytest`. No runner→`[SKIP] TDD:no test runner detected`. Fail→NO commit. file:line:error.
## 2. Credential Scan
`git diff --cached` for api keys/passwords/credentials/private keys/long base64. Match→BLOCK.

## 3. Conventional Commit
`^(build|chore|ci|cycle|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`. Invalid→BLOCK+show.
## 4. PSSA Gate
If `$env:GENTLEMAN_AGENT_ROOT/scripts/pssa-gate.ps1` exists→`-Mode Check`. Auto-fix→`-Mode Fix`. Manual=0 or user-ok. Else→`[SKIP] PSSA:not found`.

## 5. Pester Gate
If `$env:GENTLEMAN_AGENT_ROOT/scripts/run-tests.ps1` AND `scripts/tests/` exist→`-Quiet`. Fail→BLOCK unless pre-existing user-ok. Else→`[SKIP] Pester:not found`.

## 6. Adversarial Breaker (`!ship`/`!listo` ONLY—skip on `!fast`/`!check`/`!draft`/plain)
Not available→`[SKIP] Breaker:not loaded`→continue.
Load protocol. Bundle:`git diff --cached`+files+fixer claims. Zone from `review-rules.jsonc`(ROJA always, AMARILLA if auth/storage/API). No file→ALL ROJA.
Launch subagent. Parse 4-field min3 attacks.
APPROVED→push|FIX→R2(new diff). R2✅→push. R2❌→STOP|BLOCK→STOP escalate|ESCALATE→STOP partial.
Max2 rounds. Record Engram per breaker schema.

## Decision Tree
Tests:no runner→SKIP|pre-exist→user-ok|new→fix. Cred:FP→user-ok|real→vault. Commit→type(scope):desc. PSSA missing→SKIP|auto-fix→-Mode Fix. Pester missing→SKIP.
Breaker:missing→SKIP push|✅→push|🔧→R2|🚫→STOP|⚠→STOP

## Commands
`go test ./...`·`npm/pnpm/yarn test`·`cargo test`·`pytest`
`$secretsPattern='(api[_-]?key|secret|token|-----BEGIN)'; git diff --cached|Select-String -Pattern $secretsPattern`
`"$env:GENTLEMAN_AGENT_ROOT/scripts/pssa-gate.ps1" -Mode Check`
`"$env:GENTLEMAN_AGENT_ROOT/scripts/run-tests.ps1" -Quiet` — Note: if *.Tests.ps1 files are staged, the pre-commit hook re-runs the staged subset (now parallel) — intentional double coverage; commit tests separately.

## Refs
security-scanner·triple-verify·commit-crafter·ci-cd·code-review-agent·adversarial-breaker

## Anti-Patterns
Skip "small" changes·Commit no test·Bypass credential·Non-conventional·Gate after push·Skip breaker on !ship·Breaker before quality-gate(gate FIRST)·Breaker on !fast(only !ship)·Fail script missing(use [SKIP])·[SKIP]≠[PASS]
