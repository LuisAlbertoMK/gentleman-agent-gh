# Gap Analysis: SaaS

> Multi-tenant cloud system. Weights: Ops 40% · Security 35% · Business 25%.

## 🎨 UI/UX
- [ ] Onboarding flow: signup→activation→time-to-value measured?
- [ ] Dashboard: key metrics visible at glance? Customizable?
- [ ] Admin panel: user mgmt, audit, config — intuitive?
- [ ] Empty states helpful for new tenants?
- [ ] Notifications: email, in-app, push — configured?
- [ ] WCAG 2.2 AA: keyboard nav through entire admin?

## 🔒 Security
- [ ] Tenant data isolation TESTED (not just assumed)?
- [ ] Auth: MFA? SSO/SAML/OIDC? RBAC? Session rotation?
- [ ] API: JWT? API keys? OAuth2? Rate limiting per tenant?
- [ ] Audit log: per tenant, immutable, searchable?
- [ ] Data encryption: rest (AES-256) + transit (TLS 1.3)?
- [ ] Secrets management: vault, not env files?
- [ ] Dependency vulns: scanned every build?
- [ ] GDPR: data export, delete, consent per tenant?

## ⚡ Optimization
- [ ] Bundle: code splitting per route/feature?
- [ ] API response: pagination, partial response, compression?
- [ ] Caching: CDN for static? Redis for sessions? Query cache?
- [ ] Background jobs: queue, worker pool, retry logic?

## 📈 Performance
- [ ] API latency p95 < 200ms for critical endpoints?
- [ ] Database: connection pooling? query optimization? indexing?
- [ ] N+1 queries: tested? ORM configured correctly?
- [ ] Load testing: handles 2x peak traffic?

## 💾 Resource Usage
- [ ] Memory: per-tenant limits? leak detection?
- [ ] Storage: data retention policy? archival strategy?
- [ ] Cost monitoring: per-resource, per-tenant?
- [ ] Auto-scaling: horizontal? triggers defined?

## 🚀 Project Velocity
- [ ] CI/CD: build→test→staging→canary→prod automated?
- [ ] Dev loop: hot reload? local env with docker compose?
- [ ] Feature flags: gradual rollout? A/B testing?
- [ ] Release cadence: regular? documented?

## 📱 Responsive Design
- [ ] Admin panel: usable on tablet/mobile?
- [ ] Customer-facing pages: responsive?
- [ ] Touch targets ≥48px? Forms usable on mobile?

## 🏗️ Infrastructure
- [ ] Cloud provider: multi-region? DR plan tested?
- [ ] Containerization: Docker? K8s? Helm charts?
- [ ] Monitoring: uptime, error rates, latency, business metrics?
- [ ] Incident response: runbooks? on-call? escalation? SLA?
- [ ] Backup: RPO/RTO defined? Restore TESTED recently?
