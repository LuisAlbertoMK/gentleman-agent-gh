# quality-gate — Reference Materials

> **Externalized from** .agents/skills/quality-gate/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples

### Example 1: Full gate pass (Go project)
```bash
# Stage changes
git add src/auth/token.go
# Run quality gate
go test ./...                                    # ✓ TDD gate
git diff --cached | Select-String -Pattern '(api[_-]?key|secret|token|-----BEGIN)'  # ✓ no secrets
git commit -m "feat(auth): add JWT refresh rotation"  # ✓ conventional
"$env:GENTLEMAN_AGENT_ROOT/scripts/pssa-gate.ps1" -Mode Check  # ✓ PSSA
# No Pester → [SKIP]
# No breaker for plain commit → continue
git push
```

### Example 2: Secrets scan blocks commit
```bash
git add .env.local
git commit -m "chore: add local config"
# BLOCKED:
# [CREDENTIAL] Match in .env.local:2: API_KEY: sk_live_FAKE_EXAMPLE_DO_NOT_USE...
# Fix: git restore --staged .env.local && echo ".env.local" >> .gitignore
```

### Example 3: PSSA auto-fix on style violations
```bash
git add src/api/handler.go
"$env:GENTLEMAN_AGENT_ROOT/scripts/pssa-gate.ps1" -Mode Check
# [PSSA] 3 issues: trailing whitespace, unused import, line >120
"$env:GENTLEMAN_AGENT_ROOT/scripts/pssa-gate.ps1" -Mode Fix
# Auto-fixed 3 issues. Re-stage and retry.
git add src/api/handler.go
git commit -m "fix(api): handler cleanup"
```

### Example 4: Adversarial breaker on !ship (ROJA zone)
```bash
git add src/payment/processor.ts src/payment/types.ts
git commit -m "feat(payment): add Stripe webhook handler"
# !ship triggers breaker
# Breaker subagent launched with diff + review-rules.jsonc (ROJA: payment)
# Round 1: 3 attacks found (idempotency missing, webhook sig verify, amount validation)
# → FIX required. Developer applies fixes.
# Round 2: 0 attacks → APPROVED → push allowed
```

### Example 5: Multi-repo monorepo (partial SKIP)
```bash
# Repo has: apps/web (npm), apps/api (go), libs/shared (no tests)
git add apps/web/src/Button.tsx apps/api/internal/auth.go
# TDD: npm test (web) ✓ | go test ./... (api) ✓ | libs/shared → [SKIP] TDD:no test runner detected
# Credential scan: clean
# Conventional: feat(web): add Button variant
# PSSA: exists → check
# Pester: not found → [SKIP]
# Breaker: !ship → runs on staged files only
```

## Testing Patterns

### Pattern 1: Gate simulation (dry-run)
```bash
# Test all gates without committing
DRY_RUN=1 bash -c '
  go test ./... 2>&1 | head -20
  git diff --cached | Select-String -Pattern "api[_-]?key|secret|token"
  echo "Commit msg:" && cat .git/COMMIT_EDITMSG 2>/dev/null || echo "none"
  "$env:GENTLEMAN_AGENT_ROOT/scripts/pssa-gate.ps1" -Mode Check 2>&1 | head -10
'
# All clean → safe to commit
```

### Pattern 2: Selective gate (path-scoped)
```bash
# Run TDD only on staged packages
git diff --cached --name-only | grep -E '\.go$' | xargs -I{} dirname {} | sort -u | xargs -I{} go test ./{}...
# Useful for monorepos: only test what changed
```

### Pattern 3: Breaker simulation (local)
```bash
# Simulate breaker locally before !ship
git diff --cached > /tmp/staged.diff
cat /tmp/staged.diff | python -c "
import sys, json
diff = sys.stdin.read()
# Load review-rules.jsonc zones
# Run breaker logic locally (mock)
print('Simulated attacks:', 0 if 'TODO' not in diff else 1)
"
# Zero attacks → safe to !ship
```

## Edge Cases

### Edge Case 1: Pre-existing test failures (flaky baseline)
```bash
# Main has failing tests. New commit unrelated.
# Gate: [SKIP] TDD:pre-existing failures detected → user-ok required
# Document: mem_save "Flaky baseline in main: UserList.test.ts" type:discovery
# Fix flakiness separately; do not block unrelated work
```

### Edge Case 2: False positive secrets (test fixtures)
```bash
git add tests/fixtures/api-responses.json
# Contains: "token": "test_fake_token_123" → MATCH
# Resolution: user-ok with evidence "test fixture, not real secret"
# Better: add to .secretsignore or use env var in fixtures
```

### Edge Case 3: PSSA missing in CI but present locally
```bash
# Local: pssa-gate.ps1 exists → runs
# CI: script not copied → [SKIP] PSSA:not found
# Fix: add scripts/ to .gitignore? No — commit scripts/ or use portable alternative
# Portable: npx @gentleman/pssa-gate (if published)
```

### Edge Case 4: Breaker timeout / unavailable
```bash
# !ship but breaker skill not loaded / times out
# Gate: [SKIP] Breaker:not loaded → continue with warning
# Log: mem_save "Breaker unavailable on !ship — pushed without review" type:bugfix
# Never silently skip on !ship without recording
```

### Edge Case 5: Mixed conventional + breaking change
```bash
git commit -m "feat(auth)!: drop legacy session support"
# Valid: "!" after scope = breaking change
# Pattern accepts: type(scope)!: desc
# Invalid: "feat!: ..." (no scope) — use "feat(core)!: ..."
```

## Anti-Patterns
Skip "small" changes·Commit no test·Bypass credential·Non-conventional·Gate after push·Skip breaker on !ship·Breaker before quality-gate(gate FIRST)·Breaker on !fast(only !ship)·Fail script missing(use [SKIP])·[SKIP]≠[PASS]

### Anti-Pattern 6: Chaining gates instead of parallel
```bash
# SLOW: Sequential (each waits for previous)
go test ./... && npm test && cargo test

# FAST: Parallel (all at once)
(go test ./... &) && (npm test &) && (cargo test &) && wait
# Quality gate should orchestrate parallel execution
```

### Anti-Pattern 7: Using quality-gate as CI substitute
```bash
# WRONG: Local gate passes → assume CI will pass
# CI runs: matrix (OS, versions), coverage thresholds, e2e, security scans
# Local gate: fast feedback ONLY (unit tests, lint, commit format)
# Always: gh pr checks after push — never skip CI review
```

(End of file)

## Externalized Sections (ADR-007 compression)
## Commands
`go test ./...`·`npm/pnpm/yarn test`·`cargo test`·`pytest`
`$secretsPattern='(api[_-]?key|secret|token|-----BEGIN)'; git diff --cached|Select-String -Pattern $secretsPattern`
`"$env:GENTLEMAN_AGENT_ROOT/scripts/pssa-gate.ps1" -Mode Check`
`"$env:GENTLEMAN_AGENT_ROOT/scripts/run-tests.ps1" -Quiet` — Note: if *.Tests.ps1 files are staged, the pre-commit hook re-runs the staged subset (now parallel) — intentional double coverage; commit tests separately.


## Decision Tree
Tests:no runner→SKIP|pre-exist→user-ok|new→fix. Cred:FP→user-ok|real→vault. Commit→type(scope):desc. PSSA missing→SKIP|auto-fix→-Mode Fix. Pester missing→SKIP.
Breaker:missing→SKIP push|✅→push|🔧→R2|🚫→STOP|⚠→STOP partial


