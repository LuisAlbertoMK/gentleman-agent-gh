---
name: doc-sync
description: >
  Detect API/signature/config changes and suggest doc updates.
  Trigger: "doc sync", "documentación", "docs", "readme", "sincronizar docs".
license: Apache-2.0
metadata: author: gentleman-vMK, version: "1.0"
---

## When
After changing public APIs, routes, exports, config — before closing task.

## Critical Patterns

### What to watch

| Change | What doc to update | Detection |
|--------|-------------------|-----------|
| Function signature changed | Doc comments, API docs | `git diff` — function declaration line |
| Route added/removed | API docs, README endpoints | `git diff` — route registration |
| Config keys added/removed | Config docs, README env vars | Detect new env var reads |
| Return type changed | Type signatures, contracts | Interface/struct declaration change |
| Package/file renamed | README, import paths | File movement in diff |

### Output format
```
## Doc Sync: {change summary}

### Changes detected
1. `src/api/users.go:22` — `GetUser(id)` now returns `(User, error)` not just `User`
   → Update doc comment + API docs response format

2. `src/router.go:15` — new route `POST /api/v2/orders`
   → Add to README endpoint list

3. `config.go` — new env var `FEATURE_FLAG_NEW_CHECKOUT`
   → Add to config docs

### Suggested updates
- `src/api/users.go` — doc comment needs `@return` update
- `README.md` — section "API Endpoints" needs new route
- `docs/config.md` — add env var with description

### Already synced ✅
- Internal types (`internal/types.go`)
- Test files
```

### Rules
1. Run `git diff` against base branch to detect changes
2. Focus on: public API, config, routes, error types — NOT internal implementation
3. Don't suggest updating docs for private/internal code
4. If no doc changes needed → say "No doc sync required"
5. Always check if a `.md` file exists for the changed component before suggesting
