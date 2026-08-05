---
name: best-practices
description: Apply modern web development best practices for security, compatibility, and code quality.
triggers: "best practices, security audit, modernize code, code quality, check vulnerabilities"
---

## When to Use
Apply modern web development best practices for security, co

# Best practices — modern web dev standards
## Security
HTTPS+HSTS: No mixed. Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
CSP: default-src self; script-src self nonce-{random}; style-src self nonce-{random}; img-src self data: https:; connect-src self; frame-ancestors self; base-uri self; form-action self
Trusted Types: require-trusted-types-for script via Report-Only. React 19+ produces TrustedHTML.
SRI: Every third-party script/link needs integrity hash: openssl dgst -sha384 -binary file.js | openssl base64 -A
Headers: X-Frame-Options:DENY | X-Content-Type-Options:nosniff | Referrer-Policy:strict-origin-when-cross-origin | Permissions-Policy:geolocation=(),mic=(),camera=(). No X-XSS-Protection.
Deps: npm audit | structuredClone() for untrusted merges | textContent over innerHTML | Cookies: Secure+HttpOnly+SameSite=Strict+Path=/
## Browser Compat
<!DOCTYPE html> | meta charset="UTF-8" (first in head) | viewport meta | Feature detect, not UA sniff | Build-time polyfill (Babel), NOT third-party CDN (polyfill.io compromised 2024)
## Deprecated
document.write() -> dynamic script | Sync XHR -> fetch() | AppCache -> Service Workers | Non-passive touch/wheel -> {passive:true}
## Console & Errors
No console.log in prod. Error tracking (Sentry/Bugsnag). React: ErrorBoundary. Global: error+unhandledrejection handlers.
## Source Maps
Prod: sourcemap:hidden(Vite)/devtool:hidden-source-map. Strip sourcesContent from tracker uploads.
## Quality
Valid HTML(no dup IDs) | Semantic HTML5 | Explicit img dims | Event delegation | Memory cleanup via AbortController+useEffect return
## Permissions: Request geo/camera/mic after user action+explanation. Permissions-Policy restricts by default.
## Audit: HTTPS | npm audit clean | CSP | Trusted Types | SRI | HSTS+headers | no deprecated APIs | passive listeners | no console errors | valid HTML | error handling | no interstitials
## Tools: npm audit | SecurityHeaders.com | W3C Validator | Lighthouse | Mozilla Observatory
## Refs: MDN Web Security | OWASP Top 10 | web-quality-audit skill

## Anti-Patterns
Blindly copy-paste headers without verifying · Ignore FP alerts · Apply all rules to every project · No Context7 check for current API versions · Skip audit step

Generate nonce: `$nonce = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16))`
