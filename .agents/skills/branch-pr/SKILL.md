---
name: branch-pr
description: "Create Gentle AI pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs for review."
triggers: "branch PR, create PR, pull request, open PR, PR workflow"
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.1"
  changelog: "2.1: karpathy compress (8.8→3.2KB)"
---

# Gentle AI — Branch & PR Skill

## When to Use
Create/open PRs on [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai). Load before PR workflows.

## Critical Rules
1. **PR MUST link `status:approved` issue** — `Closes/Fixes/Resolves #<N>`. Auto-rejected without.
2. **Exactly one `type:*` label** — CI rejects zero/multiple.
3. **≤400 changed lines** or maintainer-applied `size:exception`.
4. **No `Co-Authored-By`** trailers. No force-push to main.

## Workflow
```
Confirm issue approved → branch from main → implement + test → commit (Conventional) → open PR with template → checks pass → merge
```

## Branch Naming
```
^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$
```
Lowercase, hyphens/dots/underscores.

## PR Body
Use `.github/PULL_REQUEST_TEMPLATE.md`. Must include `Closes #<N>` in Linked Issue. All sections required.

## Automated Checks
| Check | Verifies | Fix |
|-------|----------|-----|
| Cognitive Load | ≤400 lines or `size:exception` | Split or request exception |
| Issue Reference | Body has `Closes/Fixes/Resolves #N` | Add reference |
| Issue Approved | Linked issue has `status:approved` | Wait for maintainer |
| `type:*` Label | Exactly one type label | Add/remove labels |
| Tests | `go test ./...` + `cd e2e && ./docker-test.sh` | Fix failures |

## Conventional Commits
See `commit-crafter` skill for full format. Allowed types: `feat|fix|docs|refactor|chore|style|perf|test|build|ci|revert`. Breaking: add `!` + `BREAKING CHANGE:` footer.

## Commands
```bash
gh issue view <N> --repo Gentleman-Programming/gentle-ai          # verify approved
git checkout main && git pull && git checkout -b fix/<desc>       # branch
gh pr create --repo Gentleman-Programming/gentle-ai --title "fix(scope): desc" --body-file .github/PULL_REQUEST_TEMPLATE.md
gh pr edit <N> --repo Gentleman-Programming/gentle-ai --add-label "type:bug"
gh pr checks --repo Gentleman-Programming/gentle-ai <N>
```
