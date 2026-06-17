# Per-R Checklist — verify each BEFORE scoring

## Risk — 10 questions
1. Are all error paths handled (no empty catches, no `// TODO: handle`)?
2. Are edge cases covered (empty input, nil/null, zero, max, overflow)?
3. Is input validated at boundaries (type, range, format)?
4. Can this fail silently? Would we know?
5. Is there a rollback path for partial failures?
6. Are credentials/secrets exposed in logs or output?
7. Is there monitoring/observability for failure states?
8. Are there race conditions on shared state?
9. Is the failure mode documented or obvious?
10. Does it follow the principle of least privilege?

## Readability — 8 questions
1. Are names precise and intention-revealing?
2. Is cyclomatic complexity ≤ 10 per function/method?
3. Are side effects obvious and documented?
4. Does the structure follow project conventions?
5. Would a junior dev understand this in one pass?
6. Are comments explaining WHY not WHAT?
7. Is there duplicated logic that could be extracted?
8. Are abstractions at the right level?

## Reliability — 8 questions
1. Are external calls protected by timeout?
2. Is there retry logic with backoff for transient failures?
3. Are fallback/default values defined for failure cases?
4. Is state consistency maintained (transactions, atomicity)?
5. Are resources properly released (defer/close/Dispose)?
6. Is data validated before persistence?
7. Are concurrent writes protected (locks, CAS, transactions)?
8. Does partial failure leave the system in a known state?

## Resilience — 7 questions
1. Is there backpressure or rate limiting for load spikes?
2. Can a failure in this component cascade to others?
3. Is there a degradation path (degraded but not down)?
4. Are resource limits bounded (memory, connections, goroutines)?
5. Is there a recovery/reconnect mechanism?
6. Are health checks or circuit breakers present where needed?
7. Can this run in parallel without corruption?
