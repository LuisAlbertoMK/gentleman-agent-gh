# Gap Analysis: Website / Web App

> Public-facing web application. Weights: UX 40% · Technical 30% · Security 25%.

## 🎨 UI/UX
- [ ] Core journey mapped? (landing → action → success → retention)
- [ ] Loading states for EVERY async action? Skeletons > spinners?
- [ ] Empty states: helpful, not confusing? Actions suggested?
- [ ] Error messages: human-readable, actionable, non-technical?
- [ ] 404 page: useful? Search? Navigation? CTA?
- [ ] Forms: inline validation? autofill? error recovery? progress saved?
- [ ] Visual design consistent? Design system? Typography scale?

## 🔒 Security
- [ ] HTTPS everywhere? HSTS? CSP headers configured?
- [ ] XSS protection? CSRF tokens on all forms?
- [ ] Form validation: client AND server side?
- [ ] Auth: session management? Password policies? Rate limiting?
- [ ] Third-party scripts: audited? SRI hashes?
- [ ] Data: PII collected? Stored? Encryption policy?

## ⚡ Optimization
- [ ] Bundle size? Code splitting by route?
- [ ] Images: lazy load? WebP/AVIF? Responsive srcset?
- [ ] CSS: critical CSS inlined? Unused CSS purged?
- [ ] Fonts: subsetted? display:swap? Preloaded?

## 📈 Performance
- [ ] Lighthouse: ≥90 all categories? Core Web Vitals pass?
- [ ] SSR/SSG/CSR: correct rendering strategy for content type?
- [ ] Caching: CDN? Browser cache headers? Service worker?
- [ ] First Contentful Paint (FCP) < 1.5s? Largest Contentful Paint (LCP) < 2.5s?

## 💾 Resource Usage
- [ ] Memory leaks: tested with DevTools heap snapshot?
- [ ] Network requests: minimized? Batched? Compressed?
- [ ] Storage: localStorage/indexedDB usage justified?

## 🚀 Project Velocity
- [ ] Build time? HMR working? Dev server fast?
- [ ] Content updates: CMS? Markdown? CI-triggered rebuild?
- [ ] CI/CD: build→test→deploy automated?
- [ ] SEO: meta tags, canonical, OG, JSON-LD, sitemap?

## 📱 Responsive Design
- [ ] Mobile-first CSS? Breakpoints defined and tested?
- [ ] Touch targets ≥48px? Forms usable on 320px screen?
- [ ] Tested on real devices (not just DevTools)?
- [ ] Print styles? Print layout usable?
- [ ] Cross-browser: Chrome, Firefox, Safari, Edge tested?

## 🏗️ Infrastructure
- [ ] Hosting: CDN? Edge functions? Proper provider for scale?
- [ ] Uptime monitoring? Synthetic checks? Status page?
- [ ] Error tracking: real-time? Source maps uploaded?
- [ ] Analytics: page views? Conversions? Funnels?
- [ ] A/B testing capability?
