---
name: best-practices
description: Apply modern web development best practices for security, compatibility, and code quality. Use when asked to "apply best practices", "security audit", "modernize code", "code quality review", or "check for vulnerabilities".
license: MIT
metadata:
  author: web-quality-skills
  version: "1.2"
---

# Best practices

Modern web dev standards — security, compatibility, code quality.

## Security

**HTTPS & HSTS**: No mixed content. `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`

**CSP**:
`default-src 'self'; script-src 'self' 'nonce-{random}' https://trusted.com; style-src 'self' 'nonce-{random}'; img-src 'self' data: https:; connect-src 'self' https://api.example.com; frame-ancestors 'self'; base-uri 'self'; form-action 'self'`

**Trusted Types**: `require-trusted-types-for 'script'` — roll out via Report-Only first. React 19+ produces TrustedHTML natively.

**SRI**: Every third-party `<script>`/`<link>` needs `integrity` hash. Generate: `openssl dgst -sha384 -binary file.js | openssl base64 -A`

**Security headers**:
`X-Frame-Options: DENY` · `X-Content-Type-Options: nosniff` · `Referrer-Policy: strict-origin-when-cross-origin` · `Permissions-Policy: geolocation=(), microphone=(), camera=()`
Do NOT use `X-XSS-Protection` (deprecated, introduced vulns).

**Deps**: `npm audit` regularly · avoid prototype pollution (`structuredClone()` for untrusted merges) · prefer `textContent` over `innerHTML` (or DOMPurify) · cookies: `Secure; HttpOnly; SameSite=Strict; Path=/`

## Browser compatibility
`<!DOCTYPE html>` · `<meta charset="UTF-8">` (first in `<head>`) · `<meta name="viewport" content="width=device-width, initial-scale=1">` · Feature detect (`'IntersectionObserver' in window`), not UA sniff · Polyfill at build time (Babel/core-js), NOT from third-party CDN (polyfill.io was compromised 2024)

## Deprecated APIs
| Replace | With |
|---------|------|
| `document.write()` | Dynamic script loading |
| Sync XHR | `fetch()` |
| AppCache | Service Workers |
| Non-passive touch/wheel | `{ passive: true }` |

## Console & errors
No console.log in prod. Error tracking (Sentry/Bugsnag). React: `ErrorBoundary`. Global: `error` + `unhandledrejection` handlers.

## Source maps
Prod: `sourcemap: 'hidden'` (Vite) or `devtool: 'hidden-source-map'` · Strip `sourcesContent` from error tracker uploads.

## Code quality
Valid HTML (no dup IDs) · Semantic HTML5 (`<header>`, `<nav>`, `<main>`) · Explicit image dimensions · Event delegation · Memory cleanup via `AbortController` + `useEffect` return

## Permissions
Request geolocation/camera/mic only after user action + explanation. `Permissions-Policy` restricts by default.

## Audit checklist
**Security**: HTTPS · no mixed content · `npm audit` clean · CSP (frame-ancestors, base-uri, form-action) · Trusted Types · SRI on third-party · HSTS + security headers · no exposed source maps
**Compat**: HTML5 doctype · charset · viewport · no deprecated APIs · passive listeners
**Quality**: no console errors · valid HTML · semantic elements · error handling · memory cleanup
**UX**: no intrusive interstitials · contextual permissions · image aspect ratios

## Tools
`npm audit` · [SecurityHeaders.com](https://securityheaders.com) · [W3C Validator](https://validator.w3.org) · Lighthouse · [Observatory](https://observatory.mozilla.org)

## Refs
[MDN Web Security](https://developer.mozilla.org/en-US/docs/Web/Security) · [OWASP Top 10](https://owasp.org/www-project-top-ten/) · [Web Quality Audit](../web-quality-audit/SKILL.md)
