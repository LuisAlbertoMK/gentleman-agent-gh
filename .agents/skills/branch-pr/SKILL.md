---
name: branch-pr
description: "Create Gentle AI pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs for review."
triggers: "pull request, create PR, open PR, branch naming, PR creation, review PR, github pull request"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Create Gentle AI pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs for review.

## Rules
1. **PR MUST link approved issue** — `Closes/Fixes/Resolves #<N>` in body. Issue MUST have `status:approved`. No link → CI rejects.
2. **Exactly one `type:*` label** — CI rejects 0 or multiple.
3. **≤400 changed lines** OR get maintainer-applied `size:exception`.
4. **No `Co-Authored-By`** trailers.
5. **No force-push to main/master**.

## Workflow
1. `gh issue view <N> --repo Gentleman-Programming/gentle-ai` → confirm `status:approved`
2. Branch from main: `^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`
3. Implement, test locally (`go test ./...`, `cd e2e && ./docker-test.sh`)
4. Commit `<type>(<scope>)!: <desc>` (conventional commits)
5. `gh pr create --repo Gentleman-Programming/gentle-ai --title "<type>(<scope>): <desc>" --body-file body.md` using template: Linked Issue (`Closes #<N>`), PR Type (checkbox 1), Summary, Changes (table), Test Plan (unit+e2e), Contributor Checklist (all must check)
6. Add exactly ONE label: `type:bug`|`type:feature`|`type:docs`|`type:refactor`|`type:chore`|`type:breaking-change`
7. Wait for CI: check-pr-size, check-issue-ref, check-issue-approved, check-type-label, unit, e2e. All must pass.

## Branch Naming
`^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$` — lowercase, hyphens/dots/underscores.

## Breaking Changes
Add `!` after type/scope. `BREAKING CHANGE:` in footer. Maps to `type:breaking-change`.

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

## Refs
issue-creation · commit-crafter · work-unit-commits · chained-pr · quality-gate

## Anti-Patterns
Create PR without approved issue · Skip local tests · Force-push to main · Add multiple type labels · Co-Authored-By trailers
