---
name: security-scanner
description: "Pre-commit security scan - secrets, injection patterns, dependency vulnerabilities, supply chain risks, API usage."
triggers: "Security, seguridad, vulnerabilidad, auditar, safe check, harden"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 2950
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
## API REST Playbook
OWASP23: API1 BOLA -> per-object authz | API2 authn -> JWT (auth-hardening) | API3 BOPLA -> allowlist parse | API4 -> rate.limit per-IP+user | API7 SSRF -> webhook/callback URL allowlisted host+scheme only
Rate-limit+lockout: key IP+user, NOT client X-Forwarded-For (spoof bypass) | 429+Retry-After | N fails -> lockout
Errors: no stack/params/SQL echo - generic 400/500 + err-id, debug OFF | Pag/bulk: cap page size, opaque cursor, per-item authz
> changelog: odd/tasks/mejora-security.md (2026-09-18, slice 1)
## Refs
quality-gate · best-practices · command-wrapper · research · code-review-agent · llm-security · auto-metrics · external-auditor · immune-system
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "No secrets in this repo" | Skipping secrets scan | `grep -rn "process.env\|apiKey\|password" --include="*.{js,ts,go,py}"` on staged files |
| "npm audit is enough" | Only `npm audit`, no supply chain | Check postinstall/typosquat + `npm ls --all` (rule 1: tool first + manual) |
| "Medium can wait" | Deferring MEDIUM | Medium→suggest now, CRITICAL+HIGH fix before commit (rule 2) |

## Red Flags
- Flagging `process.env` vars as secrets without verifying FP → STOP, verify rule 3
- No risk summary `NONE/LOW/MED/HIGH` at end → reject, add summary per rule 5

## Verification
- Scan output format `Secrets:{N} Injection:{N} ... | CRITICAL/HIGH...` with `file:line` + fix per issue
- `security-audit-mcp.ps1` (P0-2) as pre-flight for MCP configs; `llm-security` skill for prompt injection

## Anti-Patterns
Flag env vars as secrets · Skip dependency audit · Fix without solution · Ignore medium · No risk summary · npm audit alone (miss supply chain)
> docs/skills/security-scanner/reference.md
