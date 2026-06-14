# Gap Analysis: API / Backend

> Headless API service. Weights: Security 40% · Technical 35% · Ops 25%.

## 🎨 UI/UX
- [ ] API docs: OpenAPI/Swagger? Interactive playground?
- [ ] Error responses: consistent format? Error codes? Human-readable messages?
- [ ] SDK/client libraries available?
- [ ] Webhook documentation? Event schema versioned?

## 🔒 Security
- [ ] Auth: API keys? JWT? OAuth2? mTLS?
- [ ] Rate limiting: per key? per endpoint? Response headers?
- [ ] Input validation: schema validation? SQL injection? NoSQL injection?
- [ ] CORS: configured correctly per environment?
- [ ] Logging: without sensitive data (PII, passwords, tokens)?
- [ ] OWASP ASVS 5.0 L1 applied? API-specific top 10 checked?

## ⚡ Optimization
- [ ] Response compression: gzip/brotli?
- [ ] Pagination: cursor-based? Limit/offset with max?
- [ ] Partial responses: GraphQL? Fields parameter? Sparse fieldsets?
- [ ] Batch endpoints for bulk operations?

## 📈 Performance
- [ ] p50/p95/p99 latency: measured? SLA defined?
- [ ] Database query performance: N+1? Connection pool? Indexes?
- [ ] Caching: response cache? Redis? CDN for GET endpoints?
- [ ] Load testing: handles 3x peak? Results documented?

## 💾 Resource Usage
- [ ] Memory: per-request allocations? Leak detection?
- [ ] CPU: heavy computations? Async/background processing?
- [ ] Database connections: pooled? Max connections configured?
- [ ] Log storage: retention policy? Aggregation?

## 🚀 Project Velocity
- [ ] Dev loop: hot reload? Local env? Docker compose?
- [ ] API versioning strategy? Breaking changes management?
- [ ] OpenAPI-first development? Spec→code generation?
- [ ] CI/CD: automated tests→staging→prod?
- [ ] Migration strategy: zero-downtime? Rollback tested?

## 📱 Responsive Design
- [ ] N/A for pure API — skip if no UI layer.
- [ ] Mobile-specific endpoints? Smaller payloads? Different caching?

## 🏗️ Infrastructure
- [ ] Deployment: containerized? K8s? Serverless?
- [ ] Horizontal scaling: stateless? Session affinity needed?
- [ ] Monitoring: uptime, latency, error rate, request count?
- [ ] Logging: structured? Centralized? Searchable?
- [ ] DR: multi-region? Failover tested?
