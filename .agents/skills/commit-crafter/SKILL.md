---
name: commit-crafter
description: Craft conventional commit messages from diff analysis.
triggers: "commit, mensaje, commit message, conventional commit, git commit, craft commit"
changelog: docs/ciclos/cycle28-20260815.md
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

## Examples
```bash
git diff --cached --stat
feat(api): add user search endpoint   # fuzzy match + pagination; Resolves #142
fix(auth): handle nil token on refresh # root cause: omitted nil check after decode; +integration test
refactor(db): extract query builder   # moves 340 lines store.go→sqlbuilder; tests pass
perf(cache): reduce TTL lookups by 60% # 2.3ms/op→0.9ms/op (benchstat p<0.01)
feat(config)!: switch to env-only credentials # BREAKING CHANGE: .credentials.json no longer read
```

## Edge Cases
| Edge Case | Handling |
|---|---|
| Mixed-type diff | Split per type; never combine `feat` + `fix` |
| No scope match | Parent directory name; root → no scope |
| Empty body | OK for trivial; required for `feat`/`fix`/`perf` |
| Breaking in non-feat | `fix!`/`refactor!` valid; always add `BREAKING CHANGE:` footer |

## Anti-Patterns
`feat: fix bug` (type contradicts intent) · 80-char subject (truncated) · Explaining HOW · `update file.go` (vague) · Skipping scope · Redundant phrasing

## Refs
judgment-day · quality-gate · work-unit-commits