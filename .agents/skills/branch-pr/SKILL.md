---
name: gentle-ai-branch-pr
description: "Create Gentle AI pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs for review."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.0"
---

# Gentle AI — Branch & PR Skill

## When to Use

Load when creating branches, opening PRs on [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai), or preparing changes for review.

## Critical Rules

1. **PR MUST link approved issue** — `Closes/Fixes/Resolves #<N>`, issue must have `status:approved`.
2. **Exactly one `type:*` label** — CI rejects zero or multiple.
3. **400-line budget** — additions+deletions ≤ 400, or `size:exception` with rationale.
4. **No `Co-Authored-By`** — never add AI attribution.
5. **No force-push to main/master**.

## Workflow

1. Confirm issue approved: `gh issue view <N>` (must show `status:approved`)
2. Create branch from main with naming convention below
3. Implement, test, commit (Conventional Commits)
4. Open PR → exactly one `type:*` label → pass automated checks

## Branch Naming

Pattern: `^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`

| Type | Example |
|------|---------|
| `feat/` | `feat/user-login` |
| `fix/` | `fix/duplicate-insert` |
| `docs/` | `docs/api-update` |
| `refactor/` | `refactor/extract-sanitizer` |
| `chore/`/`style/`/`test/`/`build/`/`ci/` | `chore/bump-bubbletea` |
| `perf/` | `perf/cache-os-detection` |
| `revert/` | `revert/undo-model-picker` |

All lowercase, hyphens/dots/underscores, short + descriptive.

## PR Body Format

Use `.github/PULL_REQUEST_TEMPLATE.md` — required: linked issue, PR type, summary, changes table, test plan, contributor checklist.

## Automated Checks

- **Cognitive Load**: ≤400 lines or `size:exception`
- **Issue**: body has `Closes/Fixes/Resolves #N`, issue has `status:approved`
- **Labels**: exactly one `type:*` label
- **Tests**: `go test ./...` + `cd e2e && ./docker-test.sh`

## Conventional Commits

Format: `<type>(<scope>)!: <desc>` with `BREAKING CHANGE:` in body for breaking.

| Type | PR Label |
|------|----------|
| feat/perf | `type:feature` |
| fix | `type:bug` |
| docs | `type:docs` |
| refactor | `type:refactor` |
| chore/style/test/build/ci | `type:chore` |
| revert | matches reverted |
| breaking `!` | `type:breaking-change` |

## Commands

```bash
# Confirm issue approved
gh issue view <N> --repo Gentleman-Programming/gentle-ai
# Create branch
git checkout main && git pull && git checkout -b fix/<desc>
# Tests
go test ./...; (cd e2e && ./docker-test.sh)
# Open PR
gh pr create --repo Gentleman-Programming/gentle-ai --title "fix(agent): <desc>" --body-file .github/PULL_REQUEST_TEMPLATE.md
# Add label
gh pr edit <N> --repo Gentleman-Programming/gentle-ai --add-label "type:bug"
```
