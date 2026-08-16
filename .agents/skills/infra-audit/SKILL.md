---
name: infra-audit
description: "Trigger: infrastructure audit, IaC, Terraform, Kubernetes, CI/CD, Docker, cloud, Helm, Ansible. Audit infra reliability."
triggers: "infrastructure audit, IaC, Terraform, Kubernetes, CI/CD, Docker, cloud, deployment, Helm, Ansible, terraform, k8s"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Reviewing infrastructure (Terraform, Docker, K8s, CI/CD, Helm, Ansible, CloudFormation). Progressive scan: audit what's present, report what's missing.

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

## Rules
1. Audit what's present (progressive). 2. Remote state FIRST. 3. Container security before CI. 4. Pin everything. 5. Both .yaml and .yml.

## Refs
container-security · security-scanner · best-practices

## Anti-Patterns
Stop if no Terraform · Ignore .yml extensions · GitHub-only CI checks · Skip NetworkPolicy · Subjective risk scoring

## ACTIONABLE EXAMPLES

**Terraform drift detection** (run before audit):
```bash
terraform plan -detailed-exitcode -out=tfplan.out 2>&1 | tee drift.log
# Exit 2 = drift detected; parse: grep -E "Plan:|No changes" drift.log
```

**Remote state verification**:
```bash
grep -rn "backend" --include="*.tf" | grep -v "local" || echo "MISSING: no remote backend"
grep -rn "terraform_remote_state" --include="*.tf" || echo "WARN: no cross-stack references"
```

**Docker multi-stage + non-root verification**:
```bash
docker build -f Dockerfile -t audit:test . && docker run --rm --user 1000 audit:test id
# Should return uid=1000, not root. Multi-stage: grep -c "FROM.*AS" Dockerfile (expect ≥2)
```

**K8s resource limits + probes check**:
```bash
kubectl get deploy -A -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.template.spec.containers[*].resources.limits.memory}{"\n"}{end}' | grep -v "Gi\|Mi" || echo "MISSING limits"
kubectl get deploy -A -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.template.spec.containers[*].livenessProbe}{"\n"}{end}' | grep "<nil>" && echo "MISSING livenessProbe"
```

**CI/CD unpinned actions + permissions audit**:
```bash
grep -rn "uses:" .github/workflows/ --include="*.yml" | grep -v "@v[0-9]" && echo "UNPINNED actions found"
grep -rn "permissions:" .github/workflows/ --include="*.yml" | grep -E "write-all|contents: write" && echo "OVER-PERMISSIVE"
```

**Helm values security scan**:
```bash
grep -rn "securityContext\|resources" charts/*/values.yaml --include="*.yaml" | wc -l
# Expect >0 per chart; 0 = missing hardening
```

## TESTING PATTERNS (verify infra reliability)

1. **Terraform plan-as-test** — Add to CI: `terraform plan -input=false -detailed-exitcode`; fail on exit 2 (drift) or 1 (error); pass on 0 (no changes). Run on every PR.
2. **K8s dry-run + policy check** — `kubectl apply --dry-run=server -f manifests/` + `kubectl apply --dry-run=server -f policies/` (OPA/Gatekeeper). Fail if any resource violates PSP/NetworkPolicy.
3. **Docker image scan gate** — Integrate `trivy image --severity HIGH,CRITICAL --exit-code 1 $IMAGE` in CI. Blocks merge on vuln. Pair with `docker scan` for base image freshness.

## EDGE CASES (when NOT to use / shared responsibility / CI failure modes)

| Scenario | Handling |
|----------|----------|
| **No IaC present** (clickops-only) | STOP — audit requires declarative config; document gap, recommend codification first |
| **Shared responsibility cloud** (RDS, S3, managed K8s) | Audit only customer-controlled layer: IAM policies, security groups, network config, not provider internals |
| **CI runner compromised** (self-hosted) | Skill cannot verify runner integrity; require signed workflows + ephemeral runners + attestation |
| **Multi-cloud / hybrid** | Run scan per provider; aggregate risk = max(sev) across clouds; don't average |
| **Helm chart without values.yaml** | Check `charts/*/templates/` directly; values may be injected at deploy time (ArgoCD/Flux) |
| **Ephemeral environments** (preview deployments) | Apply same scan with MED threshold; CRIT findings still block promotion to prod |

## ANTI-PATTERNS (what to STOP doing)

1. **Subjective risk scoring** — Never say "seems risky"; use the 4-level table only. Evidence or skip.
2. **Single-cloud CI checks** — Always include GitLab CI, Azure Pipelines, Bitbucket Pipes patterns in grep; don't assume GitHub Actions.
3. **Ignore .yml** — K8s/Helm/Ansible use both .yaml and .yml; omitting .yml misses ~30% of configs.
4. **Skip drift detection** — Terraform plan without -detailed-exitcode hides drift; always use it.
5. **Trust image tags** — `latest` in non-prod is still a supply-chain risk; pin everywhere or use digests.
