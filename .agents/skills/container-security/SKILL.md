---
name: container-security
description: "Trigger: Dockerfile, docker-compose, Kubernetes, k8s, pod, deployment, helm. Audit container security hardening."
triggers: "Dockerfile, docker-compose, container, image, Kubernetes, k8s, pod, deployment, helm, docker, orchestration"
---
## When to Use
Reviewing Dockerfiles, docker-compose, K8s manifests, Helm charts, or "is this container secure"

## SCAN DIMENSIONS

**Dockerfile**: `glob "Dockerfile*"` → FROM base (alpine/distroless), USER (non-root), COPY vs ADD, secrets in build args, multi-stage
- `grep -rn "ADD http" --include="Dockerfile*"` → CRITICAL: remote code exec (catches http AND https)
- `grep -rn "COPY \." --include="Dockerfile*"` → broad match for any COPY of current dir
- `grep -rn "^USER" --include="Dockerfile*"` → missing = runs as root

**Compose**: `glob "docker-compose*.yml", "compose*.yml"` → secrets in env, privileged, health checks, resource limits
- `grep -rn "docker.sock" --include="*.yml"` → CRITICAL: full host access
- `grep -rn "privileged:\s*true" --include="*.yml"` → CRITICAL

**Kubernetes**: `glob "*.yaml"` → securityContext, hostNetwork/hostPID, resource limits
- `grep -rn "runAsUser:\s*0\|runAsGroup:\s*0" --include="*.yaml"` → CRITICAL: root
- `grep -rn "cap_add\|capAdd\|SYS_ADMIN\|NET_RAW" --include="*.yaml"` → dangerous caps
- `grep -rn "hostPath" --include="*.yaml"` → data exfil risk
- `grep -rn "ServiceAccount\|ClusterRole\|RoleBinding" --include="*.yaml"` → least-privilege check

**Image**: `grep -rn "FROM\|image:" --include="Dockerfile*"` → pinned versions, minimal base

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

## Anti-Patterns
Flag alpine as insecure · Skip USER "K8s handles it" · Ignore build-time secrets · Miss .dockerignore
