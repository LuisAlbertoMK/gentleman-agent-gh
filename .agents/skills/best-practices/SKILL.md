---
name: best-practices
description: "Apply modern web development best practices for security, compatibility, and code quality."
triggers: "best practices, security audit, modernize code, code quality, check vulnerabilities"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 4600
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
| "Compat como afterthought" | Headers/features sin verificar Context7 | Context7 current API + W3C Validator + Mozilla Observatory |
| "Security checklist solo al final" | Audit solo pre-deploy | `npm audit --json` + SecurityHeaders.com + OWASP Top 10 continuo |
| "Copy headers blindly" | Headers sin verificar FP / SRI faltante | SRI `openssl dgst -sha384` + CSP nonce + Permissions-Policy verify |

## Red Flags
- `npm audit` alone without supply-chain check (postinstall/typosquat) → BLOCKER for deploy until postinstall/typosquat reviewed
- Permissions requested before user action without explanation → STOP and require user action + explanation first

## Verification
- `web-quality-audit` skill checklist PASS + Lighthouse score
- Headers verified via `SecurityHeaders.com` + OWASP Top 10 mapping

## Refs: MDN Web Security | OWASP Top 10 | web-quality-audit skill

## Anti-Patterns
Blindly copy-paste headers without verifying · Ignore FP alerts · Apply all rules to every project · No Context7 check for current API versions · Skip audit step

## SPA Playbook (web/XSS/deps)
XSS: contextual encoding (HTML/attr/JS/URL) | NO dangerouslySetInnerHTML/v-html (DOMPurify + tag/attr allowlist if forced) | DOM clobbering: never trust window[userKey]/named-element lookups - use getElementById + validate id/name | textContent > innerHTML
CSP essentials: default-src 'none'; script-src 'self' nonce (NO unsafe-inline/eval); object-src 'none'; base-uri 'self'; frame-ancestors 'self'; upgrade-insecure-requests | validate headers pre-deploy
Open redirect: allowlist or same-origin prefix check on ?next=/returnUrl (reject //evil.com, protocol-relative), else 302 / | postMessage: verify event.origin === expected + message shape BEFORE use; never send auth tokens via postMessage
Deps: npm audit --audit-level=high in CI (fail build) | lockfile committed + exact pin | overrides/resolutions for vulnerable transitive | npm ls typosquat check
Service Workers: register ONLY same-origin exact URL (never remote/cross-origin) + explicit scope (no scope widening) | CSP worker-src 'self' (no blob:/data:) | SRI N/A on SW script -> pin immutable versioned path | audit existing SWs (devtools > Application > Service Workers): unregister unknown/3rd-party (persist after uninstall)
DOM clobbering form/iframe: named <form>/<iframe> shadow window/document (form.action, iframe.name, attributes) - getElementById + id/name allowlist only, FormData over form.action/name lookups, never window[formName|iframeName]
> changelog: odd/tasks/mejora-security.md (2026-09-18, slice 6)
> changelog: odd/tasks/mejora-security.md (2026-09-18, slice 2)

---

> See [reference.md](docs/skills/best-practices/reference.md) for extended details, examples, and detailed patterns.
