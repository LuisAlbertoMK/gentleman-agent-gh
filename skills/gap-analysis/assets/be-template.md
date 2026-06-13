# Gap Analysis: Backend

> Server-side application. Weights: Security 30% · Performance 25% · Optimization 20% · Infra 15% · Rest 10%.

## 🎨 UI/UX
- [ ] API ergonomics: consistent response format? HAL/JSON:API/GraphQL?
- [ ] Error responses: structured (RFC 7807 Problem Details)? helpful messages?
- [ ] Documentation: OpenAPI/Swagger? auto-generated? interactive (Swagger UI)?
- [ ] Rate limiting: user-friendly Retry-After header? 429 + helpful body?
- [ ] Pagination: cursor-based? consistent format? total count?

## 🔒 Security
- [ ] Auth: JWT rotation? refresh tokens? MFA? OAuth2/SSO?
- [ ] RBAC: roles/permissions in DB, not hardcoded? tested?
- [ ] Input validation: ALL inputs validated (not just ORM)? allowlist approach?
- [ ] SQL injection: parameterized queries? ORM configured safely?
- [ ] Rate limiting: per user/IP/endpoint? configurable thresholds?
- [ ] CORS: specific origins (not `*`)? methods restricted?
- [ ] Secrets: vault/secret manager? not in env files? rotated?
- [ ] Dependency vulns: scanned on every build? (npm audit, go vulncheck, pip audit)
- [ ] Audit log: all state-changing operations logged? immutable? queryable?
- [ ] Data encryption: at rest (AES-256)? in transit (TLS 1.3)?
- [ ] PII handling: minimized? anonymized for analytics? GDPR delete endpoint?

## ⚡ Optimization
- [ ] Caching: Redis/Memcached? response caching? query result caching?
- [ ] Database: indexes on query patterns? connection pooling? statement caching?
- [ ] N+1 queries: detected and fixed? ORM batching configured?
- [ ] Payload: compression (gzip/brotli)? partial responses (GraphQL/fields param)?
- [ ] Background jobs: queue (RabbitMQ, Redis, SQS)? worker pool? retry with backoff?
- [ ] Static files: served via CDN? not through app server?

## 📈 Performance
- [ ] API latency: p50 <50ms, p95 <200ms, p99 <500ms for critical endpoints?
- [ ] Throughput: handles peak load? connection limit configured?
- [ ] Database: query plan analyzed? slow query log? connection pool tuned?
- [ ] Async: non-blocking I/O? worker threads for CPU tasks?
- [ ] Graceful degradation: circuit breakers? bulkheads? fallbacks?
- [ ] Health checks: /health, /ready endpoints? liveness + readiness probes?

## 💾 Resource Usage
- [ ] Memory: profiling done? no leaks in long-running processes?
- [ ] CPU: hot spots identified? goroutine/thread leaks monitored?
- [ ] Storage: log rotation? file cleanup? temp file management?
- [ ] Database connection pool: size tuned? wait queue monitored?
- [ ] Cost: instance right-sizing? reserved instances? serverless where appropriate?

## 🚀 Project Velocity
- [ ] Build time: <30s? incremental compilation?
- [ ] Dev loop: hot reload? docker compose for local dev?
- [ ] API testing: integration tests for all endpoints? contract tests?
- [ ] Migration strategy: zero-downtime? backward-compatible changes?
- [ ] Feature flags: toggle system? gradual rollout?
- [ ] Documentation: auto-generated API docs? runbooks?

## 📱 Responsive Design
- [ ] API adaptation: mobile clients get different response sizes?
- [ ] Offline support: sync endpoints? conflict resolution?
- [ ] Push notifications: Web Push? FCM/APNs integrated?
- [ ] Bandwidth: optimized for mobile networks? compression? minification?

## 🏗️ Infrastructure
- [ ] Containerization: Docker? multi-stage builds? distroless base?
- [ ] Orchestration: K8s/EKS/AKS? resource limits defined?
- [ ] CI/CD: build → test → staging → canary → production?
- [ ] Monitoring: metrics (CPU, memory, latency, error rate, throughput)?
- [ ] Logging: structured logs (JSON)? centralized (ELK/Loki)? searchable?
- [ ] Alerting: on-call? PagerDuty/OpsGenie? SLA/SLO defined?
- [ ] Disaster recovery: RPO/RTO defined? backups tested?
- [ ] Auto-scaling: HPA defined? scale based on CPU/memory/requests?
