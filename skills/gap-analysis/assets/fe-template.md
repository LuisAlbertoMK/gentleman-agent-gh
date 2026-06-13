# Gap Analysis: Frontend

> Client-side application. Weights: UI/UX 35% · Responsive 20% · Performance 20% · Security 10% · Optimization 15%.

## 🎨 UI/UX
- [ ] Design system: tokens (colors, spacing, typography) in code, not ad-hoc?
- [ ] Component library: reusable, documented (Storybook/ Ladle)?
- [ ] Loading/empty/error states for EVERY async operation?
- [ ] Transitions: meaningful (not decorative), <300ms?
- [ ] Feedback: every user action has visual/haptic response?
- [ ] Internationalization: i18n framework? RTL support?
- [ ] WCAG 2.2 AA: keyboard nav, focus visible, screen reader, contrast ≥4.5:1?
- [ ] Accessibility tested: axe/lighthouse CI pipeline?

## 🔒 Security
- [ ] XSS prevention: CSP headers? React escaping? dangerouslySetInnerHTML audited?
- [ ] CSRF: tokens on state-changing requests?
- [ ] Auth tokens: stored in httpOnly cookies, NOT localStorage?
- [ ] OAuth2 flow: PKCE? redirect validation? state parameter?
- [ ] Input validation: client-side + server-side (not just client)?
- [ ] Dependency vulns: npm audit in CI? Dependabot/Renovate?
- [ ] Secrets: zero API keys in frontend code (proxy through backend)?

## ⚡ Optimization
- [ ] Bundle size: code splitting per route? dynamic imports?
- [ ] Tree shaking: side-effect-free imports? unused exports removed?
- [ ] Image optimization: lazy loading? responsive images (srcset)? WebP/AVIF?
- [ ] Font loading: font-display: swap? subset? variable fonts?
- [ ] CSS: unused CSS purged? critical CSS inlined?
- [ ] Third-party scripts: async/defer? self-hosted where possible?
- [ ] Lighthouse scores: Performance ≥90, Accessibility ≥90, Best Practices ≥90?

## 📈 Performance
- [ ] Core Web Vitals: LCP <2.5s, FID <100ms, CLS <0.1?
- [ ] First paint: FP <1s, FCP <1.5s?
- [ ] Time to Interactive: TTI <3.5s on 3G?
- [ ] Rendering: virtualization for long lists? (react-window, tanstack-virtual)
- [ ] State management: re-renders minimized? memo/useMemo profiled?
- [ ] Network: request waterfall minimized? HTTP/2 or 3? prefetch critical resources?

## 💾 Resource Usage
- [ ] Memory: no leaks in SPA navigation? heap snapshots compared?
- [ ] Storage: IndexedDB/LocalStorage size limits respected?
- [ ] Cache: service worker for offline? Cache API strategy defined?
- [ ] Network: unnecessary re-fetching? data normalization (RTK Query, TanStack Query)?

## 🚀 Project Velocity
- [ ] Dev server: hot module replacement <1s?
- [ ] Build time: production build <2min? (esbuild, turbopack, swc, vite)
- [ ] Type safety: strict TypeScript? no `any` escaping?
- [ ] Linting: ESLint + Prettier in pre-commit? auto-fix?
- [ ] Storybook: component dev independent of pages?
- [ ] Visual regression: Chromatic/Percy/Playwright screenshots in CI?

## 📱 Responsive Design
- [ ] Mobile-first: breakpoints defined? content prioritization for small screens?
- [ ] Touch: targets ≥48px (WCAG)? swipe gestures? no hover-dependent UI?
- [ ] Cross-browser: tested on Chrome, Firefox, Safari, Edge?
- [ ] Print styles: @media print defined?
- [ ] Dark mode: CSS variables? prefers-color-scheme? no flash?
- [ ] Reduced motion: prefers-reduced-motion respected?

## 🏗️ Infrastructure
- [ ] Hosting: CDN? edge functions? static generation vs SSR?
- [ ] SPA routing: historyApiFallback configured? 404 page?
- [ ] Error tracking: Sentry/Bugsnag for runtime errors?
- [ ] Analytics: privacy-compliant? (Plausible, PostHog, GA4)
- [ ] A/B testing: framework? feature flags?
