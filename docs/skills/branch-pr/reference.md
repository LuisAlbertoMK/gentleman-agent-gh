# branch-pr — Reference Materials

> **Externalized from** .agents/skills/branch-pr/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples

### Example 1: Feature PR (Standard)
```bash
# Issue #142 approved: "Add dark mode toggle to settings"
gh issue view 142 --repo Gentleman-Programming/gentle-ai
# → status:approved ✓

git checkout main && git pull
git checkout -b feat/dark-mode-toggle

# Implement changes...
go test ./... && cd e2e && ./docker-test.sh

git add -A
git commit -m "feat(settings): add dark mode toggle with persistence

Closes #142"

cat > body.md <<'EOF'
## Linked Issue
Closes #142

## PR Type
- [x] Feature

## Summary
Adds a dark/light mode toggle to the Settings panel with localStorage persistence.

## Changes
| File | Change |
|------|--------|
| src/settings/SettingsPanel.tsx | Added toggle component |
| src/hooks/useTheme.ts | New hook for theme management |
| src/styles/theme.css | Dark mode CSS variables |

## Test Plan
- [x] Unit: useTheme hook tests (3 new tests)
- [x] E2E: Toggle persists after reload (docker-test.sh)

## Contributor Checklist
- [x] Conventional commit
- [x] No Co-Authored-By
- [x] ≤400 lines changed
- [x] Single type label
EOF

gh pr create --repo Gentleman-Programming/gentle-ai \
  --title "feat(settings): add dark mode toggle with persistence" \
  --body-file body.md

gh pr edit 142 --repo Gentleman-Programming/gentle-ai --add-label "type:feature"
```

### Example 2: Bug Fix PR
```bash
# Issue #89 approved: "Fix N+1 query in user list endpoint"
gh issue view 89 --repo Gentleman-Programming/gentle-ai

git checkout main && git pull
git checkout -b fix/n-plus-one-user-list

# Implement fix...
go test ./... && cd e2e && ./docker-test.sh

git add -A
git commit -m "fix(api): resolve N+1 query in GET /users

Closes #89"

cat > body.md <<'EOF'
## Linked Issue
Closes #89

## PR Type
- [x] Bug Fix

## Summary
Replaced looped single-user queries with a single JOIN query in UserRepository.

## Changes
| File | Change |
|------|--------|
| internal/repository/user.go | Added GetUsersWithRoles() batch method |
| internal/handler/user.go | Updated handler to use batch method |

## Test Plan
- [x] Unit: UserRepository test (query count assertion)
- [x] E2E: GET /users returns in <50ms (docker-test.sh)

## Contributor Checklist
- [x] Conventional commit
- [x] No Co-Authored-By
- [x] ≤400 lines changed
- [x] Single type label
EOF

gh pr create --repo Gentleman-Programming/gentle-ai \
  --title "fix(api): resolve N+1 query in GET /users" \
  --body-file body.md

gh pr edit 89 --repo Gentleman-Programming/gentle-ai --add-label "type:bug"
```

### Example 3: Breaking Change PR
```bash
# Issue #203 approved: "Remove deprecated v1 auth endpoints"
gh issue view 203 --repo Gentleman-Programming/gentle-ai

git checkout main && git pull
git checkout -b feat/remove-v1-auth-endpoints

# Implement removal...
go test ./... && cd e2e && ./docker-test.sh

git add -A
git commit -m "feat(auth)!: remove deprecated v1 auth endpoints

BREAKING CHANGE: v1 /login, /register, /refresh endpoints removed. Migrate to v2.

Closes #203"

cat > body.md <<'EOF'
## Linked Issue
Closes #203

## PR Type
- [x] Breaking Change

## Summary
Removes v1 authentication endpoints per deprecation notice (v0.8.0).

## Changes
| File | Change |
|------|--------|
| internal/routes/auth_v1.go | Deleted (127 lines) |
| internal/handler/auth_v1.go | Deleted (89 lines) |
| docs/api/auth.md | Updated migration guide |

## Test Plan
- [x] Unit: v2 auth flow tests pass
- [x] E2E: v1 endpoints return 410 Gone (docker-test.sh)

## Contributor Checklist
- [x] Conventional commit with !
- [x] BREAKING CHANGE footer
- [x] No Co-Authored-By
- [x] ≤400 lines changed
- [x] Single type label (type:breaking-change)
EOF

gh pr create --repo Gentleman-Programming/gentle-ai \
  --title "feat(auth)!: remove deprecated v1 auth endpoints" \
  --body-file body.md

gh pr edit 203 --repo Gentleman-Programming/gentle-ai --add-label "type:breaking-change"
```

### Example 4: Chore/Refactor PR (No Issue Required for Trivial)
```bash
# For chores ≤50 lines, issue optional if maintainer pre-approves
# This example assumes issue #311 exists with status:approved

git checkout main && git pull
git checkout -b chore/update-dependencies

# Update go.mod, go.sum
go mod tidy && go test ./...

git add go.mod go.sum
git commit -m "chore(deps): update Go dependencies to latest patch versions

Closes #311"

cat > body.md <<'EOF'
## Linked Issue
Closes #311

## PR Type
- [x] Chore

## Summary
Patch-level dependency updates: gorilla/mux, stretchr/testify, gorm.io/gorm.

## Changes
| File | Change |
|------|--------|
| go.mod | 12 patch updates |
| go.sum | Checksum updates |

## Test Plan
- [x] Unit: All existing tests pass
- [x] E2E: docker-test.sh passes

## Contributor Checklist
- [x] Conventional commit
- [x] No Co-Authored-By
- [x] ≤400 lines changed
- [x] Single type label
EOF

gh pr create --repo Gentleman-Programming/gentle-ai \
  --title "chore(deps): update Go dependencies to latest patch versions" \
  --body-file body.md

gh pr edit 311 --repo Gentleman-Programming/gentle-ai --add-label "type:chore"
```

### Example 5: Documentation PR
```bash
# Issue #178 approved: "Add API authentication guide"
gh issue view 178 --repo Gentleman-Programming/gentle-ai

git checkout main && git pull
git checkout -b docs/api-auth-guide

# Write documentation...
# No code tests needed for pure docs

git add docs/api/authentication.md
git commit -m "docs(api): add JWT authentication guide with examples

Closes #178"

cat > body.md <<'EOF'
## Linked Issue
Closes #178

## PR Type
- [x] Documentation

## Summary
Complete JWT auth guide: token acquisition, refresh, scopes, error codes.

## Changes
| File | Change |
|------|--------|
| docs/api/authentication.md | New file (245 lines) |

## Test Plan
- [x] Link check: markdownlint passes
- [x] Render check: docs build passes

## Contributor Checklist
- [x] Conventional commit
- [x] No Co-Authored-By
- [x] ≤400 lines changed
- [x] Single type label
EOF

gh pr create --repo Gentleman-Programming/gentle-ai \
  --title "docs(api): add JWT authentication guide with examples" \
  --body-file body.md

gh pr edit 178 --repo Gentleman-Programming/gentle-ai --add-label "type:docs"
```

## Testing Patterns

### Pattern 1: Local Pre-PR Validation (Mandatory)
```bash
# Run BEFORE gh pr create — catches 90% of CI failures
go test ./...                    # Unit tests (all packages)
go test ./internal/tui/...       # TUI-specific tests
cd e2e && ./docker-test.sh       # E2E integration tests
# All must pass → then create PR
```
**Purpose**: Fail fast locally. CI is for verification, not discovery.

### Pattern 2: PR Size Check (Automated Gate)
```bash
# Check locally before push — mirrors check-pr-size CI job
git diff --stat main...HEAD
# If added+deleted > 400 → split into chained PRs (see chained-pr skill)
# Exception: maintainer applies `size:exception` label post-review
```
**Purpose**: Enforce ≤400 lines. Prevents oversized PRs that block review.

### Pattern 3: Issue Reference Validation (Pre-CI)
```bash
# Verify issue link format before CI runs check-issue-ref
grep -E "Closes|Fixes|Resolves" body.md | grep -E "#[0-9]+"
# Must match exactly one issue number
# Issue must have status:approved (verify with gh issue view)
```
**Purpose**: Catch malformed issue refs before CI rejects the PR.

## Edge Cases

### Edge Case 1: Issue Not Yet Approved
```bash
gh issue view 999 --repo Gentleman-Programming/gentle-ai
# → status:pending-review (NOT approved)

# DO NOT create PR. Wait for maintainer approval or request it:
gh issue comment 999 --repo Gentleman-Programming/gentle-ai \
  --body "Ready for review — please approve for PR"
```
**Resolution**: Block PR creation until `status:approved`. CI `check-issue-approved` will reject.

### Edge Case 2: Multiple Type Labels Accidentally Added
```bash
gh pr edit 42 --repo Gentleman-Programming/gentle-ai --add-label "type:feature"
gh pr edit 42 --repo Gentleman-Programming/gentle-ai --add-label "type:bug"
# CI check-type-label FAILS (multiple type:* labels)

# Fix: Remove all, add exactly one
gh pr edit 42 --repo Gentleman-Programming/gentle-ai --remove-label "type:feature,type:bug"
gh pr edit 42 --repo Gentleman-Programming/gentle-ai --add-label "type:feature"
```
**Resolution**: Only ONE `type:*` label allowed. Use `gh pr edit --remove-label` to clean.

### Edge Case 3: Force-Push to Main (Blocked)
```bash
git push origin main --force
# → REJECTED by branch protection (Rule 5)

# Correct: Push to feature branch only
git push origin feat/my-feature
# Or if main diverged: rebase feature onto main, then force-push FEATURE branch
git checkout feat/my-feature && git rebase main && git push origin feat/my-feature --force-with-lease
```
**Resolution**: Never force-push to protected branches. Use `--force-with-lease` on feature branches only.

### Edge Case 4: PR Exceeds 400 Lines (Requires Exception)
```bash
git diff --stat main...HEAD
# 523 files changed, 12,450 insertions(+), 8,230 deletions(-) → TOO LARGE

# Option A: Split into chained PRs (chained-pr skill)
# Option B: Request size:exception from maintainer
gh pr edit 99 --repo Gentleman-Programming/gentle-ai --add-label "size:exception"
# Maintainer applies label after reviewing scope justification
```
**Resolution**: Either split work (preferred) or get explicit `size:exception` label.

## Anti-Patterns

### Anti-Pattern 1: Creating PR Without Approved Issue
```bash
# WRONG
gh pr create --repo Gentleman-Programming/gentle-ai \
  --title "feat: new dashboard" \
  --body "Closes #999"   # Issue #999 doesn't exist or isn't approved

# CI REJECTS: check-issue-ref (missing) OR check-issue-approved (not approved)
```
**Why it fails**: Every PR must trace to an approved issue. No exceptions.

### Anti-Pattern 2: Skipping Local Tests
```bash
# WRONG
git commit -m "feat: risky refactor"
git push origin feat/risky-refactor
gh pr create ...  # CI runs tests → FAILS (flaky, slow, wastes reviewer time)

# CORRECT
go test ./... && cd e2e && ./docker-test.sh  # Pass locally FIRST
git push origin feat/risky-refactor
gh pr create ...
```
**Why it fails**: CI is verification, not your test runner. Local failures block merge and waste maintainer cycles.

## Refs
issue-creation · commit-crafter · work-unit-commits · chained-pr · quality-gate

## Anti-Patterns
Create PR without approved issue · Skip local tests · Force-push to main · Add multiple type labels · Co-Authored-By trailers

## Externalized Sections (ADR-007 compression)
## Commands
```bash
# Check issue
gh issue view <N> --repo Gentleman-Programming/gentle-ai
# Branch
git checkout main && git pull && git checkout -b <type>/<desc>
# Test
go test ./... && go test ./internal/tui/... && cd e2e && ./docker-test.sh
# PR
gh pr create --repo Gentleman-Programming/gentle-ai --title "<type>(<scope>): <desc>" --body-file body.md
# Check status
gh pr checks --repo Gentleman-Programming/gentle-ai <PR#> && gh pr view <PR#>
gh pr edit <PR#> --repo Gentleman-Programming/gentle-ai --add-label "type:bug"
```
---

docs/skills/branch-pr/reference.md
---
