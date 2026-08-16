---
name: container-security
description: "Trigger: Dockerfile, docker-compose, Kubernetes, k8s, pod, deployment, helm. Audit container security hardening."
triggers: "Dockerfile, docker-compose, container, image, Kubernetes, k8s, pod, deployment, helm, docker, orchestration"
changelog: docs/ciclos/cycle28-20260815.md
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

## Examples

**1. Dockerfile - Hardened Multi-stage**
```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server .

# Runtime stage - distroless
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/server"]
```

**2. docker-compose - Least Privilege**
```yaml
services:
  app:
    image: myapp:v1.2.3
    user: "1000:1000"
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
      - /var/run:noexec,nosuid,size=10m
    cap_drop:
      - ALL
    cap_add: []
    pids_limit: 100
    mem_limit: 512m
    cpus: "0.5"
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

**3. Kubernetes Deployment - securityContext**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      serviceAccountName: payment-sa
      automountServiceAccountToken: false
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: app
        image: myorg/payment-service:v2.1.0
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop: ["ALL"]
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-sa
  namespace: production
```

**4. Helm Chart - Values with Security Defaults**
```yaml
# values.yaml
replicaCount: 3
image:
  repository: myorg/myapp
  tag: "v1.4.2"
  pullPolicy: IfNotPresent
  pullSecrets: ["registry-creds"]

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
  capabilities:
    drop:
      - ALL

podSecurityContext: {}

serviceAccount:
  create: true
  name: ""
  annotations: {}

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 15
  periodSeconds: 20
readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 10

networkPolicy:
  enabled: true
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: ingress-nginx
      ports:
      - protocol: TCP
        port: 8080
```

**5. Kubernetes NetworkPolicy - Zero Trust**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-deny-all
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: ingress-nginx
      ports:
      - protocol: TCP
        port: 8080
  egress:
    - to:
      - namespaceSelector:
          matchLabels:
            name: database
      ports:
      - protocol: TCP
        port: 5432
    - to:
      - namespaceSelector:
          matchLabels:
            name: cache
      ports:
      - protocol: TCP
        port: 6379
    - to: []  # DNS
      ports:
      - protocol: UDP
        port: 53
```

## Testing Patterns

**1. Static Analysis Pipeline (CI Gate)**
```yaml
# .github/workflows/container-security.yml
name: Container Security
on: [push, pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Hadolint
        uses: hadolint/hadolint-action@v3
        with:
          dockerfile: Dockerfile
          failure-threshold: error
      - name: Run Trivy (Dockerfile)
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'config'
          scan-ref: '.'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'
      - name: Run Trivy (Image)
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: '${{ env.REGISTRY }}/${{ env.IMAGE }}:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
      - name: Run kube-score
        run: |
          kubectl kustomize k8s/ | kube-score score -
      - name: Check for secrets
        uses: trufflesecurity/trufflehog@main
        with:
          path: .
          base: ${{ github.event.pull_request.base.sha || 'main' }}
```

**2. Runtime Admission Control (OPA Gatekeeper)**
```yaml
# ConstraintTemplate: must-run-as-nonroot.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8spsprunasnonroot
spec:
  crd:
    spec:
      names:
        kind: K8sPSPRunAsNonRoot
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8spsprunasnonroot
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.securityContext.runAsNonRoot
          msg := sprintf("Container %s must run as non-root", [container.name])
        }
        violation[{"msg": msg}] {
          container := input.review.object.spec.initContainers[_]
          not container.securityContext.runAsNonRoot
          msg := sprintf("InitContainer %s must run as non-root", [container.name])
        }
```

**3. Image Signing & Verification (Cosign + Kyverno)**
```yaml
# Kyverno policy: verify-image-signature.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: check-cosign-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
    verifyImages:
    - image: "*"
      key: |
        -----BEGIN PUBLIC KEY-----
        MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
        -----END PUBLIC KEY-----
      annotations:
        - "dev.cosignproject.cosign/signature"
```

## Edge Cases

**1. Build-time secrets in multi-stage builds**
`ARG`/`ENV` in builder stage visible in `docker history` even if not in final image.
Fix: Use `--mount=type=secret` (BuildKit) or external secret injection at runtime.

**2. Distroless base images break debugging**
No shell, no package manager. Can't `kubectl exec -it pod -- sh`.
Fix: Use `-debug` variants (`gcr.io/distroless/java17-debug`) for staging only, or add busybox sidecar.

**3. Capabilities interact with seccomp**
Dropping `ALL` caps + `seccompProfile: RuntimeDefault` is defense-in-depth, but `seccomp` profile must allow syscalls the app actually uses. Missing `clone`/`fork` breaks Go/Java apps.
Fix: Profile per language runtime; test in staging with `securityContext.seccompProfile.type: Unconfined` then audit `audit.log`.

**4. Rootless containers on Kubernetes**
`runAsUser: 1000` works, but host filesystem mounts (`hostPath`, `emptyDir`) may have root-owned files from node.
Fix: `fsGroup: 1000` + `securityContext.fsGroupChangePolicy: "OnRootMismatch"` + initContainer to chown.

## Anti-Patterns

1. **"Alpine is secure enough"** — Alpine uses musl libc (not glibc), different attack surface but not inherently secure. Still runs as root by default, no user namespace isolation. Use distroless or gVisor/Kata for stronger isolation.

2. **"Kubernetes securityContext replaces Dockerfile USER"** — K8s `runAsUser` overrides Dockerfile `USER`, but:
   - Build-time `USER` still affects build cache / layer ownership
   - Image scanned by registries (Harbor, ECR) sees root layers
   - Local `docker run` without K8s still runs as root
   Fix: Both layers must agree — Dockerfile `USER nonroot` + K8s `runAsUser: 1000`.