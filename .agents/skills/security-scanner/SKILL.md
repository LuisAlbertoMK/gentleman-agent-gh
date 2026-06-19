---
name: security-scanner
description: "Pre-commit security scan — detect secrets, injection patterns, dependency vulnerabilities, and dangerous API usage"
triggers: "Security, seguridad, vulnerabilidad, auditar"
license: Apache-2.0
metadata:
  tags:
    - security
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.0->1.1 (sprint 5: 78->60 lines
---

Pre-commit security scan: secrets, injection patterns, dependency vulns, dangerous APIs.Trigger: "security", "seguridad", "vulnerabilidad", "auditar", "safe check", "harden".
## WhenBefore committing sensitive code, deploying, or user asks "is this secure"
## Scan Dimensions| Category | Detection ||----------|-----------|| **Secrets** | `grep: sk-[a-zA-Z0-9]+, BEGIN.*KEY, password\s*=` || **Injection** | Concatenated queries, raw `exec()` || **Sensitive APIs** | `eval()`, `exec()`, `unsafe`, `os/exec` || **Dependencies** | `go list -m` + `npm audit` + safety check || **Config** | Debug mode, permissive CORS, no HTTPS || **File access** | Path traversal, symlink attacks |
## Quick patterns by language**Go:**
```grep -rn "apiKey\|password\|secret" --include="*.go" | grep -v "_test\|\.env\|mock"grep -rn "sql\.Exec\|\.Raw(" --include="*.go" | grep -v "_test"grep -rn "os/exec" --include="*.go"```**JS/TS:**```grep -rn "process\.env\.\|apiKey\|password" --include="*.{js,ts}" | grep -v "\.env\|\.config\|test"grep -rn "eval(\|exec(\|shelljs\|child_process" --include="*.{js,ts}"npm audit --json```**Python:**```grep -rn "os\.environ\[\|password\|secret\|api_key" --include="*.py" | grep -v "_test\|\.env\|test_"grep -rn "eval(\|exec(\|subprocess\." --include="*.py"```
## Output
```
## Security Scan: {scope}
### Summary- Secrets: {N} | Injection: {N} | Dangerous APIs: {N} | Vuln deps: {N}
### Issues (CRITICAL/HIGH/MEDIUM/LOW)#
### CRITICAL: {type} in {file:line}- Pattern: `{found}` → Fix: `{suggested fix}
````
## Rules1. Run `grep` BEFORE manual inspection. Tool first.2. Critical+High → must fix before commit. Medium → suggest.3. Verify false positives — don't auto-flag env vars4. Issues found? Always provide fix, not just warning5. End with: "Remaining risk: NONE/LOW/MED/HIGH (why)"
## EXAMPLE OUTPUT
```markdown
## Security Scan: src/handlers/
### Summary
- Secrets: 1 | Injection: 0 | Dangerous APIs: 1 | Vuln deps: 0
### Issues
# CRITICAL: Hardcoded API key in config.go:15
- Pattern: `apiKey := "sk-abc123"` → Fix: use env var
```
