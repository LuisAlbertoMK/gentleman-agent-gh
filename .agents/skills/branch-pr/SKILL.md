---
name: gentle-ai-branch-pr
description: "PR workflow — issue-first checks, branch naming, conventional commits, automated PR validation"
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.2"
  changelog: "2.2: karpathy compress"
---
## Rules
1. **Every PR MUST link an approved issue** (`status:approved`) — no exceptions
2. **Every PR MUST have exactly one `type:*` label**
3. **Automated checks must pass** before merge
4. **Blank PRs without issue → blocked**
## Workflow
Verify `status:approved` → branch `type/description` → conventional commits → shellcheck modified → open PR w/ template → `type:*` label → wait for checks
## Branch Naming: `^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`
## PR Body
Template: `.github/PULL_REQUEST_TEMPLATE.md`
1. **Linked Issue** (REQUIRED): `Closes #N` / `Fixes #N` — issue MUST have `status:approved`
2. **PR Type** (REQUIRED): check ONE + matching label (Bug→`type:bug` · Feature→`type:feature` · Docs→`type:docs` · Refactor→`type:refactor` · Chore→`type:chore` · Breaking→`type:breaking-change`)
3. **Summary**: 1-3 bullets · **Changes**: `| File | Change |` table · **Test Plan**: shellcheck, manual · **Checklist**: linked issue ✓ · type label ✓ · shellcheck ✓ · skills tested ✓ · docs updated ✓ · conventional commit ✓ · no Co-Authored-By ✓
## Automated Checks
Issue Reference (body has Closes/Fixes/Resolves #N) · Issue Approved (`status:approved`) · Type Label (exactly one `type:*`) · Shellcheck (all .sh)
## Conventional Commits
Format: `type(scope)!: description` · regex: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`
`!` = breaking. Mapping: `feat`→`type:feature` · `fix`→`type:bug` · `docs`→`type:docs` · `refactor`→`type:refactor` · `chore`/`style`/`test`/`build`/`ci`→`type:chore` · `perf`→`type:feature` · `revert`→`type:bug` · `feat!`/`fix!`→`type:breaking-change`
Examples: `feat(scripts): add Codex support` · `fix(skills): correct topic key` · `feat!: redesign skill loading`
## Commands
```
git checkout -b feat/my-feature main
shellcheck scripts/*.sh
git push -u origin feat/my-feature
gh pr create --title "type(scope): desc" --body "Closes #N"
gh pr edit <pr-number> --add-label "type:feature"
```
