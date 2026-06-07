---
name: commit-crafter
description: >
  Craft conventional commit messages from diff analysis.
  Trigger: "commit", "mensaje", "commit message", "conventional commit".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## When
User asks for commit message. Before `git commit`.

## Critical Patterns

### Commit type selection

| Type | When | Example |
|------|------|---------|
| `feat` | New feature for user | `feat(auth): add OAuth2 login` |
| `fix` | Bug fix | `fix(parser): handle empty input` |
| `refactor` | Code change — no behavior change | `refactor(api): extract validation` |
| `perf` | Performance improvement | `perf(db): pool connections` |
| `test` | Add/fix tests | `test(auth): cover edge cases` |
| `docs` | Documentation | `docs(readme): update setup` |
| `chore` | Maintenance, deps, config | `chore(deps): bump go 1.22` |
| `style` | Formatting, lint | `style(format): gofmt all` |
| `ci` | CI/CD | `ci(deploy): add staging` |

### Format
```
<type>(<scope>): <short summary>

<body — optional, wrap at 72 chars>

BREAKING CHANGE: <description — only if needed>
```

### Workflow
```
git diff --cached → analyze changed files → detect type + scope → craft → output
```

### Detection rules
| Diff pattern | Type |
|-------------|------|
| New files, new APIs, new routes | `feat` |
| Error handling, bug pattern fixes | `fix` |
| Moves files, renames, extracts fns | `refactor` |
| Changes to `go.mod`, `package.json` | `chore` |
| Comment-only, `.md` files | `docs` |
| Benchmark changes | `perf` |

### Scope detection
| File pattern | Scope |
|-------------|-------|
| `src/api/*`, `routes/*` | `api` |
| `src/db/*`, `internal/store/*` | `db` |
| `src/auth/*` | `auth` |
| `frontend/src/components/*` | `ui` |
| `deploy/*`, `.github/*` | `deploy` |

### Rules
1. Summary: imperative mood, ≤ 50 chars, lowercase start, no period
2. Body: explain WHAT + WHY (not HOW — that's the diff)
3. Breaking change: if public API changes → `BREAKING CHANGE:` in footer + `!` after type
4. Evidence: `git diff --stat` before crafting
5. If multiple unrelated changes → suggest splitting commits
