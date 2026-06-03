---
name: branch-pr
description: > PR creation workflow for Agent Teams Lite (issue-first enforcement).
  Trigger: Creating PR, opening PR, preparing changes for review.
license: Apache-2.0
metadata: author: gentleman-programming, version: "2.1"
---

## Rules
1. PR MUST link approved issue (`status:approved`)
2. PR MUST have exactly one `type:*` label
3. Automated checks must pass
4. Blank PRs without issue linkage blocked

## Workflow
1. Verify issue `status:approved`
2. Create branch per naming rules below
3. Implement with conventional commits
4. Run shellcheck
5. Open PR using template
6. Add one `type:*` label
7. Wait for checks

## Branch Naming
`^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`

`feat/<desc>` · `fix/<desc>` · `chore/<desc>` · `docs/<desc>` · `style/<desc>`
`refactor/<desc>` · `perf/<desc>` · `test/<desc>` · `build/<desc>` · `ci/<desc>` · `revert/<desc>`

## PR Body Format
```markdown
Closes #<issue>  (Keywords: Closes/Fixes/Resolves)

Type: [Bug fix|Feature|Docs|Refactor|Chore|Breaking change]
Label: [type:bug|feature|docs|refactor|chore|breaking-change]

Summary: 1-3 bullets

| File | Change |
| `{path}` | {what} |

Test Plan: shellcheck · manual test · skills load

Checklist: approved issue · type:label · shellcheck · skills tested · docs updated · conventional commits · no Co-Authored-By
```

## Conventional Commits
Format: `type(scope): desc` | `type: desc` | `type!:` = breaking
Regex: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`

| Type | Label | Type | Label |
|------|-------|------|-------|
| `feat` | feature | `fix`/`revert` | bug |
| `docs` | docs | `refactor` | refactor |
| `chore`/`style`/`build`/`ci` | chore | `perf`/`feat!`/`fix!` | feature/breaking |
| `test` | chore | | |

## Automated Checks
| Check | Job | Verifies |
|-------|-----|----------|
| Issue Reference | Check Issue Reference | Body has `Closes/Fixes/Resolves #N` |
| Issue Approved | Check Issue Has status:approved | Linked issue has `status:approved` |
| type: Label | Check PR Has type:\* Label | Exactly one type label |
| Shellcheck | Shellcheck | Scripts pass `shellcheck` |

## Commands
```bash
git checkout -b feat/my-feature main
shellcheck scripts/*.sh
git push -u origin feat/my-feature
gh pr create --title "feat(scope): desc" --body "Closes #N"
gh pr edit <pr> --add-label "type:feature"
```
