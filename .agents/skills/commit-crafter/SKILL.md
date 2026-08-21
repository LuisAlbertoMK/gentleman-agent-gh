---
name: commit-crafter
description: Craft conventional commit messages from diff analysis.
triggers: "commit, mensaje, commit message, conventional commit, git commit, craft commit"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1907
---

## When to Use
Craft conventional commit messages from diff analysis.

## Type Detection
| Type | Trigger | Diff Pattern | Example |
|---|---|---|---|
| `feat` | New feature | New files, APIs, routes | `feat(api): add user login endpoint` |
| `fix` | Bug fix | Error handling, edge cases | `fix(auth): handle token expiry` |
| `refactor` | No behavior change | Moves, renames, extracts | `refactor(db): extract query builder` |
| `perf` | Performance | Benchmark changes | `perf(cache): reduce TTL lookups` |
| `test` | Add/fix tests | `*_test.go`, `*.spec.ts` | `test(api): cover login edge cases` |
| `docs` | Documentation | `*.md`, comments | `docs: document rate limiting` |
| `chore` | Maintenance | `go.mod`, `package.json`, CI | `chore: bump deps` |
| `style` | Formatting | Lint-only, whitespace | `style: format with prettier` |
| `ci` | CI/CD | `.github/`, deploy scripts | `ci: add lint step to workflow` |

## Format & Rules
`<type>(<scope>): <summary>` — Body explains WHAT + WHY (not HOW). 1) `git diff --stat` before crafting. 2) Summary: imperative, ≤50 chars, lowercase. 3) Body: 72-char wrap, WHAT+WHY. 4) Unrelated changes → split commits. 5) Breaking: `!` after type + `BREAKING CHANGE:` footer.

## Scope by file pattern
`api/*/routes/*`→api | `db/*/store/*`→db | `auth/*`→auth | `components/*`→ui | `deploy/*/.github/*`→deploy | `docs/*`→docs

## Anti-Patterns
`feat: fix bug` (type contradicts intent) · 80-char subject (truncated) · Explaining HOW · `update file.go` (vague) · Skipping scope · Redundant phrasing

## Refs
judgment-day · quality-gate · work-unit-commits
## Reference
> docs/skills/commit-crafter/reference.md
