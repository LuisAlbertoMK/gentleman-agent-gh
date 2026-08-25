---
name: security-scanner
description: "Pre-commit security scan - secrets, injection patterns, dependency vulnerabilities, supply chain risks, API usage."
triggers: "Security, seguridad, vulnerabilidad, auditar, safe check, harden"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1719
---
## When to Use
Pre-commit, pre-deploy, or "is this secure?"
## SCAN DIMENSIONS
Secrets · Injection · Sensitive APIs · Supply chain · Dependencies · Config · File access · API security
## QUICK PATTERNS
Go: `grep -rn "apiKey\|password\|secret\|sql\.Exec\|os/exec" --include="*.go"` · JS/TS: `grep -rn "process\.env\.\|eval(\|child_process" --include="*.{js,ts}"` · Py: `grep -rn "password\|secret\|api_key\|subprocess\." --include="*.py"` · audit: `npm audit --json` · no lockfile = HIGH · postinstall: `grep -rn "postinstall\|preinstall" package.json` · typosquat: `npm ls --all` · API: `grep -rn "rate.limit\|RateLimiter" --include="*.{ts,js,py,go}"` + `grep -rn "zod\|joi\|pydantic"`
## OUTPUT FORMAT
`## Security Scan: {scope} — Secrets:{N} Injection:{N} Supply:{N} API:{N} Vuln:{N} | Issues CRITICAL/HIGH/MEDIUM/LOW: {type} in {file:line} — Pattern: {found} → Fix: {fix}`
## Rules
1. Tool first, then manual. 2. Critical+High fix before commit; Medium→suggest. 3. Verify FPs — don't auto-flag env vars. 4. Always provide fix, not just warning. 5. End with risk summary: NONE/LOW/MED/HIGH (why)
## Refs
quality-gate · best-practices · command-wrapper · research · code-review-agent · llm-security
## Anti-Patterns
Flag env vars as secrets · Skip dependency audit · Fix without solution · Ignore medium · No risk summary · npm audit alone (miss supply chain)
> docs/skills/security-scanner/reference.md
