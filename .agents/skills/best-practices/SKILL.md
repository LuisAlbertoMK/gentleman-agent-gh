---
name: best-practices
description: Apply modern web development best practices for security, compatibility, and code quality.
triggers: "best practices, security audit, modernize code, code quality, check vulnerabilities"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 3000
---

## When to Use
Apply modern web development best practices for security, compatibility, and code quality.

# Best practices — modern web dev standards
## Security
HTTPS+HSTS: No mixed. Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
CSP: default-src self; script-src self nonce-{random}; style-src self nonce-{random}; img-src self data: https:; connect-src self; frame-ancestors self; base-uri self; form-action self
Trusted Types: require-trusted-types-for script via Report-Only. React 19+ produces TrustedHTML.
SRI: Every third-party script/link needs integrity hash: openssl dgst -sha384 -binary file.js | openssl base64 -A
Headers: X-Frame-Options:DENY | X-Content-Type-Options:nosniff | Referrer-Policy:strict-origin-when-cross-origin | Permissions-Policy:geolocation=(),mic=(),camera=(). No X-XSS-Protection.
Deps: npm audit | structuredClone() for untrusted merges | textContent over innerHTML | Cookies: Secure+HttpOnly+SameSite=Strict+Path=/
## Quality
Valid HTML(no dup IDs) | Semantic HTML5 | Explicit img dims | Event delegation | Memory cleanup via AbortController+useEffect return
## Permissions: Request geo/camera/mic after user action+explanation. Permissions-Policy restricts by default.
## Tools: npm audit | SecurityHeaders.com | W3C Validator | Lighthouse | Mozilla Observatory
## Anti-Rationalization

| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Best practices are overkill here" | Skipping audit for small project | Even small project → `web-quality-audit` checklist (perf/accessibility/SEO) |
| "It works, so it's secure" | No `npm audit` / `SecurityHeaders.com` check | `npm audit --json` + `SecurityHeaders.com` + W3C Validator before ship |
| "Copy headers blindly" | Headers without verifying FP alerts | Context7 current API versions + `Mozilla Observatory` score |

## Red Flags
- `npm audit` alone without supply-chain check (postinstall/typosquat)
- Permissions requested before user action without explanation

## Verification
- `web-quality-audit` skill checklist PASS + Lighthouse score
- Headers verified via `SecurityHeaders.com` + OWASP Top 10 mapping

## Refs: MDN Web Security | OWASP Top 10 | web-quality-audit skill

## Anti-Patterns
Blindly copy-paste headers without verifying · Ignore FP alerts · Apply all rules to every project · No Context7 check for current API versions · Skip audit step

---

> See [reference.md](docs/skills/best-practices/reference.md) for extended details, examples, and detailed patterns.
