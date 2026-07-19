---
name: auth-hardening
description: "Trigger: auth, authentication, authorization, JWT, OAuth, RBAC, CSRF, session, login, password hashing. Audit and harden authentication and authorization."
license: Apache-2.0
metadata:
  tags: [security]
  author: gentleman-vMK
  version: "1.0"
  changelog: "1.0: initial version — JWT, OAuth, RBAC, CSRF, sessions, password hashing"
---
## WHEN: Reviewing auth flows, login/signup, token handling, RBAC, or user asks "is this auth secure"

## SCAN DIMENSIONS

**JWT**: `grep -rn "jwt\|jsonwebtoken\|jose\|JwtBearer" --include="*.{ts,js,py,go}"` → check algorithm (none/HS256=WEAK, prefer RS256/ES256), expiry, audience validation, key rotation
**OAuth**: `grep -rn "oauth\|oidc\|pkce\|redirect_uri\|authorization_code" --include="*.{ts,js,py,yaml,yml}"` → check PKCE enforced, redirect URI exact match, state parameter, token exchange
**RBAC**: `grep -rn "role\|permission\|authorize\|canAccess\|isAllowed" --include="*.{ts,js,py,go}"` → check role checks BEFORE data access, no client-side-only enforcement, no privilege escalation paths
**CSRF**: `grep -rn "csrf\|xsrf\|SameSite\|csrfToken\|double.*submit" --include="*.{ts,js,py,yaml,yml}"` → check SameSite=Strict/Lax, CSRF token on state-changing ops, double-submit pattern
**Sessions**: `grep -rn "session\|cookie\|express-session\|cookie-session" --include="*.{ts,js,py,yaml,yml}"` → check HttpOnly+Secure+SameSite flags, session fixation prevention, rotation on login, reasonable expiry
**Password Hashing**: `grep -rn "bcrypt\|argon2\|scrypt\|pbkdf2\|md5\|sha1\|crypto.createHash" --include="*.{ts,js,py,go}"` → bcrypt/argon2=OK, MD5/SHA1/SHA256 without salt=CRITICAL

## QUICK PATTERNS

**JS/TS**: `grep -rn "jwt\.sign\|jwt\.verify\|accessToken\|refreshToken" --include="*.{js,ts}"` · `grep -rn "passport\|next-auth\|lucia\|better-auth" --include="*.{js,ts}"`
**Python**: `grep -rn "PyJWT\|jose\|flask-login\|fastapi.*Depends\|django.contrib.auth" --include="*.py"` · `grep -rn "hashlib\|passlib\|bcrypt" --include="*.py"`
**Go**: `grep -rn "jwt-go\|golang-jwt\|oauth2\|casbin" --include="*.go"` · `grep -rn "bcrypt.GenerateFromPassword\|argon2.IDKey" --include="*.go"`

## VULNERABILITY CHECKLIST

| Check | Severity | Pattern |
|-------|----------|---------|
| JWT alg=none allowed | CRITICAL | `algorithm.*none` or missing `algorithms` param in verify |
| Hardcoded JWT secret | CRITICAL | `secret\s*=\s*["']` in source (not env var) |
| MD5/SHA1 password hash | CRITICAL | `md5\|sha1` in password context |
| No CSRF on state-changing POST | HIGH | POST handler without CSRF middleware |
| OAuth missing PKCE | HIGH | authorization_code without code_verifier |
| Session cookie missing HttpOnly | HIGH | `httpOnly.*false` or missing flag |
| JWT no expiry check | HIGH | `expiresIn` missing or very long (>24h for access tokens) |
| Role check after data fetch | HIGH | SELECT/GET before authorize check |
| Session fixation (no rotation) | MEDIUM | Login handler doesn't regenerate session ID |
| Weak refresh token rotation | MEDIUM | Same refresh token usable多次 |
| Missing rate limit on login | MEDIUM | No throttle on auth endpoints |

## OUTPUT FORMAT

```
## Auth Hardening: {scope}
### Summary
- JWT: {N} issues | OAuth: {N} | RBAC: {N} | CSRF: {N} | Sessions: {N} | Passwords: {N}
### Issues (CRITICAL/HIGH/MEDIUM/LOW)
# CRITICAL: {type} in {file:line}
- Pattern: `{found}` → Fix: `{fix}`
```

## RULES
1. Check JWT algorithm BEFORE anything else — alg=none bypasses all auth. 2. Verify role checks are BEFORE data access, not after. 3. CSRF must cover ALL state-changing endpoints (POST/PUT/DELETE/PATCH). 4. Password hashing: bcrypt/argon2 ONLY. 5. End with: "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Refs
security-scanner · best-practices · quality-gate · code-review-agent

## Anti-Patterns
Flag bcrypt as weak (it's not) · Skip JWT algorithm check · Only test happy path auth · Ignore refresh token security · Miss client-side-only role checks
