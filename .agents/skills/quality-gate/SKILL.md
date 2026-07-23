---
name: quality-gate
description: "Pre-commit gate — TDD + Pester tests pass, secrets scan, conventional commit, PSSA gate"
triggers: "Quality gate, pre-commit, PSSA gate"
license: Apache-2.0
metadata:
  tags: [engineering]
  author: gentleman-vMK
  version: "3.0"
  changelog: "3.0: added Adversarial Breaker (step 6, !ship only)"
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
## 6. Adversarial Breaker (**`!ship`/`!listo` ONLY** — skip on `!fast`, `!check`, `!draft`, plain commits):
   - Load `adversarial-breaker` skill protocol
   - Gather artifact bundle: `git diff --cached`, changed files list, fixer claims from session
   - Zone check: resolve zone from `review-rules.jsonc` (ROJA always breaker, AMARILLA if touches auth/storage/API)
   - Launch breaker subagent with full briefing + artifact bundle
   - Parse breaker output (4-field contract, min 3 attacks)
   - Verdict path:
     - APPROVED → continue to push
     - FIX → Round 2 (new diff + delta context). Round 2 APPROVED → continue. Round 2 FIX/BLOCK → STOP
     - BLOCK → STOP, escalate to user with chain evidence
     - ESCALATE → STOP, partial results to user
   - Max 2 rounds total. Round 2 breaks → ESCALATE to human.
   - Record breaker result to Engram per adversarial-breaker recording schema.
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
!ship pipeline? (step 6)
  Breaker APPROVED → push
  Breaker FIX → Round 2 → APPROVED? push : STOP
  Breaker BLOCK → STOP, escalate to user
  Breaker ESCALATE → STOP, show partial results
```
## Commands
`go test ./...` · `npm/pnpm/yarn test` · `cargo test` · `pytest`
`$secretsPattern = '(api[_-]?key|' + 'secret|' + 'token|-----BEGIN)'; git diff --cached | Select-String -Pattern $secretsPattern`
`"$env:GENTLEMAN_AGENT_ROOT/scripts/pssa-gate.ps1" -Mode Check`
`"$env:GENTLEMAN_AGENT_ROOT/scripts/run-tests.ps1" -Quiet`

## Refs
security-scanner · triple-verify · commit-crafter · ci-cd · code-review-agent · adversarial-breaker

## Anti-Patterns
Skip gate for "small" changes · Commit without test · Bypass credential scan · Use non-conventional message · Gate after push · Skip breaker on !ship · Breaker before quality-gate (gate ALWAYS first) · Breaker runs on !fast (break only on !ship)
