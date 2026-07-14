# Verifiable Rules per R

Binary (pass/fail) rules checked BEFORE scoring. Reviewer MUST answer yes/no for each.

## Risk — Verifiable Rules
| # | Rule | Pass Criteria |
|---|------|---------------|
| R01 | All error paths return typed errors | No `panic()`, no empty catches, no `// TODO: handle` |
| R02 | Input validated at every public boundary | `validateInput()` or equivalent at API/file/network entry points |
| R03 | No suppressed errors (`_ = fn()`) | `_ =` is NOT used to discard errors |
| R04 | No nil/null dereference without guard | Every pointer/map/slice dereference is guarded |
| R05 | No secrets in logs or output | `log.Printf("%+v", obj)` not used on sensitive structs |
| R06 | Rollback exists for partial failures | Transaction rollback or compensation action present |
| R07 | Resource limits are enforced | Pagination, rate limiting, or timeout on external resources |

## Readability — Verifiable Rules
| # | Rule | Pass Criteria |
|---|------|---------------|
| RD01 | Cyclomatic complexity ≤ 10 per function | Count if/else/for/switch/case/&&/\|\| per function |
| RD02 | No function > 100 lines | (Or agreed project max) |
| RD03 | No nested conditionals beyond 3 levels | if > if > if is max; extract otherwise |
| RD04 | Names reveal intent | No single-letter vars (except loops), no abbreviations |
| RD05 | Comments explain WHY not WHAT | Code is self-documenting for WHAT |
| RD06 | No TODO/FIXME/HACK in non-experimental code | Each must have an issue reference |
| RD07 | No dead code or commented-out blocks | Remove, don't comment |

## Reliability — Verifiable Rules
| # | Rule | Pass Criteria |
|---|------|---------------|
| RL01 | External calls have timeout | `context.WithTimeout` or `http.Client.Timeout` set |
| RL02 | Retry with backoff on transient failures | At least 1 retry with delay, not immediate retry |
| RL03 | Fallback/default for every external dependency | Default config, cached response, or degraded path |
| RL04 | Resources are released in all paths | `defer` / `finally` / `using` — checked after early returns too |
| RL05 | Concurrent writes are protected | Mutex, CAS, transaction, or channel serialization |
| RL06 | State is validated before persistence | Schema validation, constraint checks before INSERT/UPDATE |
| RL07 | Partial failure doesn't corrupt state | Transactional boundaries or compensating actions |

## Resilience — Verifiable Rules
| # | Rule | Pass Criteria |
|---|------|---------------|
| RS01 | Backpressure or rate limiting for load | Channel buffer size is bounded, or rate limiter present |
| RS02 | No cascading failure possible | Component failure is isolated (bulkhead pattern) |
| RS03 | Graceful degradation path defined | Non-critical features fail independently |
| RS04 | Resource limits bounded | Max goroutines, max connections, max memory defined |
| RS05 | Recovery/reconnect on transient failure | Reconnection with backoff for network/resources |
| RS06 | Health check or circuit breaker where needed | For critical external dependencies |
| RS07 | Concurrent safety documented | Thread-safety guarantees stated in comments/types |
