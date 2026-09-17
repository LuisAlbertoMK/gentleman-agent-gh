---
name: branch-pr
description: "Create Gentle AI pull requests with issue-first checks. Trigger: creating, opening, or preparing PRs for review."
triggers: "pull request, create PR, open PR, branch naming, PR creation, review PR, github pull request"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2200
---
## Rules
1. PR MUST link approved issue — `Closes/Fixes/Resolves #<N>`, issue `status:approved`. No link→CI rejects.
2. Exactly one `type:*` label
3. ≤400 changed lines OR `size:exception`
4. No `Co-Authored-By` trailers
5. No force-push to main/master

## Workflow
1. `gh issue view <N> --repo Gentleman-Programming/gentle-ai` → confirm `status:approved`
2. Branch: `^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)\/[a-z0-9._-]+$`
3. Implement, test locally (`go test ./...`, `cd e2e && ./docker-test.sh`)
4. Commit `<type>(<scope>)!: <desc>` (conventional commits)
5. `gh pr create --repo Gentleman-Programming/gentle-ai --title "<type>(<scope>): <desc>" --body-file body.md`
6. ONE label: `type:bug|feature|docs|refactor|chore|breaking-change`
7. Wait for CI: check-pr-size, check-issue-ref, check-issue-approved, check-type-label, unit, e2e

## Breaking Changes
Add `!` after type/scope. `BREAKING CHANGE:` in footer. Maps to `type:breaking-change`.

## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "PR sin issue-first" | No Closes/Fixes #N or issue not approved | gh issue view + body Closes #N + CI check |
| "commit mixto" | Mixed work units or >400 lines | 1 commit=1 work unit + ≤400 lines |
| "branch sin regex" | Branch doesn't match pattern | Regex + exactly one type:* label |

## Red Flags
- Same rationalization 2× → force RED

→ docs/skills/branch-pr/reference.md · Cross-Refs: chained-pr | issue-creation | work-unit-commits | commit-crafter

