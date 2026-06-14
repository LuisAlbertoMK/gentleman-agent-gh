---
name: best-practices
description: Apply modern web development best practices for security, compatibility, and code quality. Use when asked to "apply best practices", "security audit", "modernize code", "code quality review", or "check for vulnerabilities".
license: MIT
metadata:
  author: web-quality-skills
  version: "1.1"
---

# Best practices

Modern web development standards. Para ejemplos de código completos, ver `references/`.

## Security

### HTTPS & HSTS
- No mixed content — all resources over HTTPS. Protocol-relative URLs (`//example.com`) are legacy.
- HSTS header: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`

### Content Security Policy (CSP)
```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}' https://trusted.com;
  style-src 'self' 'nonce-{random}';
  img-src 'self' data: https:;
  connect-src 'self' https://api.example.com;
  frame-ancestors 'self';
  base-uri 'self';
  form-action 'self';
```

### Trusted Types (DOM-XSS defense)
`Content-Security-Policy: require-trusted-types-for 'script'; trusted-types default;`
Roll out with `Content-Security-Policy-Report-Only` first. React 19+ produces TrustedHTML natively.

### Subresource Integrity (SRI)
All third-party `<script>` and `<link rel="stylesheet">` need `integrity` hash:
```html
<script src="https://cdn.example.com/lib.js"
        integrity="sha384-{base64-hash}"
        crossorigin="anonymous"></script>
```
Generate: `openssl dgst -sha384 -binary file.js | openssl base64 -A`

### Security headers
```
X-Frame-Options: DENY                                           # clickjacking (legacy; prefer CSP frame-ancestors)
X-Content-Type-Options: nosniff                                 # MIME sniffing
Referrer-Policy: strict-origin-when-cross-origin                 # referrer
Permissions-Policy: geolocation=(), microphone=(), camera=()     # feature restriction
```
**Do NOT use** `X-XSS-Protection` — deprecated and introduced vulns in some browsers.

### Dependencies & input
- `npm audit` regularly, auto-fix with `npm audit fix`
- Avoid prototype pollution: use `structuredClone()` or null-prototype objects for untrusted deep merges
- Use `element.textContent` over `innerHTML`; if HTML is needed, use DOMPurify
- Cookies: `Secure; HttpOnly; SameSite=Strict; Path=/`

## Browser compatibility

| Element | Rule |
|---------|------|
| Doctype | `<!DOCTYPE html>` |
| Charset | `<meta charset="UTF-8">` as first element in `<head>` |
| Viewport | `<meta name="viewport" content="width=device-width, initial-scale=1">` |
| Feature detection | `'IntersectionObserver' in window` — not UA sniffing |
| Polyfills | Bundle at build time (Babel/core-js). Never load from third-party CDN (polyfill.io was compromised in 2024). |

## Deprecated APIs to avoid
| Replace | With |
|---------|------|
| `document.write()` | Dynamic script loading |
| Synchronous XHR | `fetch()` (async) |
| Application Cache | Service Workers |
| Non-passive touch/wheel | `{ passive: true }` (or `false` if `preventDefault` needed) |

## Console & errors
- No console.log in production. Use error tracking (Sentry, Bugsnag).
- React: `ErrorBoundary` component with `componentDidCatch`
- Global: `window.addEventListener('error', handler)` + `unhandledrejection`

## Source maps
- Production: `sourcemap: 'hidden'` (Vite) or `devtool: 'hidden-source-map'`
- Strip `sourcesContent` from maps uploaded to error trackers

## Code quality
- **Valid HTML**: no duplicate IDs, proper nesting
- **Semantic HTML5**: `<header>`, `<nav>`, `<main>`, `<section>`, `<article>` over `<div>`
- **Image aspect ratios**: preserve with explicit `width` + `height` or `object-fit`
- **Event delegation**: container-level listener vs per-element handlers
- **Memory cleanup**: `AbortController` for event listeners, cleanup in `useEffect` return

## Permissions
- Request geolocation/camera/mic only after user action + explanation
- Permissions-Policy restricts capabilities by default

## Audit checklist

### Security (critical)
- [ ] HTTPS enabled, no mixed content
- [ ] No vulnerable dependencies (`npm audit`)
- [ ] CSP with `frame-ancestors`, `base-uri`, `form-action`
- [ ] Trusted Types enforced (or report-only during rollout)
- [ ] Third-party scripts pinned with SRI hashes
- [ ] Security headers: HSTS, X-Content-Type-Options, Referrer-Policy
- [ ] No exposed source maps in production

### Compatibility
- [ ] HTML5 doctype + charset first in head + viewport meta
- [ ] No deprecated APIs
- [ ] Passive event listeners for scroll/touch

### Code quality
- [ ] No console errors in production
- [ ] Valid HTML, semantic elements
- [ ] Proper error handling + memory cleanup

### UX
- [ ] No intrusive interstitials
- [ ] Permission requests in context after user action
- [ ] Appropriate image aspect ratios (no layout shift)

## Tools

| Tool | Purpose |
|------|---------|
| `npm audit` | Dependency vulnerabilities |
| [SecurityHeaders.com](https://securityheaders.com) | Header analysis |
| [W3C Validator](https://validator.w3.org) | HTML validation |
| Lighthouse | Best practices audit |
| [Observatory](https://observatory.mozilla.org) | Security scan |

## References

- [MDN Web Security](https://developer.mozilla.org/en-US/docs/Web/Security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Web Quality Audit](../web-quality-audit/SKILL.md)
