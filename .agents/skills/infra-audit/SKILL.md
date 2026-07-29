---
name: infra-audit
description: "Trigger: infrastructure audit, IaC, Terraform, Kubernetes, CI/CD, Docker, cloud, deployment, Helm, Ansible. Audit infrastructure reliability and security."
triggers: "infrastructure audit, IaC, Terraform, Kubernetes, CI/CD, Docker, cloud, deployment, Helm, Ansible, terraform, k8s"
---
## WHEN: Reviewing infrastructure (Terraform, Docker, K8s, CI/CD, Helm, Ansible, CloudFormation). Progressive scan: audit what's present, report what's missing.

## SCAN DIMENSIONS (progressive — audit what's present)

**Terraform**: `grep -rn "^resource\|^data\|^module\|backend\|state" --include="*.tf"` → remote state, typed vars, minimal perms

**Docker**: `grep -rn "FROM\|latest" --include="Dockerfile*"` → pinned versions, non-root, multi-stage

**K8s** (BOTH .yaml AND .yml): `grep -rn "securityContext\|resources\|limits\|privileged\|cap_add\|livenessProbe\|readinessProbe\|NetworkPolicy\|ingress" --include="*.yaml" --include="*.yml"`

**CI/CD** (multi-system): `grep -rn "secrets\.\|GITHUB_TOKEN\|CI_JOB_TOKEN\|GITLAB_TOKEN\|permissions:\|uses:\|image:" --include="*.yml"`

**Helm/Ansible/CF**: `grep -rn "securityContext\|resources\|become:\|AWSTemplateFormatVersion" --include="*.yaml" --include="*.yml" --include="values.*"`

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

## RULES
1. Audit what's present (progressive). 2. Remote state FIRST. 3. Container security before CI. 4. Pin everything. 5. Both .yaml and .yml.

## Refs
container-security · security-scanner · best-practices

## Anti-Patterns
Stop if no Terraform · Ignore .yml extensions · GitHub-only CI checks · Skip NetworkPolicy · Subjective risk scoring
