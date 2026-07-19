---
name: auth-hardening
description: "Trigger: auth, authentication, authorization, JWT, OAuth, RBAC, CSRF, session, login, password hashing. Audit and harden authentication and authorization."
license: Apache-2.0
metadata:
  tags: [security]
  author: gentleman-vMK
  version: "1.2"
  changelog: "1.2: aggressive compression — 775→~580 tokens · 1.1: Karpathy · 1.0: initial"
---
## WHEN: Reviewing auth flows, login/signup, token handling, RBAC, or "is this auth secure"

## SCAN DIMENSIONS

**JWT**: `grep -rn "jwt\|jsonwebtoken\|jose\|JwtBearer" --include="*.{ts,js,py,go}"` → alg none/HS256=WEAK (prefer RS256/ES256), expiry, audience, key rotation
**OAuth**: `grep -rn "oauth\|oidc\|pkce\|redirect_uri\|authorization_code" --include="*.{ts,js,py,yaml,yml}"` → PKCE enforced, redirect URI exact match, state param
**RBAC**: `grep -rn "role\|permission\|authorize\|canAccess\|isAllowed" --include="*.{ts,js,py,go}"` → role checks BEFORE data access, no client-side-only enforcement
**CSRF**: `grep -rn "csrf\|xsrf\|SameSite\|csrfToken\|double.*submit" --include="*.{ts,js,py,yaml,yml}"` → SameSite=Strict/Lax, token on state-changing ops
**Sessions**: `grep -rn "session\|cookie\|express-session\|cookie-session" --include="*.{ts,js,py,yaml,yml}"` → HttpOnly+Secure+SameSite, fixation prevention, rotation on login
**Passwords**: `grep -rn "bcrypt\|argon2\|scrypt\|pbkdf2\|md5\|sha1" --include="*.{ts,js,py,go}"` → bcrypt/argon2=OK, MD5/SHA1=CRITICAL

## VULNERABILITY CHECKLIST

| Check | Sev | Pattern |
|-------|-----|---------|
| JWT alg=none | CRIT | `algorithm.*none` or missing `algorithms` param |
| Hardcoded JWT secret | CRIT | `secret\s*=\s*["']` in source |
| MD5/SHA1 password hash | CRIT | `md5\|sha1` in password context |
| No CSRF on POST | HIGH | POST handler without CSRF middleware |
| OAuth missing PKCE | HIGH | authorization_code without code_verifier |
| Session missing HttpOnly | HIGH | `httpOnly.*false` or missing |
| JWT no expiry | HIGH | `expiresIn` missing or >24h |
| Role check after fetch | HIGH | SELECT/GET before authorize |

## OUTPUT FORMAT

```
## Auth Hardening: {scope}
### Summary
- JWT: {N} | OAuth: {N} | RBAC: {N} | CSRF: {N} | Sessions: {N} | Passwords: {N}
### Issues (CRITICAL/HIGH/MEDIUM/LOW)
# CRITICAL: {type} in {file:line}
- Pattern: `{found}` → Fix: `{fix}`
```

## RULES
1. JWT algorithm FIRST — alg=none bypasses all auth. 2. Role checks BEFORE data access. 3. CSRF on ALL state-changing endpoints. 4. bcrypt/argon2 ONLY. 5. End: "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Refs
security-scanner · best-practices · quality-gate · code-review-agent

## Anti-Patterns
Flag bcrypt as weak · Skip JWT algorithm check · Only test happy path · Ignore refresh token security · Miss client-side-only role checks
