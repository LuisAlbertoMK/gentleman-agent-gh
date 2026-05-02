---
name: branch-pr
description: >
  PR creation workflow for Agent Teams Lite (issue-first enforcement).
  Trigger: Creating PR, opening PR, preparing changes for review.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.0"
---

## When
Creating PR · Preparing branch · Helping contributor open PR

## Critical Rules
1. Every PR MUST link approved issue — no exceptions
2. Every PR MUST have exactly one `type:*` label
3. Automated checks must pass before merge
4. Blank PRs without issue linkage blocked by GitHub Actions

## Workflow
1. Verify issue has `status:approved`
2. Create branch: `type/description` (see Naming below)
3. Implement with conventional commits
4. Run shellcheck on modified scripts
5. Open PR using template
6. Add exactly one `type:*` label
7. Wait for checks to pass

## Branch Naming
Regex: `^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feat/<desc>` | `feat/user-login` |
| Bug fix | `fix/<desc>` | `fix/zsh-glob-error` |
| Chore | `chore/<desc>` | `chore/update-ci-actions` |
| Docs | `docs/<desc>` | `docs/installation-guide` |
| Style | `style/<desc>` | `style/format-scripts` |
| Refactor | `refactor/<desc>` | `refactor/extract-shared-logic` |
| Performance | `perf/<desc>` | `perf/reduce-startup-time` |
| Test | `test/<desc>` | `test/add-setup-coverage` |
| Build | `build/<desc>` | `build/update-shellcheck` |
| CI | `ci/<desc>` | `ci/add-branch-validation` |
| Revert | `revert/<desc>` | `revert/broken-setup-change` |

## PR Body Format

### 1. Linked Issue (REQUIRED)
```markdown
Closes #<issue-number>
```
Keywords: `Closes #N`, `Fixes #N`, `Resolves #N`. Issue MUST have `status:approved`.

### 2. PR Type (REQUIRED)
Check ONE + add matching label:
| Checkbox | Label |
|----------|-------|
| Bug fix | `type:bug` |
| New feature | `type:feature` |
| Documentation | `type:docs` |
| Code refactoring | `type:refactor` |
| Maintenance/tooling | `type:chore` |
| Breaking change | `type:breaking-change` |

### 3. Summary
1-3 bullets of what PR does.

### 4. Changes Table
```markdown
| File | Change |
| `path/to/file` | What changed |
```

### 5. Test Plan
```markdown
- [x] Scripts pass shellcheck
- [x] Manually tested affected functionality
- [x] Skills load correctly
```

### 6. Contributor Checklist
- Linked approved issue · One `type:*` label · Ran shellcheck · Skills tested · Docs updated if behavior changed · Conventional commits · No `Co-Authored-By`

## Automated Checks
| Check | Job | Verifies |
|-------|-----|----------|
| PR Validation | Check Issue Reference | Body contains `Closes/Fixes/Resolves #N` |
| PR Validation | Check Issue Has status:approved | Linked issue approved |
| PR Validation | Check PR Has type:* Label | Exactly one type label |
| CI | Shellcheck | Scripts pass shellcheck |

## Conventional Commits
Regex: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`

Format: `type(scope): description` or `type: description`
- `type` — required: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test
- `(scope)` — optional, lowercase
- `!` — optional, breaking change
- `description` — required after `: `

| Commit type | PR label |
|-------------|----------|
| `feat` | `type:feature` |
| `fix` | `type:bug` |
| `docs` | `type:docs` |
| `refactor` | `type:refactor` |
| `chore/style/perf/test/build/ci` | `type:chore` |
| `revert` | `type:bug` |
| `feat!` / `fix!` | `type:breaking-change` |

## Commands
```bash
git checkout -b feat/my-feature main
shellcheck scripts/*.sh
git push -u origin feat/my-feature
gh pr create --title "feat(scope): description" --body "Closes #N"
gh pr edit <pr-number> --add-label "type:feature"
```
