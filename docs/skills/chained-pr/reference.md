# chained-pr — Reference Materials

> **Externalized from** .agents/skills/chained-pr/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples (4-5)

### Example 1: Stacked PRs to Main — Auth Refactor (600 lines)
**Scenario**: Split `auth/` refactor into 3 independent slices landing to `main`.
**PR #1** (`auth/contracts`): Interfaces + types only (120 lines). No implementation.
**PR #2** (`auth/jwt-provider`): JWT token provider using PR #1 contracts (180 lines). Tests included.
**PR #3** (`auth/middleware`): Express middleware wiring JWT provider (200 lines). Integration tests.
**Dependency**: #2 → #1, #3 → #2. Each lands independently; revert any PR without cascading.

### Example 2: Feature Branch Chain — Payment Integration (1,200 lines)
**Scenario**: Stripe payment feature requiring DB migration + API + UI before merge.
**Tracker PR** (`feature/payments`): Draft/no-merge, empty commit, CI disabled.
**PR #1** (`payments/db-migration`): Migration + models (250 lines). Targets tracker.
**PR #2** (`payments/api`): REST endpoints + webhooks (400 lines). Targets PR #1 branch.
**PR #3** (`payments/ui`): Checkout page + components (350 lines). Targets PR #2 branch.
**Dependency**: Tracker ← #1 ← #2 ← #3. Only tracker merges to main after all 3 approved.

### Example 3: Stacked PRs — Design System Token Migration (800 lines)
**Scenario**: Migrate hardcoded colors to design tokens across 15 components.
**PR #1** (`tokens/core`): Token definitions + ThemeProvider (100 lines).
**PR #2** (`tokens/button`): Button + ButtonGroup migration (180 lines). Tests snapshots.
**PR #3** (`tokens/inputs`): Input, Select, Textarea migration (220 lines).
**PR #4** (`tokens/feedback`): Alert, Toast, Modal migration (300 lines).
**Strategy**: All stacked to `main`; each component slice independently revertible.

### Example 4: Stacked PRs — API Versioning (550 lines)
**Scenario**: Add v2 API while keeping v1; shared middleware extraction.
**PR #1** (`api/shared-middleware`): Extract auth/rate-limit to shared pkg (150 lines).
**PR #2** (`api/v2-contracts`): OpenAPI v2 spec + types (120 lines).
**PR #3** (`api/v2-impl`): v2 controllers using shared middleware (280 lines).
**Boundary**: PR #1 is prerequisite; #2/#3 can be reviewed in parallel after #1 merges.

### Example 5: Feature Branch Chain — Multi-Tenant Schema (2,000 lines)
**Scenario**: Tenant isolation requiring migration + RLS policies + API guards + admin UI.
**Tracker**: `feature/multi-tenant` (draft).
**PR #1** (`tenant/migration`): Schema + RLS (400 lines).
**PR #2** (`tenant/api-guards`): Middleware + context (350 lines).
**PR #3** (`tenant/admin-ui`): Tenant switcher + dashboard (500 lines).
**PR #4** (`tenant/onboarding`): Invite flow + provisioning (450 lines).
**Integration gate**: Only tracker merges; children squashed into tracker on final merge.

---

## Testing Patterns (3)

### Pattern 1: Diff Isolation Verification
**Goal**: Ensure each PR diff contains ONLY its work unit.
```bash
# In PR branch, compare against parent branch
git diff parent-branch..HEAD --stat
# Verify: no files from other work units appear
# Verify: test files co-located with implementation changes
```
**Assertion**: `git diff parent-branch..HEAD --name-only` matches expected file list exactly.

### Pattern 2: Independent CI Pass
**Goal**: Each PR passes full CI without siblings.
```yaml
# .github/workflows/pr-chain.yml
jobs:
  test-pr-1:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm test -- --testPathPattern="auth/contracts"
  test-pr-2:
    needs: test-pr-1
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { ref: ${{ github.event.pull_request.head.ref }} }
      - run: npm ci && npm test -- --testPathPattern="auth/jwt-provider"
```
**Assertion**: Each job passes on its branch alone; no cross-PR test dependencies.

### Pattern 3: Rollback Simulation
**Goal**: Verify reverting any PR doesn't break main.
```bash
# Simulate: merge PR #2, then revert
git checkout main && git merge pr-2-branch --no-ff
git revert -m 1 HEAD  # revert merge commit
npm test  # must pass
```
**Assertion**: Main branch tests pass after reverting any single PR in the chain.

---

## Edge Cases (4)

### Edge Case 1: Generated Code Pollution
**Situation**: `prisma migrate` or `openapi-generator` adds 500+ lines to PR #1.
**Resolution**: Exclude generated files from line count; create separate `chore/generated-sync` PR.
**Rule**: `size:exception` auto-granted for vendor/generated diffs if segregated.

### Edge Case 2: Cross-Cutting Concern (Logging/Telemetry)
**Situation**: Adding structured logging touches 30 files across 3 work units.
**Resolution**: Extract logging concern into its own PR #0 (shared infra), then each work unit imports it.
**Rule**: Cross-cutting changes become prerequisite PR, not scattered across chain.

### Edge Case 3: Database Migration Ordering
**Situation**: PR #2 migration depends on PR #1 migration; both target tracker branch.
**Resolution**: Enforce migration sequence in tracker PR description; CI runs migrations in order.
**Rule**: Migration PRs must declare `depends_on: [migration-name]` in header.

### Edge Case 4: Hotfix Interrupts Chain
**Situation**: Critical bug found in main while chain has 2/4 PRs open.
**Resolution**: Hotfix branches from `main`, merges to `main`; rebase all chain PRs onto new main.
**Rule**: Chain PRs rebase (not merge) after hotfix; tracker PR updated last.

---

## Anti-Patterns (2)

### Anti-Pattern 1: "Split by Line Count" Without Semantic Boundaries
**Bad**: Arbitrarily slice 1,000-line PR into 250-line chunks by file count.
**Why it fails**: Reviewers see incomplete features; rollback breaks dependent code; CI fails mid-chain.
**Fix**: Split by **deliverable work unit** (contract → impl → integration), not lines.

### Anti-Pattern 2: Long-Lived Chain Without Integration
**Bad**: 8 PRs open for 3 weeks; main drifts; merge conflicts compound; reviewer fatigue.
**Why it fails**: Stale diffs, lost context, integration hell, no user value until all land.
**Fix**: Max 4 PRs per chain; target merge within 5 business days; tracker PR has TTL.

---

(End of file - total 178 lines)

## Externalized Sections (ADR-007 compression)
## Decision Gates

| Condition | Action |
|---|---|
| PR ≤400 changed lines and focused | Keep single PR. |
| PR >400, each slice can land independently | Use Stacked PRs to main. |
| PR >400, feature must integrate before main | Use Feature Branch Chain with tracker. |
| Generated/vendor/migration diff cannot split cleanly | Ask maintainer for `size:exception`. |
| SDD provides `delivery_strategy` | Follow it before apply/PR creation. |


## Output Contract

Return the chosen strategy, PR order, current PR boundary, dependency diagram, review budget (`additions + deletions`), verification plan, and any `size:exception` rationale.


