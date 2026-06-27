---
name: branch-pr
description: "Create pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs for review."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.0"
---

# Gentle AI — Branch & PR Skill

Creating branches/PRs on [Gentleman-Programming/gentle-ai](https://github.com/Gentleman-Programming/gentle-ai).

## Rules
1. **PR MUST link approved issue** — `Closes/Fixes/Resolves #<N>` in body; issue MUST have `status:approved`. Auto-rejected otherwise.
2. **Exactly one `type:*` label** — CI rejects zero/multiple.
3. **400-line review budget** — ≤400 lines or `size:exception` with documented rationale.
4. **All automated checks must pass**.
5. **No `Co-Authored-By` trailers**.
6. **No force-push to main/master**.

## Workflow
1. Verify `status:approved` — `gh issue view <N>`
2. Branch from main (`^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`)
3. Implement, test (`go test ./...` + `cd e2e && ./docker-test.sh`), commit (Conventional Commits)
4. Open PR with template body + one `type:*` label
5. All checks pass before merge

## Branch Naming
All lowercase, hyphens/dots/underscores as separators.

| Types | Example |
|-------|---------|
| `feat/`·`fix/`·`docs/`·`chore/`·`style/`·`refactor/`·`perf/`·`test/`·`build/`·`ci/`·`revert/` | `fix/duplicate-observation-insert` |

## PR Body
Template `.github/PULL_REQUEST_TEMPLATE.md`: Linked Issue (Closes #N), PR Type (one checkbox), Summary, Changes (file table), Test Plan (unit + E2E), Contributor Checklist (issue link, line budget, type label, tests, docs, conventional commits, no Co-Authored-By).

## Automated Checks
| Check | How to Fix |
|-------|------------|
| **Cognitive Load** (≤400 lines) | Split PR or request `size:exception` |
| **Issue Reference** (Closes/Fixes/Resolves #N) | Add to body |
| **Issue Approved** (status:approved) | Wait for maintainer |
| **Has `type:*`** (exactly one) | Ask maintainer |
| **Unit Tests** | Fix tests |
| **E2E Tests** | Fix E2E |

## Conventional Commits
Pattern: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`

`feat→type:feature` · `fix→type:bug` · `docs→type:docs` · `refactor→type:refactor` · `chore|style|test|build|ci→type:chore` · `perf→type:feature` · `revert→matches reverted`

Breaking: `!` suffix → `type:breaking-change`.
Examples: `feat(tui): add progress bar` · `fix(agent): correct Claude Code detection` · `chore(deps): bump bubbletea` · `feat(cli)!: change default config path`

## Commands
```bash
gh issue view <N>
git checkout main && git pull && git checkout -b fix/<desc>
go test ./...
cd e2e && ./docker-test.sh
gh pr create --title "fix(agent): ..." --body-file .github/PULL_REQUEST_TEMPLATE.md
gh pr checks <N>
gh pr edit <N> --add-label "type:bug"
```

## References
- [PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md)
- [Conventional Commits](https://www.conventionalcommits.org/)
