---
name: gentle-ai-branch-pr
description: "Create PRs with issue-first checks — branch naming, conventional commits, automated PR validation"
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.1"
---

## Use
Creating/opening/preparing PRs or branches for review.

## Rules
1. **Every PR MUST link an approved issue** (`status:approved`) — no exceptions
2. **Every PR MUST have exactly one `type:*` label**
3. **Automated checks must pass** before merge
4. **Blank PRs without issue linkage → blocked** by GitHub Actions

## Workflow
1. Verify issue has `status:approved` → create branch `type/description` → implement with conventional commits → shellcheck modified scripts → open PR with template → add one `type:*` label → wait for checks

## Branch Naming
Regex: `^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`

Types: `feat` · `fix` · `chore` · `docs` · `style` · `refactor` · `perf` · `test` · `build` · `ci` · `revert`

## PR Body
Template: `.github/PULL_REQUEST_TEMPLATE.md`

1. **Linked Issue** (REQUIRED): `Closes #N` / `Fixes #N` / `Resolves #N` — issue MUST have `status:approved`
2. **PR Type** (REQUIRED): check ONE + matching label: Bug→`type:bug` · Feature→`type:feature` · Docs→`type:docs` · Refactor→`type:refactor` · Chore→`type:chore` · Breaking→`type:breaking-change`
3. **Summary**: 1-3 bullet points of what the PR does
4. **Changes**: `| File | Change |` table
5. **Test Plan**: shellcheck, manual test, skills load
6. **Checklist**: linked issue ✓ · type label ✓ · shellcheck ✓ · skills tested ✓ · docs updated ✓ · conventional commit ✓ · no Co-Authored-By ✓

## Automated Checks
| Check | Verifies |
|-------|----------|
| Issue Reference | Body has `Closes/Fixes/Resolves #N` |
| Issue Approved | Linked issue has `status:approved` |
| Type Label | Exactly one `type:*` label |
| Shellcheck | All `.sh` scripts pass |

## Conventional Commits
Format: `type(scope)!: description` — regex: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`

`!` = breaking change. Type→label: `feat`→`type:feature` · `fix`→`type:bug` · `docs`→`type:docs` · `refactor`→`type:refactor` · `chore`/`style`/`test`/`build`/`ci`→`type:chore` · `perf`→`type:feature` · `revert`→`type:bug` · `feat!`/`fix!`→`type:breaking-change`

Examples: `feat(scripts): add Codex support` · `fix(skills): correct topic key` · `docs(readme): update guide` · `feat!: redesign skill loading`

## Commands
```bash
git checkout -b feat/my-feature main
shellcheck scripts/*.sh
git push -u origin feat/my-feature
gh pr create --title "feat(scope): description" --body "Closes #N"
gh pr edit <pr-number> --add-label "type:feature"
```
