# RDD Reference — Examples, Receipt, Recovery

## Tier 0 Examples

**Single-line fix** (`src/config.ts`, 1L):
```diff
- const MAX_RETRIES = 3;
+ const MAX_RETRIES = 5;
```
Tier: 0 — freeze only, no 4R. Receipt has no verdict/scores.

**Add comment** (`src/db/pool.ts`, 3L):
```diff
+ // Connection pool settings
  export const POOL_SIZE = 10;
```
Tier: 0 — audit trail only.

## Tier 1 Examples

**Shared module refactor** (`src/utils/validate.ts`, 120L):
```diff
- export function validate(input: string) {
+ export function validate(input: string, opts?: ValidateOptions) {
```
Tier: 1 (50-200L, shared module). 4R verdict: WARN (Read:6). 1 opt-in fix applied.

**Tier 1 Receipt:**
```json
{
  "id": "rdd-receipt-002",
  "freeze": "HEAD-a1b2c3d4e5f6-9f8e7d6c",
  "tier": 1, "files": ["src/utils/validate.ts"],
  "lines_changed": 120, "verdict": "WARN",
  "4r": { "risk": 7, "read": 6, "rel": 8, "res": 7 },
  "fixes_applied": 1, "timestamp": "2026-09-17T10:30:00Z"
}
```

## Tier 2 Examples

**Auth schema change** (3 files, 250L — jwt.ts, middleware.ts, schema.ts):
Tier: 2 (schema/auth changes). 4R verdict: FAIL (Risk:3 — no rate limit). STOP → judgment-day.

**Tier 2 Receipt:**
```json
{
  "id": "rdd-receipt-003",
  "freeze": "HEAD-x1y2z3w4v5u6-4b3a2c1d",
  "tier": 2,
  "files": ["src/auth/jwt.ts", "src/auth/middleware.ts", "src/db/schema.ts"],
  "lines_changed": 250, "verdict": "FAIL",
  "4r": { "risk": 3, "read": 7, "rel": 5, "res": 6 },
  "blockers": [{
    "file": "src/auth/jwt.ts", "line": 15, "r": "Risk",
    "finding": "No rate limit on /token — brute-force risk",
    "trace": "POST /token → signToken() → no throttle",
    "ref": "OWASP API2:2023"
  }],
  "escalation": "judgment-day", "auto_fix": false,
  "timestamp": "2026-09-17T11:45:00Z"
}
```

## Receipt Schema (Canonical)

```json
{
  "id": "rdd-receipt-{seq}",
  "freeze": "HEAD-{12}-{8}",
  "tier": 0, "files": [], "lines_changed": 0,
  "verdict": "PASS|WARN|FAIL|SKIP",
  "4r": { "risk": 0, "read": 0, "rel": 0, "res": 0 },
  "fixes_applied": 0, "blockers": [],
  "escalation": null, "auto_fix": false,
  "timestamp": "ISO-8601"
}
```

## Recovery

### scope-changed
**Trigger:** Files modified after freeze, before review completes.
**Action:** Detect via `git diff HEAD -- <frozen-files>` → non-empty = scope changed. Re-freeze, re-assess tier, void previous review.

```json
{
  "recovery": { "type": "scope-changed",
    "original_freeze": "HEAD-a1b2c3d4e5f6-9f8e7d6c",
    "new_freeze": "HEAD-b2c3d4e5f6a7-1a2b3c4d",
    "original_tier": 1, "new_tier": 2 }
}
```

### stale snapshot
**Trigger:** HEAD moved since freeze (commit/checkout).
**Action:** Detect via HEAD mismatch. Warn, re-freeze, void all prior gates.

```json
{
  "recovery": { "type": "stale-snapshot",
    "original_freeze": "HEAD-c3d4e5f6a7b8-5e6f7a8b",
    "new_freeze": "HEAD-d4e5f6a7b8c9-9c0d1e2f",
    "review.status": "VOIDED" }
}
```

## Human/Negotiated Parity (Tier 2)

Human-in-the-loop for: override verdict, negotiate scope (split PR), accept risk.

**Negotiated envelope:**
```json
{
  "negotiation": {
    "original_verdict": "FAIL",
    "human_verdict": "PASS_WITH_CONDITIONS",
    "conditions": ["Add rate limit in follow-up PR"],
    "approver": "luis@team.dev",
    "timestamp": "2026-09-17T12:00:00Z"
  }
}
```

## Freeze Verification

```bash
CURRENT=$(git rev-parse --short HEAD | cut -c1-12)
FREEZE_HEAD=$(jq -r '.freeze' rdd-receipt-003.json | cut -d'-' -f2)
[ "$CURRENT" = "$FREEZE_HEAD" ] && echo "Valid" || echo "STALE — re-freeze"
```

Use `odd-freeze.ps1` for consistent freeze generation.

## Anti-patterns

| Pattern | Detection | Consequence |
|---------|-----------|-------------|
| Skip freeze tier 0 | No HEAD ref | Retroactive freeze |
| Re-use old receipt | Hash mismatch | Gates voided |
| Auto-fix tier 2 FAIL | Fix without judgment-day | Revert + escalate |
| Override without conditions | PASS_NO_CONDITIONS tier 2 | Reject |

## Refs
code-review-agent/reference.md*judgment-day/SKILL.md*quality-gate/SKILL.md
