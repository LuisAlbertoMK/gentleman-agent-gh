---
name: security-scanner
description: >
  Pre-commit security scan: secrets, injection patterns, dependency vulns, dangerous APIs.
  Trigger: "security", "seguridad", "vulnerabilidad", "auditar", "safe check", "harden".
license: Apache-2.0
metadata: author: gentleman-programming, version: "1.0"
---

## When
Before committing sensitive code, before deploying, user asks "is this secure".

## Critical Patterns

### Scan dimensions

| Category | What to check | Detection method |
|----------|--------------|------------------|
| **Secrets** | API keys, tokens, passwords | `grep` patterns: `sk-[a-zA-Z0-9]+`, `BEGIN.*KEY`, `password\s*=` |
| **Injection** | SQL, command, path injection | `grep` for concatenated queries, raw `exec()` |
| **Sensitive APIs** | `eval()`, `exec()`, `unsafe`, `os/exec` | Language-specific dangerous fn calls |
| **Dependencies** | Known vulns | `go list -m` + `npm audit` + safety check |
| **Config** | Debug mode, permissive CORS, no HTTPS | Check env vars, middleware setup |
| **File access** | Path traversal, symlink attacks | Check file read patterns, user-provided paths |

### Quick patterns by language

**Go:**
```
grep -rn "apiKey\|password\|secret" --include="*.go" | grep -v "_test\|\.env\|mock"
grep -rn "sql\.Exec\|\.Raw(" --include="*.go" | grep -v "_test"
grep -rn "os/exec" --include="*.go"
```

**JS/TS:**
```
grep -rn "process\.env\.\|apiKey\|password" --include="*.{js,ts,jsx,tsx}" | grep -v "\.env\|\.config\|test"
grep -rn "eval(\|exec(\|shelljs\|child_process" --include="*.{js,ts}"
npm audit --json
```

**Python:**
```
grep -rn "os\.environ\[\|password\|secret\|api_key" --include="*.py" | grep -v "_test\|\.env\|test_"
grep -rn "eval(\|exec(\|subprocess\." --include="*.py"
```

### Output format
```
## Security Scan: {scope}

### Summary
- Secrets found: 2 ⚠️
- Injection risks: 0 ✅
- Dangerous APIs: 0 ✅
- Vuln dependencies: 0 ✅

### Issues (severity: CRITICAL / HIGH / MEDIUM / LOW)

#### CRITICAL: API key in source code
- File: src/config.go:15
- Pattern: `apiKey := "sk-..."`  
- Fix: Use env var. `apiKey := os.Getenv("API_KEY")`

#### MEDIUM: Raw SQL query
- File: src/db/users.go:42
- Pattern: `db.Exec("SELECT * FROM users WHERE id = " + userID)`
- Fix: Use parameterized query: `db.Exec("SELECT * FROM users WHERE id = $1", userID)`

### ✅ No issues found in: auth, middleware, routes
```

### Rules
1. Run `grep` patterns BEFORE manual inspection. Tool first.
2. Critical + High → must fix before commit. Medium → suggest fix.
3. Verify false positives manually — don't auto-flag env var assignments
4. If issues found: always provide the fix, not just the warning
5. At end: "Remaining risk: NONE / LOW / MED / HIGH (explain why)"
