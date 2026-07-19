---
name: container-security
description: "Trigger: Dockerfile, docker-compose, container, image, Kubernetes, k8s, pod, deployment, helm. Audit container security and orchestration hardening."
license: Apache-2.0
metadata:
  tags: [security, infrastructure]
  author: gentleman-vMK
  version: "1.0"
  changelog: "1.0: initial version — Dockerfile, compose, K8s, image hardening"
---
## WHEN: Reviewing Dockerfiles, docker-compose, K8s manifests, Helm charts, or user asks "is this container secure"

## SCAN DIMENSIONS

**Dockerfile**: `glob "Dockerfile*", "*.dockerfile"` → check FROM base (alpine/distroless preferred), USER directive (non-root), COPY vs ADD, no secrets in build args, multi-stage builds
**Compose**: `glob "docker-compose*.yml", "compose*.yml"` → check secrets not in env vars, no privileged containers, health checks, resource limits, read-only root fs
**Kubernetes**: `glob "*.yaml", "*.yml"` → check securityContext (runAsNonRoot, readOnlyRootFilesystem, drop ALL capabilities), no hostNetwork/hostPID, resource limits, network policies
**Image**: `grep -rn "FROM\|image:" --include="Dockerfile*"` → check pinned versions (not `latest`), minimal base images, no `apt-get upgrade` without version pinning

## QUICK PATTERNS

**Dockerfile anti-patterns**:
- `USER root` or missing USER → CRITICAL: container runs as root
- `ADD http://` → HIGH: remote code execution during build
- `COPY . .` without .dockerignore → MEDIUM: leaks secrets/.env/.git
- `RUN apt-get install` without `--no-install-recommends` → LOW: bloated image
- Secrets in `ARG`/`ENV` → CRITICAL: visible in `docker history` and image layers

**Compose anti-patterns**:
- `privileged: true` → CRITICAL: full host access
- Secrets in `environment:` → HIGH: visible in `docker inspect`
- No `healthcheck:` → MEDIUM: no readiness/liveness probe
- No `mem_limit`/`cpus` → MEDIUM: resource exhaustion risk

**K8s anti-patterns**:
- Missing `securityContext` → HIGH: defaults to root
- `hostNetwork: true` → HIGH: bypasses network policies
- No `resources.limits` → MEDIUM: pod can consume all node resources
- `latest` tag in image → MEDIUM: non-reproducible deployments

## OUTPUT FORMAT

```
## Container Security: {scope}
### Summary
- Dockerfile: {N} issues | Compose: {N} | K8s: {N} | Image: {N}
### Issues (CRITICAL/HIGH/MEDIUM/LOW)
# CRITICAL: {type} in {file:line}
- Pattern: `{found}` → Fix: `{fix}`
```

## RULES
1. Check USER directive FIRST — running as root is the #1 container vulnerability. 2. Secrets in ENV/ARG = CRITICAL (visible in docker history). 3. Multi-stage builds for production images. 4. Pin ALL image versions (no `latest`). 5. End with: "Remaining risk: NONE/LOW/MED/HIGH (why)"

## Refs
security-scanner · best-practices · quality-gate

## Anti-Patterns
Flag alpine as insecure (it's minimal, that's good) · Skip USER check because "K8s handles it" · Ignore build-time secrets (only check runtime) · Miss .dockerignore importance
