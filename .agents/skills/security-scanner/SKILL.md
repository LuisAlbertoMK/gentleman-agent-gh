---
name: security-scanner
description: "Pre-commit security scan - secrets, injection patterns, dependency vulnerabilities, supply chain risks, API usage."
triggers: "Security, seguridad, vulnerabilidad, auditar, safe check, harden"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Pre-commit, pre-deploy, or "is this secure?"
## SCAN DIMENSIONS
Secrets · Injection · Sensitive APIs · Supply chain · Dependencies · Config · File access · API security
## QUICK PATTERNS
Go: `grep -rn "apiKey\|password\|secret\|sql\.Exec\|os/exec" --include="*.go"` · JS/TS: `grep -rn "process\.env\.\|eval(\|child_process" --include="*.{js,ts}"` · Py: `grep -rn "password\|secret\|api_key\|subprocess\." --include="*.py"` · audit: `npm audit --json` · no lockfile = HIGH · postinstall: `grep -rn "postinstall\|preinstall" package.json` · typosquat: `npm ls --all` · API: `grep -rn "rate.limit\|RateLimiter" --include="*.{ts,js,py,go}"` + `grep -rn "zod\|joi\|pydantic"`
## EXAMPLES
**1. Secrets — regex + trufflehog**: grep → trufflehog:
`grep -rnE "sk-<20+ALNUM>|<PRIVATE_KEY_HEREDOC>" --include="*.{js,ts,py,go,sh}"` then `trufflehog filesystem . --only-verified`
**2. Injection — SQLi/XSS**:
`grep -rnE "SELECT .*\+|WHERE .*\$|execute\(.*\+" --include="*.{js,ts,py,go}"` → parameterize. XSS: `grep -rnE "innerHTML\s*=|dangerouslySetInnerHTML" --include="*.{js,ts}"` → escape output.
**3. Dep vuln CI — dependabot/npm audit**: `.github/dependabot.yml` npm weekly; gate: `npm audit --audit-level=high || exit 1`
**4. Supply chain — sigstore/cosign**: `cosign verify-blob --signature img.sig --cert img.pem artifact.tar.gz` · `curl -fsSL <url> | sha256sum -c checksums.txt`
## TESTING
**1. FP reduction**: fixtures (`<TEST_FIXTURE>`) vs real secrets → flags only real ones.
**2. Zero-secret CI gate**: `trufflehog filesystem . --only-verified --fail` + `! grep -rnE "sk-<20+ALNUM>" .` → blocks merge.
## EDGE CASES
- **FP secrets**: test fixtures, example.com keys, config samples → exclude by path, not value
- **Encrypted vars**: .env.enc / age / sops → scan ciphertext; never decrypt
- **CI secrets vs leaks**: `<SECRETS_PLACEHOLDER>` = legit ref; committed raw value = leak
- **Timing**: pre-commit = fast per-diff; CI = full history; run both
## OUTPUT FORMAT
```
## Security Scan: {scope}
### Summary
- Secrets: {N} | Injection: {N} | Supply Chain: {N} | API Security: {N} | Vuln deps: {N}
### Issues (CRITICAL/HIGH/MEDIUM/LOW)
# CRITICAL: {type} in {file:line}
- Pattern: `{found}` → Fix: `{fix}`
```
## Rules
1. Tool first, then manual. 2. Critical+High fix before commit; Medium→suggest. 3. Verify FPs — don't auto-flag env vars. 4. Always provide fix, not just warning. 5. End with: "Remaining risk: NONE/LOW/MED/HIGH (why)"
## Refs
quality-gate · best-practices · command-wrapper · research · code-review-agent · llm-security
## Anti-Patterns
Flag env vars as secrets · Skip dependency audit · Fix without solution · Ignore medium · No risk summary · npm audit alone (miss supply chain)
