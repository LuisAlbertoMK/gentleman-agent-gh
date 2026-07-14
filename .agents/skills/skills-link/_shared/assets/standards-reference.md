## Industry Standards Quick Reference

> Cross-skill reference for software quality standards. Referenced by gap-analysis, security-scanner, code-review-agent.

### ISO/IEC 25010:2023 — Software Quality Model
9 characteristics for product quality evaluation.

| Characteristic | Sub-characteristics | Gap layer |
|---------------|-------------------|-----------|
| Functional Suitability | Completeness, correctness, appropriateness | Functional |
| Performance Efficiency | Time behavior, resource utilization, capacity | Technical |
| Compatibility | Co-existence, interoperability | Technical |
| Usability | Appropriateness, learnability, operability, UI aesthetics | UX |
| Reliability | Maturity, availability, fault tolerance, recoverability | Ops |
| Security | Confidentiality, integrity, non-repudiation, accountability | Security |
| Maintainability | Modularity, reusability, analyzability, modifiability, testability | Technical |
| Portability | Adaptability, installability, replaceability | Technical |

### OWASP ASVS 5.0 (May 2025) — Application Security Verification
**350 requirements** across 17 chapters, 3 cumulative levels.

| Level | % of reqs | Intent |
|-------|-----------|--------|
| **L1 — Basic** | ~20% | First-layer defences, baseline for any app |
| **L2 — Standard** | ~50% | Most business apps with sensitive data |
| **L3 — Advanced** | ~30% | Financial, healthcare, critical infra |

**17 chapters**: V1 Encoding/Sanitization · V2 Validation/Business Logic · V3 Web Frontend · V4 API/Web Service · V5 File Handling · V6 Authentication · V7 Session Mgmt · V8 Authorization · V9 Self-contained Tokens · V10 OAuth/OIDC · V11 Cryptography · V12 Secure Communication · V13 Configuration · V14 Data Protection · V15 Secure Coding/Architecture · V16 (reserved) · V17 (reserved)

### WCAG 2.2 (Oct 2023) — Web Content Accessibility
**86 success criteria** across 4 principles, 3 levels (A/AA/AAA). AA = legal baseline.

**4 Principles (POUR)**:
- **Perceivable**: text alternatives, captions, adaptable, distinguishable
- **Operable**: keyboard, enough time, seizures, navigable, input modalities
- **Understandable**: readable, predictable, input assistance
- **Robust**: compatible with assistive technologies

**New in 2.2** (9 criteria): Focus Not Obscured (AA+AAA) · Focus Appearance (AA) · Dragging Movements (AA) · Target Size ≥24×24px (AA) · Consistent Help (AA) · Redundant Entry (AA) · Accessible Authentication (AA+AAA)

### Compliance Frameworks (industry-specific)

Add these when the system handles regulated data.

| Framework | Scope | Key controls | When |
|-----------|-------|-------------|------|
| **HIPAA** | Health data (US) | AES-256, MFA, audit logs, signed BAAs, pen testing, breach notify ≤60d | Healthcare apps, telemedicine |
| **PCI DSS 4.0.1** | Payment data | 12 reqs: secure coding, pre-prod vuln scan, 30-day critical fix, API security, MFA | E-commerce, payments |
| **SOC 2 Type II** | SaaS data security | 5 TSCs: Security(req), Availability, Processing Integrity, Confidentiality, Privacy. 33 Common Criteria. 6-12mo observation. | B2B SaaS, enterprise vendors |
| **GDPR** | EU personal data | Lawful basis, data mapping, consent, DPIAs, 72hr breach notify, DSARs, vendor DPAs | Any EU user data |

### SaaS Maturity Model
| Level | Name | Characteristics |
|-------|------|----------------|
| 1 | Ad-Hoc | Manual deploys, no monitoring, shared secrets, flat pricing |
| 2 | Reactive | Basic CI, alerts after incidents, basic auth, manual review |
| 3 | Proactive | CD, monitoring+runbooks, MFA+RBAC+audit logs, tiered pricing |
| 4 | Strategic | Auto-scaling, DR tested, SLOs, zero-trust, price optimization |
