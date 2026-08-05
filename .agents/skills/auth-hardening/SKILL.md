---
name: auth-hardening
description: "Trigger: auth, JWT, OAuth, RBAC, CSRF, session, login, password hashing. Audit and harden auth flows."
triggers: "auth, authentication, authorization, JWT, OAuth, RBAC, CSRF, session, login, password hashing, token, cookie"
---
## When to Use
Review auth flows, login, tokens, RBAC — "is this auth secure?"
## SCAN DIMENSIONS

**JWT**: `grep -rn "jwt\|jsonwebtoken\|jose" --include="*.{ts,js,py,go}"` → alg (none/HS256=WEAK, prefer RS256/ES256), expiry, audience, rotation
- Alg: `grep -rn "algorithm.*[\"']none[\"']" --include="*.{ts,js,py,go}"`
- Secret: `grep -rn "secret\s*=\s*[\"'][^\"']+[\"']" --include="*.{ts,js,py,go}" | grep -v "process\.env\|env\.\|os\.environ"`
- Refresh: rotation, expiry, reuse detection, revocation
**OAuth**: `grep -rn "oauth\|oidc\|pkce\|redirect_uri\|authorization_code" --include="*.{ts,js,py,yaml,yml}"` → PKCE, exact redirect URI, state param
**RBAC**: `grep -rn "authorize\|canAccess\|isAllowed\|checkPermission\|requireRole" --include="*.{ts,js,py,go}"` → checks BEFORE data access, no client-side-only
**CSRF**: `grep -rn "csrf\|xsrf\|SameSite\|csrfToken" --include="*.{ts,js,py,yaml,yml}"` → SameSite=Strict/Lax, token on state-changing

**Sessions**: `grep -rn "session\|cookie\|express-session" --include="*.{ts,js,py,yaml,yml}"` → HttpOnly+Secure+SameSite, fixation (regenerate on login)
**Passwords**: `grep -rn "bcrypt\|argon2\|scrypt\|pbkdf2" --include="*.{ts,js,py,go}"` → OK | `grep -rn "md5\|sha1" --include="*.{ts,js,py,go}" | grep -v "_test\|checksum\|etag"` → CRITICAL

## CHECKLIST

| Check | Sev | Pattern |
|-------|-----|---------|
| JWT alg=none | CRIT | `algorithm.*["']none["']` or missing `algorithms` param |
| Hardcoded JWT secret | CRIT | `secret\s*=\s*["'][^"']+["']` excl env |
| MD5/SHA1 password | CRIT | `md5\|sha1` in password context |
| No CSRF on POST | HIGH | POST without CSRF middleware |
| OAuth no PKCE | HIGH | auth_code without code_verifier |
| Session no HttpOnly | HIGH | `httpOnly.*false` or missing |
| JWT no expiry | HIGH | `expiresIn` missing or >24h |
| Role check after fetch | HIGH | SELECT/GET before authorize |
| No refresh rotation | HIGH | Same refresh token reusable |
| Session fixation | MED | Login doesn't regenerate ID |

## OUTPUT
```
## Auth Hardening: {scope}
### Summary
- JWT: {N} | OAuth: {N} | RBAC: {N} | CSRF: {N} | Sessions: {N} | Passwords: {N}
### Issues
# CRITICAL: {type} in {file:line}
- Pattern: `{found}` → Fix: `{fix}`
```

## Rules
1. JWT alg FIRST. 2. Role checks BEFORE data. 3. CSRF on ALL state-changing. 4. bcrypt/argon2 ONLY. 5. "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Refs
security-scanner · best-practices · quality-gate · code-review-agent

## Anti-Patterns
Flag bcrypt as weak · Skip JWT alg · Happy path only · Ignore refresh tokens · Client-side-only roles · Flag env vars as hardcoded
