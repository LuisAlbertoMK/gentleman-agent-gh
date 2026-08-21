---
name: infra-audit
description: "Trigger: infrastructure audit, IaC, Terraform, Kubernetes, CI/CD, Docker, cloud, Helm, Ansible. Audit infra reliability."
triggers: "infrastructure audit, IaC, Terraform, Kubernetes, CI/CD, Docker, cloud, deployment, Helm, Ansible, k8s"
changelog: docs/ciclos/cycle28-20260815.md
token_budget: 1619
---

## When to Use
Reviewing infrastructure (Terraform, Docker, K8s, CI/CD, Helm, Ansible, CloudFormation). Progressive scan: audit what's present, report what's missing.

## CHECKLIST
| Check | Sev |
|-------|-----|
| No remote state | CRIT |
| Privileged container | CRIT |
| Secrets in CI plaintext | CRIT |
| No resource limits | HIGH |
| No health checks | HIGH |
| No NetworkPolicy (multi-tenant K8s) | HIGH |
| `latest` tag in prod | MED |
| Unpinned CI actions | MED |

## RISK SCORING
| Level | Criteria |
|-------|----------|
| NONE | All checks pass |
| LOW | Only MED findings |
| MED | 1+ HIGH findings |
| HIGH | 1+ CRIT findings |

## OUTPUT
```
### Security Compliance
| Check | Status | File | Evidence |
### Reliability
| Component | SPOF? | Replicas | Health Check |
### Risk: [NONE/LOW/MED/HIGH] — [why]
```

## Rules
1. Audit what's present (progressive).
2. Remote state FIRST.
3. Container security before CI.
4. Pin everything.
5. Both .yaml and .yml.

## Refs
container-security · security-scanner · best-practices

## Anti-Patterns
Stop if no Terraform · Ignore .yml extensions · GitHub-only CI checks · Skip NetworkPolicy · Subjective risk scoring

---

> See [reference.md](docs/skills/infra-audit/reference.md) for extended details, examples, and detailed patterns.