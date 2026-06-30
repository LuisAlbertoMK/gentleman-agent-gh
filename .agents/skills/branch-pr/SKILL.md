---
name: gentle-ai-branch-pr
description: "Create Gentle AI pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs for review."
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.0"
---

## When
- Create branch for fix/feature
- Open PR on Gentleman-Programming/gentle-ai
- Prepare changes for review

## Rules
1. **PR MUST link approved issue** — `Closes/Fixes/Resolves #<N>` in body. Issue MUST have `status:approved`. No link → CI rejects.
2. **Exactly one `type:*` label** — CI rejects 0 or multiple.
3. **≤400 changed lines** (`additions+deletions`) OR get maintainer-applied `size:exception` with rationale.
4. **No `Co-Authored-By`** trailers.
5. **No force-push to main/master**.

## Workflow
1. `gh issue view <N> --repo Gentleman-Programming/gentle-ai` → confirm `status:approved`
2. Branch from main: `^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`
3. Implement, test locally (`go test ./...`, `cd e2e && ./docker-test.sh`)
4. Commit `<type>(<scope>)!: <desc>` (conventional commits)
5. `gh pr create --repo Gentleman-Programming/gentle-ai --title "<type>(<scope>): <desc>" --body "$(cat body.md)"` with template from `.github/PULL_REQUEST_TEMPLATE.md`
6. Add exactly ONE `type:*` label: `type:bug`|`type:feature`|`type:docs`|`type:refactor`|`type:chore`|`type:breaking-change`
7. Wait for CI: check-pr-size, check-issue-ref, check-issue-approved, check-type-label, unit, e2e. All must pass.

## PR Body Template
Sections: Linked Issue (`Closes #<N>`), PR Type (checkbox one), Summary, Changes (table File/What), Test Plan (unit + e2e), Contributor Checklist (all must check). Fill all required.

## Branch Naming
`^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$` — lowercase, hyphens/dots/underscores.

## Breaking Changes
Add `!` after type/scope. `BREAKING CHANGE:` in footer. Maps to `type:breaking-change`.

## Commands
```bash
# Check issue
gh issue view <N> --repo Gentleman-Programming/gentle-ai

# Branch
git checkout main && git pull && git checkout -b <type>/<desc>

# Test
go test ./...
go test ./internal/tui/...
cd e2e && ./docker-test.sh

# PR
gh pr create --repo Gentleman-Programming/gentle-ai --title "<type>(<scope>): <desc>" --body "$(cat <<'BODY'
## 🔗 Linked Issue
Closes #<N>
## 🏷️ PR Type
- [ ] `type:bug` | `type:feature` | `type:docs` | `type:refactor` | `type:chore` | `type:breaking-change`
## 📝 Summary
## 📂 Changes
| File | What |
|------|------|
## 🧪 Test Plan
- [ ] Unit tests pass
- [ ] E2E tests pass
- [ ] Manually tested
## ✅ Contributor Checklist
- [ ] PR linked to approved issue
- [ ] ≤400 lines or size:exception
- [ ] type:* label applied
- [ ] Tests pass
- [ ] Docs updated if needed
- [ ] Conventional commits
- [ ] No Co-Authored-By
BODY
)"

# Check status
gh pr checks --repo Gentleman-Programming/gentle-ai <PR#>
gh pr view --repo Gentleman-Programming/gentle-ai <PR#>
gh pr edit <PR#> --repo Gentleman-Programming/gentle-ai --add-label "type:bug"
```
