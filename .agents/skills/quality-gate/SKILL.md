---
name: quality-gate
description: "Pre-commit gate — TDD + Pester tests pass, secrets scan, conventional commit, PSSA gate"
triggers: "Quality gate, pre-commit, PSSA gate"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2950
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

## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "saltar adversarial-breaker en !ship" | ROJA/AMARILLA sin breaker + push | §6 breaker gate → APPROVED o STOP según zone |
| "ignorar gate PSSA faltante" | [SKIP] PSSA tratado como pass silencioso | §4 pssa-gate.ps1 existe→Check/Fix else [SKIP]+warn |
| "diferir secrets medios" | MEDIUM pospuesto, HIGH sin fix previo | Rule2: CRITICAL+HIGH fix now, MEDIUM→suggest now |

## Red Flags
- Doing work without checking output format → STOP, re-read skill
- Second occurrence of same rationalization → force RED zone

## Verification
- Output matches skill ## Output contract + file:line citaton
- cross-ref-check.ps1 → SKILL.md OK
## Refs
security-scanner·triple-verify·commit-crafter·ci-cd·code-review-agent·adversarial-breaker·auto-metrics·external-auditor·immune-system
---

docs/skills/quality-gate/reference.md
---

