---
name: commit-crafter
description: Craft conventional commit messages from diff analysis.
triggers: "commit, mensaje, commit message, conventional commit, git commit, craft commit"
license: Apache-2.0
metadata:
  tags:
    - engineering
  author: gentleman-vMK
  version: "1.2"
  changelog: "1.2: initial tracked version"
---
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

## Example
```bash
git diff --cached --stat
feat(auth): add OAuth2 token refresh

Token refresh prevents silent logout for long-running sessions.
Adds refresh grant flow with retry-on-401 logic.

BREAKING CHANGE: refresh_token field now required in auth config
```

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
