# Gap Analysis: Website / Web App

> Weighted checklist for public-facing web applications.

## Layer Weights
UX ████████ 40% · Technical ███████ 30% · Security ██████ 25%
Functional █████ 20% · Ops █████ 20% · Business ██████ 25%

## Functional
- [ ] Core user journey mapped? (landing → action → success)
- [ ] Content: SEO-optimized? Structured data? Sitemap?
- [ ] Forms: validation? error states? confirmation?
- [ ] Search: full-text? filters? pagination?
- [ ] Internationalization (i18n)? Localization (l10n)? RTL?

## Technical
- [ ] SSR/SSG/CSR? Correct for use case?
- [ ] Performance: Lighthouse score? Core Web Vitals?
- [ ] Bundle size? Code splitting? Tree shaking?
- [ ] Images: lazy load? WebP/AVIF? responsive?
- [ ] Caching: CDN? browser cache? service worker?
- [ ] SEO: meta tags? canonical? Open Graph? JSON-LD?

## Security
- [ ] HTTPS everywhere? HSTS? CSP headers?
- [ ] XSS protection? CSRF tokens?
- [ ] Form validation: client + SERVER side?
- [ ] Auth: session management? password policies?
- [ ] Third-party scripts: audited? Subresource Integrity?

## UX
- [ ] Loading states for EVERY async action?
- [ ] Empty states: helpful, not confusing?
- [ ] Error messages: human-readable? actionable?
- [ ] 404 page: useful? search? navigation?
- [ ] Mobile responsive? Touch targets ≥48px?
- [ ] Accessibility: WCAG 2.1 AA? Keyboard navigable?
- [ ] Forms: autofill? error inline? progress saved?

## Ops
- [ ] CI/CD: build→test→deploy automated?
- [ ] Uptime monitoring? Synthetic checks?
- [ ] Error tracking: real-time? source maps?
- [ ] Analytics: page views? conversions? funnels?
- [ ] A/B testing capability?

## Business
- [ ] Conversion funnel tracked? Drop-off points identified?
- [ ] SEO: indexed pages? organic traffic? backlinks?
- [ ] Content fresh? Blog updated? Case studies?
- [ ] Landing page: clear value prop? CTA above fold?
