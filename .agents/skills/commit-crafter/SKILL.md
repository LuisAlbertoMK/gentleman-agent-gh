---
name: commit-crafter
description: Craft conventional commit messages from diff analysis.
triggers: "commit, mensaje, commit message, conventional commit, git commit, craft commit"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Craft conventional commit messages from diff analysis.

<!-- karpathy-compressed: 2026-07-09 -->
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

## Format: `<type>(<scope>): <summary>` — Body explains WHAT + WHY (not HOW)
## Rules: 1) `git diff --stat` before crafting. 2) Summary: imperative, ≤50 chars, lowercase. 3) Body: 72-char wrap, WHAT+WHY. 4) Unrelated changes → split commits. 5) Breaking: `!` after type + `BREAKING CHANGE:` footer.
## Scope by file pattern
| Pattern | Scope |
|---|---|
| `api/*/routes/*` | `api` |
| `db/*/store/*` | `db` |
| `auth/*` | `auth` |
| `components/*` | `ui` |
| `deploy/*/.github/*` | `deploy` |
| `docs/*` | `docs` |

## Examples
```bash
# 1. Feature with scope
git diff --cached --stat
feat(api): add user search endpoint

Search supports fuzzy match and pagination.
Resolves #142 for admin dashboard filtering.

# 2. Bug fix with root cause
fix(auth): handle nil token on refresh

Root cause: token struct omitted nil check after decode.
Added guard + integration test for expired-then-refresh flow.

# 3. Refactor with behavior preservation
refactor(db): extract query builder to sqlbuilder pkg

Moves 340 lines from store.go → sqlbuilder/builder.go.
All existing tests pass. No API changes.

# 4. Perf with benchmark evidence
perf(cache): reduce TTL lookups by 60%

Before: 2.3ms/op | After: 0.9ms/op (benchstat p<0.01)
Replaces map scan with priority queue for eviction.

# 5. Breaking change with migration hint
feat(config)!: switch to env-only credentials

BREAKING CHANGE: .credentials.json no longer read.
Migrate: set GITHUB_TOKEN, AWS_KEY env vars.
See MIGRATION.md for automated script.
```

## Testing Patterns
| Pattern | Description | Example |
|---|---|---|
| **Golden diff** | Commit from known-good diff fixture; assert message matches expected regex | `testdata/golden/feat-api-search.diff` → `feat(api): add user search endpoint` |
| **Type inference** | Feed diffs for each type; verify correct type prefix detected | `fix:`, `feat:`, `refactor:`, `perf:`, `docs:`, `chore:` |
| **Scope resolution** | Diffs with mixed file patterns; assert scope follows priority table | `api/routes/user.go + auth/token.go` → scope `api` (priority) |

## Edge Cases
| Edge Case | Handling |
|---|---|
| **Mixed-type diff** | Split into separate commits per type; never combine `feat` + `fix` |
| **No scope match** | Fallback to parent directory name; if root → no scope (e.g. `chore: update deps`) |
| **Empty body** | Allow for trivial changes (typo, whitespace); require body for `feat`/`fix`/`perf` |
| **Breaking in non-feat** | `fix!` or `refactor!` valid if behavior contract changes; always add `BREAKING CHANGE:` footer |

## Anti-Patterns
| Anti-Pattern | Why | Do Instead |
|---|---|---|
| `feat: fix bug` | Type contradicts intent | Use correct type |
| 80-char subject | Truncated in logs | Keep ≤50 chars |
| Explaining HOW | Body should explain WHY | Describe problem/motivation |
| `update file.go` | Vague, no intent | `refactor(file): extract parseConfig` |
| Skipping scope | Harder changelog scan | Always include scope |
| Redundant phrasing | Bloated message | `fix: handle nil pointer in parse` |

## Refs
- [judgment-day](../judgment-day/SKILL.md) — code review gate
- [quality-gate](../quality-gate/SKILL.md) — pre-commit checks
- [work-unit-commits](../work-unit-commits/SKILL.md) — organizing commits
