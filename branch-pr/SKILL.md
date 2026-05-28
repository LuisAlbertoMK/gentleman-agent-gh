---
name: branch-pr
description: > PR creation workflow for Agent Teams Lite (issue-first enforcement).
  Trigger: Creating PR, opening PR, preparing changes for review.
license: Apache-2.0
metadata: author: gentleman-programming, version: "2.1"
---

## Rules
1. Every PR MUST link approved issue (`status:approved`) — no exceptions
2. Every PR MUST have exactly one `type:*` label
3. Automated checks must pass before merge
4. Blank PRs without issue linkage blocked by GitHub Actions

## Workflow
1. Verify issue has `status:approved`
2. Create branch: `type/description` (regex: `^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`)
3. Implement with conventional commits
4. Run shellcheck on modified scripts
5. Open PR using template
6. Add exactly one `type:*` label
7. Wait for checks

## Branch Naming
`feat/<desc>` · `fix/<desc>` · `chore/<desc>` · `docs/<desc>` · `refactor/<desc>` · `perf/<desc>` · `test/<desc>` · `build/<desc>` · `ci/<desc>` · `revert/<desc>`

## PR Body Format
```markdown
Closes #<issue>  (Keywords: Closes/Fixes/Resolves)

Type: [Bug fix|Feature|Docs|Refactor|Chore|Breaking change]
Label: [type:bug|feature|docs|refactor|chore|breaking-change]

Summary: 1-3 bullets

| File | Change |
| `{path}` | {what} |

Test Plan:
- [ ] Scripts pass shellcheck
- [ ] Manually tested
- [ ] Skills load correctly

Checklist: Linked approved issue · One type:label · Shellcheck · Tests · Docs updated · Conventional commits · No Co-Authored-By
```

## Conventional Commits
Regex: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`

| Commit type | PR label |
|-------------|----------|
| `feat` | `type:feature` |
| `fix` / `revert` | `type:bug` |
| `docs` | `type:docs` |
| `refactor` | `type:refactor` |
| `chore/style/perf/test/build/ci` | `type:chore` |
| `feat!` / `fix!` | `type:breaking-change` |

## Automated Checks
| Check | Verifies |
|-------|----------|
| Issue Reference | Body has `Closes/Fixes/Resolves #N` |
| Issue Approved | Linked issue has `status:approved` |
| type: Label | Exactly one type label |
| Shellcheck | Scripts pass |

## Commands
```bash
git checkout -b feat/my-feature main
shellcheck scripts/*.sh
git push -u origin feat/my-feature
gh pr create --title "feat(scope): desc" --body "Closes #N"
gh pr edit <pr> --add-label "type:feature"
```
