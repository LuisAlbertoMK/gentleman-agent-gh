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
Regex: `^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feat/<desc>` | `feat/user-login` |
| Bug fix | `fix/<desc>` | `fix/zsh-glob-error` |
| Chore | `chore/<desc>` | `chore/update-ci-actions` |
| Docs | `docs/<desc>` | `docs/installation-guide` |
| Style | `style/<desc>` | `style/format-scripts` |
| Refactor | `refactor/<desc>` | `refactor/extract-shared-logic` |
| Perf | `perf/<desc>` | `perf/reduce-startup-time` |
| Test | `test/<desc>` | `test/add-setup-coverage` |
| Build | `build/<desc>` | `build/update-shellcheck` |
| CI | `ci/<desc>` | `ci/add-branch-validation` |
| Revert | `revert/<desc>` | `revert/broken-setup-change` |

## PR Body Format
```markdown
Closes #<issue>  (Keywords: Closes/Fixes/Resolves)

Type: [Bug fix|Feature|Docs|Refactor|Chore|Breaking change]
Label: [type:bug|feature|docs|refactor|chore|breaking-change]

Summary: 1-3 bullets

| File | Change |
| `{path}` | {what} |

Test Plan:
- [x] Scripts pass shellcheck
- [x] Manually tested affected functionality
- [x] Skills load correctly in target agent

Checklist (all must pass):
- Linked approved issue (`status:approved`)
- Exactly one `type:*` label
- Shellcheck on modified scripts
- Skills tested in at least one agent
- Docs updated if behavior changed
- Conventional commit format
- No `Co-Authored-By` trailers
```

## Conventional Commits
Format: `type(scope): description` | `type: description` | `type!:` for breaking
Regex: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9\._-]+\))?!?: .+`

| Commit type | PR label | Examples |
|-------------|----------|----------|
| `feat` | `type:feature` | `feat(scripts): add Codex support` |
| `fix` | `type:bug` | `fix(skills): correct topic key format` |
| `docs` | `type:docs` | `docs(readme): update config guide` |
| `refactor` | `type:refactor` | `refactor(skills): extract shared logic` |
| `chore` | `type:chore` | `chore(ci): add shellcheck to PR validation` |
| `style` | `type:chore` | `style(skills): fix markdown formatting` |
| `perf` | `type:feature` | `perf(scripts): reduce setup.sh time` |
| `test` | `type:chore` | `test(scripts): add integration tests` |
| `build` | `type:chore` | `build(ci): pin actions to SHAs` |
| `ci` | `type:chore` | `ci(workflows): add branch validation` |
| `revert` | `type:bug` | `revert: undo broken setup change` |
| `feat!` / `fix!` | `type:breaking-change` | `feat!: redesign skill loading` |

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
