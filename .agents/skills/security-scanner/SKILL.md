---
name: security-scanner
description: "Pre-commit security scan — detect secrets, injection patterns, dependency vulnerabilities, and dangerous API usage"
triggers: "Security, seguridad, vulnerabilidad, auditar, safe check, harden"
license: Apache-2.0
metadata:
  tags: [security]
  author: gentleman-vMK
  version: "1.1"
---
## WHEN: Before committing sensitive code, deploying, or user asks "is this secure"
## SCAN DIMENSIONS
**Secrets**: `grep: sk-[a-zA-Z0-9]+, BEGIN.*KEY, password\s*=` | **Injection**: Concatenated queries, raw `exec()` | **Sensitive APIs**: `eval()`, `exec()`, `unsafe`, `os/exec` | **Dependencies**: `go list -m` + `npm audit` + safety | **Config**: Debug mode, permissive CORS, no HTTPS | **File access**: Path traversal, symlink attacks
## QUICK PATTERNS
**Go**: `grep -rn "apiKey\|password\|secret" --include="*.go" | grep -v "_test\|\.env\|mock"` · `grep -rn "sql\.Exec\|\.Raw(" --include="*.go" | grep -v "_test"` · `grep -rn "os/exec" --include="*.go"`
**JS/TS**: `grep -rn "process\.env\.\|apiKey\|password" --include="*.{js,ts}" | grep -v "\.env\|\.config\|test"` · `grep -rn "eval(\|exec(\|shelljs\|child_process" --include="*.{js,ts}"` · `npm audit --json`
**Python**: `grep -rn "os\.environ\[\|password\|secret\|api_key" --include="*.py" | grep -v "_test\|\.env\|test_"` · `grep -rn "eval(\|exec(\|subprocess\." --include="*.py"`
## OUTPUT FORMAT
```
## Security Scan: {scope}
### Summary
- Secrets: {N} | Injection: {N} | Dangerous APIs: {N} | Vuln deps: {N}
### Issues (CRITICAL/HIGH/MEDIUM/LOW)
# CRITICAL: {type} in {file:line}
- Pattern: `{found}` → Fix: `{fix}`
```
## RULES
1. Run `grep` before manual inspection. Tool first. 2. Critical+High must fix before commit. Medium→suggest. 3. Verify FPs — don't auto-flag env vars. 4. Issues found? Always provide fix, not just warning. 5. End with: "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Refs
quality-gate · best-practices · command-wrapper · research · code-review-agent

## Anti-Patterns
Flag env vars as secrets · Skip dependency audit · Fix without providing solution · Ignore medium severity · No risk summary
