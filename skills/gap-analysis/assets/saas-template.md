# Gap Analysis: SaaS

> Weighted checklist for multi-tenant cloud systems.

## Layer Weights
Functional ████ 30% · Technical █████ 35% · Security █████ 35%
UX ███ 20% · Ops ██████ 40% · Business ███ 25%

## Maturity Levels
| Level | Ops | Security | Business |
|-------|-----|----------|----------|
| **Ad-Hoc** | Manual deploys, no monitoring | No audit, shared secrets | No pricing strategy |
| **Reactive** | Basic CI, alerts after incidents | Basic auth, manual review | Flat pricing, no analytics |
| **Proactive** | CD, monitoring, runbooks | MFA, RBAC, audit logs | Tiers, usage analytics |
| **Strategic** | Auto-scaling, DR tested, SLOs | SSO, zero-trust, pen-tested | Price optimization, LTV/CAC |

## Functional
- [ ] Multi-tenant? Tenant isolation strategy?
- [ ] Plans/tiers per feature? Feature gating?
- [ ] Onboarding flow: signup→activation→time-to-value?
- [ ] Billing: subscriptions? usage-based? dunning?
- [ ] Notifications: email? in-app? push? templates?
- [ ] Admin panel: user management? audit? config?
- [ ] API versioning? rate limiting? docs?
- [ ] SSO/SAML/OIDC integration?

## Technical
- [ ] Horizontal scaling? Stateless app servers?
- [ ] Database per tenant vs shared vs hybrid?
- [ ] Caching strategy? CDN? Redis? Invalidation?
- [ ] Background jobs? Queue? Worker pool?
- [ ] Migrations: zero-downtime? rollback tested?
- [ ] Error tracking + APM? (Sentry, DataDog)
- [ ] Query performance: N+1? connection pooling?
- [ ] Reference: ISO 25010 Performance Efficiency

## Security (OWASP ASVS 5.0 L1 as minimum)
- [ ] Tenant data isolation TESTED?
- [ ] Auth: MFA? RBAC? Session management?
- [ ] API: JWT? API keys? OAuth2? Rate limiting?
- [ ] Audit log per tenant? Immutable?
- [ ] Data encryption: rest (AES-256) + transit (TLS 1.3)?
- [ ] Secrets management: vault? env? hardcoded?
- [ ] Dependency vulns: scanned regularly?
- [ ] GDPR: data export? delete? consent?

## UX
- [ ] Onboarding conversion tracked?
- [ ] Empty states helpful? Loading states?
- [ ] Mobile responsive? PWA?
- [ ] WCAG 2.2 AA: keyboard nav? contrast? focus?

## Ops
- [ ] CI/CD: automated tests → staging → canary → prod?
- [ ] Monitoring: uptime? error rates? latency? business metrics?
- [ ] Incident response: runbooks? on-call? escalation?
- [ ] Backup: RPO/RTO defined? Restore TESTED?
- [ ] Feature flags? Gradual rollout?
- [ ] Cost monitoring + reserved instances?
- [ ] SLA defined? Past uptime?

## Business
- [ ] Pricing page clear? Feature comparison table?
- [ ] Churn tracked? Reason collected?
- [ ] Feature adoption analytics by tenant?
- [ ] Competitive matrix maintained?
- [ ] LTV/CAC > 3? Payback period < 12mo?
