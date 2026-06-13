# Gap Analysis: Database

> Data layer / storage system. Weights: Performance 30% · Security 25% · Resource 20% · Infra 15% · Rest 10%.

## 🎨 UI/UX
- [ ] API: query interface ergonomic? GraphQL/REST for DB access?
- [ ] Documentation: schema documented? ERD generated? data dictionary?
- [ ] Admin UI: pgAdmin/Adminer/phpMyAdmin? or CLI-only?
- [ ] Migration UX: rollback-friendly? dry-run mode? status visible?

## 🔒 Security
- [ ] Encryption at rest: TDE? disk encryption? column-level encryption for PII?
- [ ] Encryption in transit: TLS for all connections? mutual TLS?
- [ ] Access control: least privilege per service? read-only replicas for queries?
- [ ] Authentication: strong passwords? IAM roles? certificate auth? no default creds?
- [ ] Audit logging: all schema changes logged? data access logged?
- [ ] Backup encryption: backups encrypted? secure transfer?
- [ ] Connection security: IP allowlisting? VPC? bastion host?
- [ ] SQL injection: parameterized queries everywhere? no raw string concatenation?
- [ ] Data retention: PII cleanup policy? automated purge?

## ⚡ Optimization
- [ ] Index strategy: indexes match query patterns? covering indexes? partial indexes?
- [ ] Query optimization: EXPLAIN ANALYZE on slow queries? missing index detection?
- [ ] Schema: normalized (3NF) with strategic denormalization? anti-patterns (EAV, JSON blobs)?
- [ ] Connection pooling: PgBouncer/HikariCP? pool size tuned?
- [ ] Caching: query cache? Redis/Memcached read-through cache? materialized views?
- [ ] Partitioning: table partitioning by time/tenant? partition pruning effective?
- [ ] Archival: old data archived? hot/warm/cold tiering?

## 📈 Performance
- [ ] Query latency: p95 <10ms for simple queries? <100ms for complex?
- [ ] Throughput: max connections tuned? no connection exhaustion?
- [ ] Replication: read replicas for read-heavy workloads? replication lag monitored?
- [ ] Vacuum (PostgreSQL): autovacuum tuned? bloat monitored?
- [ ] Connection spikes: max_connections configured? connection pool as buffer?
- [ ] Slow query log: enabled? monitored? alerts on new slow queries?
- [ ] Maintenance windows: index rebuild? analyze? scheduled during low traffic?

## 💾 Resource Usage
- [ ] Storage: disk usage monitored? auto-scaling for storage? data compression?
- [ ] Memory: buffer pool / shared buffers sized correctly? working set fits in memory?
- [ ] CPU: query CPU usage profiled? no runaway queries?
- [ ] IOPS: disk IOPS monitored? SSD provisioned IOPS? no thundering herd?
- [ ] Cost: reserved instances? storage tiering? data lifecycle policies?

## 🚀 Project Velocity
- [ ] Migrations: version-controlled? auto-applied in CI? rollback tested?
- [ ] Schema changes: backward-compatible? zero-downtime migrations (expand-migrate-contract)?
- [ ] Dev DB: local replica? Docker image with seed data?
- [ ] Testing: integration tests with DB? testcontainers? in-memory DB for unit tests?
- [ ] CI: migration test in pipeline? schema linting? (sqllint, sqlfluff)
- [ ] Documentation: schema changes documented in PR? decision log?

## 📱 Responsive Design
- [ ] API compatibility: mobile clients can paginate? limit/offset supported?
- [ ] Offline sync: conflict resolution strategy? last-write-wins? CRDT?
- [ ] Bandwidth: response size minimized? projection queries? no over-fetching?

## 🏗️ Infrastructure
- [ ] High availability: primary + replica failover? automated? RTO <1min?
- [ ] Backup: automated? point-in-time recovery? RPO <5min?
- [ ] Disaster recovery: cross-region replica? tested regularly?
- [ ] Monitoring: query latency, connection count, disk IO, replication lag, cache hit ratio?
- [ ] Alerting: disk space <20%, replication lag >10s, connection count >80%?
- [ ] Scaling: read replicas? sharding strategy? connection pooling?
- [ ] Version: latest major? upgrade path tested? EOL known?
