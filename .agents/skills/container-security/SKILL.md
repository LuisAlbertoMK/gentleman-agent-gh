---
name: container-security
description: "Trigger: Dockerfile, docker-compose, Kubernetes, k8s, pod, deployment, helm. Audit container security hardening."
triggers: "Dockerfile, docker-compose, container, image, Kubernetes, k8s, pod, deployment, helm, docker, orchestration"
changelog: docs/ciclos/cycle28-20260815.md
---
## When to Use
Reviewing Dockerfiles, docker-compose, K8s manifests, Helm charts, or "is this container secure"

## CHECKLIST

| Check | Sev | Pattern |
|-------|-----|---------|
| Runs as root | CRIT | Missing USER or `runAsUser: 0` |
| ADD remote code | CRIT | `ADD http` (matches http/https) |
| Secrets in ENV/ARG | CRIT | Visible in docker history |
| Privileged container | CRIT | `privileged: true` |
| Docker socket mount | CRIT | `/var/run/docker.sock` |
| No securityContext | HIGH | K8s pod without securityContext |
| hostPath volume | HIGH | Data exfil risk |
| Dangerous caps | HIGH | SYS_ADMIN, NET_RAW, ALL |
| No health check | MED | Missing readiness/liveness |
| No resource limits | MED | Pod can exhaust node |
| `latest` tag | MED | Non-reproducible |

## OUTPUT
```
## Container Security: {scope}
### Summary
- Dockerfile: {N} | Compose: {N} | K8s: {N} | Image: {N}
### Issues
# CRITICAL: {type} in {file:line}
- Pattern: `{found}` → Fix: `{fix}`
```

## Rules
1. USER FIRST. 2. Secrets in ENV/ARG = CRITICAL. 3. Multi-stage for prod. 4. Pin versions. 5. End: "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Refs
security-scanner · best-practices · quality-gate
---

docs/skills/container-security/reference.md
---