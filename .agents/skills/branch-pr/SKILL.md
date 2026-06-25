---
name: gentle-ai-branch-pr
description: "Create Gentle AI pull requests with issue-first checks. Trigger: creating or preparing PRs."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.0"
---

# Gentle AI — Branch & PR Skill

## When to Use
Create branches + PRs on [gentle-ai](https://github.com/Gentleman-Programming/gentle-ai). Load before any PR workflow.

## Critical Rules
1. **Every PR MUST link an approved issue** — `Closes/Fixes/Resolves #<N>`, issue MUST have `status:approved`. PRs without this are **auto-rejected**.
2. **Exactly one `type:*` label** — CI rejects zero/multiple.
3. **400-line review budget** — keep PRs ≤400 changed lines or get maintainer-applied `size:exception`.
4. **Automated checks must pass** (see below).
5. **No `Co-Authored-By` trailers** in commits.
6. **No force-push to main/master**.

## Workflow
1. Confirm issue `status:approved` → `gh issue view <N> --repo Gentleman-Programming/gentle-ai`
2. Create branch (see naming below)
3. Implement, test (`go test ./...` + `cd e2e && ./docker-test.sh`)
4. Commit (Conventional Commits)
5. Open PR with template body + exactly one `type:*` label
6. All automated checks must pass before merge

## Branch Naming
```
^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$
```
Lowercase, hyphens/dots/underscores as separators.

## PR Body
Use `.github/PULL_REQUEST_TEMPLATE.md`. All sections required unless optional. MUST include `Closes #<N>` in 🔗 Linked Issue section.

## Automated Checks
| Check | What It Verifies | How to Fix |
|-------|-----------------|------------|
| Check PR Cognitive Load | ≤400 lines or `size:exception` present | Split PR or request `size:exception` |
| Check Issue Reference | Body contains `Closes/Fixes/Resolves #N` | Add reference |
| Check Issue `status:approved` | Linked issue has `status:approved` | Wait for maintainer |
| Check `type:*` label | Exactly one type label | Add/remove labels |
| Unit Tests | `go test ./...` passes | Fix failing tests |
| E2E Tests | `cd e2e && ./docker-test.sh` passes | Fix E2E scenarios |

## Conventional Commits
```
^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+
```
Breaking changes: add `!` after type/scope + `BREAKING CHANGE:` in footer → `type:breaking-change` label.

| Type | PR Label |
|------|----------|
| `feat` | `type:feature` |
| `fix` | `type:bug` |
| `docs` | `type:docs` |
| `refactor` | `type:refactor` |
| `chore`/`style`/`test`/`build`/`ci` | `type:chore` |
| `perf` | `type:feature` |
| `revert` | matches reverted type |

## Commands
```bash
# Create branch
git checkout main && git pull && git checkout -b fix/<short-description>

# Open PR
gh pr create --repo Gentleman-Programming/gentle-ai \
  --title "fix(agent): short description" \
  --body-file .github/PULL_REQUEST_TEMPLATE.md

# Check PR status
gh pr checks --repo Gentleman-Programming/gentle-ai <PR-number>

# Add label
gh pr edit <PR-number> --repo Gentleman-Programming/gentle-ai --add-label "type:bug"
```
