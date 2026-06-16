---
name: commit-crafter
description: Craft conventional commit messages from diff analysis.
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.1"
triggers: "commit/mensaje/commit message/conventional commit"
---

## When & Workflow
User asks for commit. `git diff --cached` → analyze → detect type+scope → craft → output.

## Type + Detection (merged)
| Type | When | Diff pattern |
|------|------|-------------|
| `feat` | New feature | New files/APIs/routes |
| `fix` | Bug fix | Error handling, bug patterns |
| `refactor` | No behavior change | Moves, renames, extracts |
| `perf` | Performance | Benchmark changes |
| `test` | Add/fix tests | Test files |
| `docs` | Documentation | Comments, .md |
| `chore` | Maintenance | go.mod, package.json |
| `style` | Formatting, lint | Lint-only changes |
| `ci` | CI/CD | .github, deploy |

## Format
`<type>(<scope>): <summary>` — imperative, ≤50 chars, lower, no period. Body wraps at 72, explains WHAT+WHY (not HOW). Breaking: add `BREAKING CHANGE:` footer + `!` after type.

## Scope (by file pattern)
`api/*/routes/*`→`api` · `db/*/store/*`→`db` · `auth/*`→`auth` · `components/*`→`ui` · `deploy/*/.github/*`→`deploy`

## Rules
1. **Evidence**: `git diff --stat` before crafting
2. **Multiple unrelated changes** → suggest splitting commits
3. **Breaking**: public API changes → `!` after type + footer
