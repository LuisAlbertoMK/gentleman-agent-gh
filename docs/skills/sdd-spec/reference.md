# sdd-spec — Reference Materials

> **Externalized from** .agents/skills/sdd-spec/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## EXAMPLES (5)

### Example 1: NEW Spec — Authentication Domain
```markdown
# Authentication Specification

## Purpose
Enable secure user authentication with JWT tokens, supporting login, logout, token refresh, and session invalidation.

## Requirements
- MUST issue JWT access token (15 min) + refresh token (7 days) on valid credentials
- MUST reject invalid credentials with 401 + "invalid credentials"
- MUST invalidate refresh token on logout (single-device) or global logout (all devices)
- SHOULD rotate refresh token on each use (detect replay)
- MAY support "remember me" extending refresh token to 30 days

## Scenarios
### GIVEN valid email/password WHEN POST /auth/login THEN 200 + access+refresh tokens
### GIVEN invalid password WHEN POST /auth/login THEN 401 + "invalid credentials"
### GIVEN expired access token + valid refresh WHEN POST /auth/refresh THEN 200 + new tokens
### GIVEN reused refresh token WHEN POST /auth/refresh THEN 401 + revoke all user tokens
### GIVEN global logout WHEN POST /auth/logout-all THEN 200 + all sessions invalidated
```

### Example 2: MODIFIED Spec — Delta for Profile Domain
```markdown
# Delta for Profile

## MODIFIED | Validate display name
### Requirement | MUST validate 3-50 chars | (Previously: must not be empty)
#### Scenario: valid length
- GIVEN a valid 20-char display name WHEN PUT /profile/name THEN 200 + DB updated
#### Scenario: too short
- GIVEN a 2-char display name WHEN PUT /profile/name THEN 400 + "too short"
#### Scenario: too long
- GIVEN a 51-char display name WHEN PUT /profile/name THEN 400 + "too long"

## ADDED | Sanitize profanity
### Requirement | SHOULD sanitize profanity from display name
#### Scenario: profanity detected
- GIVEN a display name containing profanity WHEN PUT /profile/name THEN 200 + sanitized name stored
```

### Example 3: REMOVED Spec — Deprecated Feature
```markdown
# Delta for LegacyExport

## REMOVED | CSV export endpoint
### Requirement | MUST provide GET /export/csv | (Reason: replaced by /export/stream with format param)
### Migration | Update clients to POST /export/stream with {"format": "csv"}
```

### Example 4: RENAMED Spec — Domain Restructure
```markdown
# Delta for Notifications → Messaging

## RENAMED | Notifications → Messaging
### Requirement | Messaging domain (Previously: Notifications domain)
### Migration | Update imports from @/notifications to @/messaging; rename DB table notifications → messages
```

### Example 5: Complex Multi-Domain Delta
```markdown
# Delta for OrderProcessing

## ADDED | Idempotency keys
### Requirement | MUST accept Idempotency-Key header on POST /orders
#### Scenario: duplicate key returns original
- GIVEN order created with key "abc123" WHEN POST /orders with same key THEN 200 + original order

## MODIFIED | Payment validation
### Requirement | MUST validate payment before confirming | (Previously: validated after)
#### Scenario: invalid payment rejected early
- GIVEN invalid card WHEN POST /orders THEN 402 + "payment failed" (order not created)

## ADDED | Webhook retry policy
### Requirement | MUST retry failed webhooks with exponential backoff (1m, 5m, 15m, 1h)
#### Scenario: max retries exhausted
- GIVEN webhook fails 4 times WHEN retry exhausted THEN mark delivery FAILED + alert on-call
```

---

## TESTING PATTERNS (3)

### Pattern 1: Automated Scenario Validation
```bash
# Extract scenarios from spec and validate they follow G/W/T format
pcregrep -M '### GIVEN .* WHEN .* THEN .*' openspec/changes/*/specs/*/spec.md
# Exit 0 = all scenarios valid; Exit 1 = malformed scenario found
```

### Pattern 2: Test Generation from Specs
```markdown
# Each G/W/T scenario maps 1:1 to a test case
# Example mapping:
# GIVEN valid name WHEN PUT /profile/name THEN 200
# → test("updates profile name with valid input", async () => { ... })
#
# CI gate: spec scenario count == test count (enforced in sdd-verify)
```

### Pattern 3: Spec-to-Test Traceability
```yaml
# In test files: @spec {requirement-id} {scenario-name}
# Example:
# @spec REQ-PROFILE-001 valid-length
# test("updates profile name with valid input", ...)
#
# Verification: grep -r "@spec" tests/ | wc -l matches spec scenario count
```

---

## EDGE CASES (4)

| Edge Case | Detection | Handling |
|-----------|-----------|----------|
| **Empty delta** | No changes in proposal's Affected Areas vs existing spec | Write "no spec changes needed" in delta; skip file creation; return `status: success` with note |
| **Budget exceeded** (>650 words) | Word count check before persist | Split by domain into multiple delta files; each <650 words; link via `Related:` header |
| **Missing existing spec** (MODIFIED domain) | Read fails on `openspec/specs/{domain}/spec.md` | Treat as NEW spec; write full spec with Purpose; note "(Created from delta — no prior spec)" |
| **Cross-domain dependency** | Proposal references capability in another domain | Add `Depends on: {other-domain}` in delta header; ensure other domain's spec processed first |

---

## ANTI-PATTERNS (2)

### Anti-Pattern 1: Partial MODIFIED Blocks
```markdown
# WRONG — loses scenarios not explicitly edited
## MODIFIED | Validate display name
### Requirement | MUST validate 3-50 chars | (Previously: must not be empty)
#### Scenario: too short
- GIVEN a 2-char display name WHEN PUT /profile/name THEN 400
# Missing: valid length scenario, too long scenario → ARCHIVE REPLACES THESE
```

```markdown
# CORRECT — copy FULL block then edit
## MODIFIED | Validate display name
### Requirement | MUST validate 3-50 chars | (Previously: must not be empty)
#### Scenario: valid length
- GIVEN a valid 20-char display name WHEN PUT /profile/name THEN 200
#### Scenario: too short
- GIVEN a 2-char display name WHEN PUT /profile/name THEN 400
#### Scenario: too long
- GIVEN a 51-char display name WHEN PUT /profile/name THEN 400
```

### Anti-Pattern 2: Implementation Leakage in Specs
```markdown
# WRONG — describes HOW, not WHAT
### Requirement | MUST hash password with bcrypt cost 12 before storing in users table
#### Scenario: password stored
- GIVEN password "secret" WHEN POST /auth/register THEN bcrypt hash in users.password column
```

```markdown
# CORRECT — describes WHAT (behavior)
### Requirement | MUST store passwords securely (irreversible, salted)
#### Scenario: password not stored in plaintext
- GIVEN password "secret" WHEN POST /auth/register THEN GET /users/me shows no plaintext password
#### Scenario: same password → different hashes
- GIVEN two users with same password WHEN registered THEN password hashes differ
```
