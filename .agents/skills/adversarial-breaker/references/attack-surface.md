# Attack Surface Checklist

Quick reference for the breaker — organized by attack category. Not all apply to every fix; breaker selects relevant vectors based on the diff.

## Input Validation
- [ ] Null / undefined / empty string
- [ ] Boundary: 0, -1, MAX_INT, MIN_INT, NaN, Infinity
- [ ] Unicode: emoji, RTL chars, zero-width chars, null bytes
- [ ] Length: empty, 1 char, max length, overflow (e.g. very long string)
- [ ] Type: wrong type passed intentionally
- [ ] Format: malformed email, URL, date, UUID

## Injection
- [ ] SQL: `' OR 1=1--`, `'; DROP TABLE--`, parameterized?
- [ ] XSS: `<script>alert(1)</script>`, event handlers
- [ ] Command: `; ls`, `| cat /etc/passwd`, backticks
- [ ] Path traversal: `../../etc/passwd`, `..%2F..%2F`
- [ ] Template injection: `{{7*7}}`, `${7*7}`
- [ ] Header injection: `\r\n` in headers

## Concurrency
- [ ] Race condition: parallel writes to same key
- [ ] TOCTOU: check-then-act without lock
- [ ] Idempotency: duplicate request produces same result?
- [ ] Deadlock: two resources acquired in different order
- [ ] Starvation: one thread never gets the lock

## Error Handling
- [ ] Dependency returns null/error/throws
- [ ] Network timeout mid-operation
- [ ] Disk full / quota exceeded
- [ ] DB connection drops mid-transaction
- [ ] Promise rejection not caught
- [ ] Exception in finally/cleanup block

## Data Integrity
- [ ] Partial write: what if process dies after first DB write?
- [ ] Stale read: cache not invalidated after write?
- [ ] Integer overflow in counters/balances
- [ ] Floating point: 0.1 + 0.2 ≠ 0.3
- [ ] Encoding: UTF-8 vs Latin-1 mismatch
- [ ] Timezone: UTC vs local time confusion

## Auth & Access
- [ ] Privilege escalation: can user A access user B's data?
- [ ] Missing auth check on new endpoint/operation
- [ ] Token expiry not enforced
- [ ] Rate limiting missing on sensitive endpoint
- [ ] CSRF: state-changing operation via GET

## Regression Risk
- [ ] Does this fix break an existing feature?
- [ ] Does this fix change a public API contract?
- [ ] Does this fix assume a DB schema that might not exist?
- [ ] Does this fix work in all deployment environments?
