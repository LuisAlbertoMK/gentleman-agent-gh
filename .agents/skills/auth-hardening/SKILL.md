---
name: auth-hardening
description: "Trigger: auth, JWT, OAuth, RBAC, CSRF, session, login, password hashing. Audit and harden auth flows."
triggers: "auth, authentication, authorization, JWT, OAuth, RBAC, CSRF, session, login, password hashing, token, cookie"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use
Review auth flows, login, tokens, RBAC — "is this auth secure?"

## TESTING (3 patterns)
Auth integration: test DB → `POST /login` → 200 + `Set-Cookie: session=...; HttpOnly; Secure; SameSite=Lax`
Token validation: expired JWT→401; `alg=none`→401; wrong aud→403
RBAC matrix: parametrize roles×endpoints → 200 allowed, 403 denied, no 500s

## CHECKLIST (sev: pattern)
CRIT: JWT alg=none `algorithm.*["']none["']` | Hardcoded secret `secret\s*=\s*["'][^"']+["']` excl env | MD5/SHA1 password `md5\|sha1`
HIGH: No CSRF on POST | OAuth no PKCE `auth_code` w/o `code_verifier` | No HttpOnly `httpOnly.*false` | JWT no expiry `expiresIn` missing/>24h | Role after fetch | No refresh rotation
MED: Session fixation (login doesn't regenerate ID)

## OUTPUT
```
## Auth Hardening: {scope}
### Summary
- JWT:{N} OAuth:{N} RBAC:{N} CSRF:{N} Sessions:{N} Passwords:{N}
### Issues
# CRITICAL: {type} in {file:line}
- Pattern: `{found}` → Fix: `{fix}`
```

## Rules
1. JWT alg FIRST. 2. Role checks BEFORE data. 3. CSRF on ALL state-changing. 4. bcrypt/argon2 ONLY. 5. "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Refs
security-scanner · best-practices · quality-gate · code-review-agent

## Anti-Patterns (8)
Flag bcrypt weak · Skip JWT alg · Happy path only · Ignore refresh tokens · Client-side-only roles · Flag env vars hardcoded · Use `alg: none` for testing · Store JWT in localStorage
## Reference
> docs/skills/auth-hardening/reference.md
