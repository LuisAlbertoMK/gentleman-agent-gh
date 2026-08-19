# Best Practices — Extended Reference

> This file contains verbose examples, testing patterns, edge cases, and anti-patterns externalized from `SKILL.md` to keep the main skill under 5KB. See [SKILL.md](../../../.agents/skills/best-practices/SKILL.md) for the core security, compatibility, and quality rules.

---

## Examples (5)

### 1. Complete CSP with Nonce + Trusted Types
```html
<meta http-equiv="Content-Security-Policy"
  content="default-src 'self';
    script-src 'self' 'nonce-{NONCE}' 'strict-dynamic';
    style-src 'self' 'nonce-{NONCE}';
    img-src 'self' data: https:;
    connect-src 'self';
    frame-ancestors 'self';
    base-uri 'self';
    form-action 'self';
    trusted-types default;">
```
Server sets nonce per request; React 19+ auto-produces TrustedHTML.

### 2. SRI for Third-Party Scripts
```html
<script src="https://cdn.example.com/analytics.js"
  integrity="sha384-oqVuAfXRKap7fdgcCY5uykM6+R9GqQ8K/uxp..."
  crossorigin="anonymous"></script>
```
Generate: `openssl dgst -sha384 -binary analytics.js | openssl base64 -A`

### 3. Secure Cookie Pattern
```js
res.cookie('session', token, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict',
  path: '/',
  maxAge: 1000 * 60 * 60 * 24 // 24h
});
```

### 4. AbortController Cleanup in React
```jsx
useEffect(() => {
  const controller = new AbortController();
  fetch('/api/data', { signal: controller.signal })
    .then(r => r.json())
    .then(setData);
  return () => controller.abort();
}, []);
```

### 5. Passive Event Listeners
```js
element.addEventListener('wheel', handler, { passive: true });
element.addEventListener('touchstart', handler, { passive: true });
```

---

## Testing Patterns (3)

### 1. CSP Header Validation (Jest + Supertest)
```js
test('CSP header present with nonce', async () => {
  const res = await request(app).get('/');
  expect(res.headers['content-security-policy']).toMatch(/script-src.*nonce-/);
  expect(res.headers['content-security-policy']).toMatch(/trusted-types/);
});
```

### 2. SRI Integrity Check (Playwright)
```js
test('Third-party scripts have integrity attribute', async ({ page }) => {
  await page.goto('/');
  const scripts = await page.locator('script[src^="https://"]').all();
  for (const script of scripts) {
    await expect(script).toHaveAttribute('integrity');
  }
});
```

### 3. Cookie Security Flags (Supertest)
```js
test('Session cookie has Secure+HttpOnly+SameSite=Strict', async () => {
  const res = await request(app).post('/login').send(creds);
  const cookie = res.headers['set-cookie'][0];
  expect(cookie).toMatch(/HttpOnly/);
  expect(cookie).toMatch(/Secure/);
  expect(cookie).toMatch(/SameSite=Strict/);
});
```

---

## Edge Cases (4)

### 1. Nonce Regeneration on Every Request
Nonce must be unique per response — reuse breaks CSP. Generate in middleware, inject into template.

### 2. Trusted Types Report-Only vs Enforced
Start with `Content-Security-Policy-Report-Only: trusted-types default` to collect violations before enforcing.

### 3. Subresource Integrity on Dynamic Imports
```js
const mod = await import(/* @integrity "sha384-..." */ './module.js');
```
Vite/Rollup: `output.manualChunks` + `experimentalRenderBuiltUrl` for auto-SRI.

### 4. HSTS Preload Submission Requirements
`max-age=31536000; includeSubDomains; preload` — must serve HTTPS on ALL subdomains, no mixed content, valid cert chain. Submit to hstspreload.org after 1+ week verification.

---

## Anti-Patterns (Extended)

### 1. Copy-Paste Security Headers Without Context
Applying `X-Frame-Options: DENY` breaks legitimate iframe embeds (payment widgets, auth providers). Use `frame-ancestors` in CSP instead — granular control.

### 2. Treating All npm Audit Findings as Blockers
`npm audit` flags devDependencies and transitive deps that may not reach production. Filter: `npm audit --omit=dev --audit-level=high` + manual review of reachable paths.

---

## Utility: Generate Nonce
```powershell
$nonce = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(16))
```