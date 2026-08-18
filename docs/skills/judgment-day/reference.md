# judgment-day — Reference Materials

> **Externalized from** .agents/skills/judgment-day/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Examples

### Example 1: Standard ROJA Review — Both Clean
```json
{
  "target": "src/auth/jwt.ts",
  "profiles": ["architect", "security"],
  "reviews": [
    {"profile": "architect", "verdict": "CLEAN", "findings": []},
    {"profile": "security", "verdict": "CLEAN", "findings": []}
  ],
  "synthesis": "APPROVED",
  "output": "JD-src/auth/jwt.ts | Profiles: architect/security | 4R | Confirmed:0 | JDGMNT: APPROVED | CALIB: OK"
}
```

### Example 2: Confirmed Finding — Same Root Cause
```json
{
  "target": "src/api/users.ts:45-67",
  "profiles": ["architect", "security"],
  "reviews": [
    {"profile": "architect", "verdict": "FIX", "findings": [{"file": "src/api/users.ts", "line": 52, "severity": "HIGH", "type": "N+1 query"}]},
    {"profile": "security", "verdict": "FIX", "findings": [{"file": "src/api/users.ts", "line": 51, "severity": "HIGH", "type": "N+1 query"}]}
  ],
  "synthesis": "Confirmed — same root cause (file ±5 lines)",
  "output": "JD-src/api/users.ts | Profiles: architect/security | 4R | Confirmed:1 | JDGMNT: ESCALATED | CALIB: GAP"
}
```

### Example 3: Different Findings — Triage Required
```json
{
  "target": "src/payments/stripe.ts",
  "profiles": ["architect", "security"],
  "reviews": [
    {"profile": "architect", "verdict": "FIX", "findings": [{"file": "src/payments/stripe.ts", "line": 23, "severity": "MEDIUM", "type": "Missing idempotency key"}]},
    {"profile": "security", "verdict": "FIX", "findings": [{"file": "src/payments/stripe.ts", "line": 67, "severity": "HIGH", "type": "PII in logs"}]}
  ],
  "synthesis": "Different findings → triage → fix both → re-judge (round 1/2)",
  "output": "JD-src/payments/stripe.ts | Profiles: architect/security | 4R | Confirmed:0 | JDGMNT: ESCALATED | CALIB: GAP"
}
```

### Example 4: Re-Judge Round 2 — Diff Delta Only
```json
{
  "target": "src/payments/stripe.ts",
  "profiles": ["architect", "security"],
  "round": 2,
  "diff_delta": "src/payments/stripe.ts:23:+idempotencyKey; src/payments/stripe.ts:67:-console.log(user.email)",
  "reviews": [
    {"profile": "architect", "verdict": "CLEAN", "findings": []},
    {"profile": "security", "verdict": "CLEAN", "findings": []}
  ],
  "synthesis": "Both CLEAN on diff delta → APPROVED",
  "output": "JD-src/payments/stripe.ts | Profiles: architect/security | 4R | Confirmed:0 | JDGMNT: APPROVED | CALIB: OK"
}
```

### Example 5: Identical Profiles Forced to Security
```json
{
  "target": "src/config/env.ts",
  "jd_profile_selector": [{"match": "basename", "pattern": "*.config.ts", "profile": "architect"}],
  "resolved_profiles": ["architect", "security"],
  "note": "Single match 'architect' duplicated → second forced to 'security' per Rule 4"
}
```

## Testing Patterns

### Pattern 1: Unit — Zone Filter Logic
```typescript
// tests/judgment-day/zone-filter.test.ts
import { filterZone } from '../src/judgment-day/zone-filter';

test('ROJA triggers dual review', () => {
  expect(filterZone('ROJA')).toEqual({ mode: 'dual', profiles: 2 });
});

test('AMARILLA triggers single review', () => {
  expect(filterZone('AMARILLA')).toEqual({ mode: 'single', profiles: 1 });
});

test('VERDE skips review', () => {
  expect(filterZone('VERDE')).toEqual({ mode: 'skip', profiles: 0 });
});
```

### Pattern 2: Integration — Profile Selector Resolution
```typescript
// tests/judgment-day/profile-selector.test.ts
import { resolveProfiles } from '../src/judgment-day/profile-selector';

test('Fallback to architect when no match', () => {
  const selector = [{ match: 'path', pattern: 'src/auth/*', profile: 'security' }];
  expect(resolveProfiles(selector, 'src/api/users.ts')).toEqual(['architect', 'security']);
});

test('First match wins (ordered)', () => {
  const selector = [
    { match: 'basename', pattern: '*.test.ts', profile: 'testing' },
    { match: 'path', pattern: 'src/*', profile: 'architect' }
  ];
  expect(resolveProfiles(selector, 'src/auth/login.test.ts')).toEqual(['testing', 'security']);
});

test('Identical profiles forces security as second', () => {
  const selector = [{ match: 'fallback', profile: 'architect' }];
  expect(resolveProfiles(selector, 'any/file.ts')).toEqual(['architect', 'security']);
});
```

### Pattern 3: E2E — Full Pipeline with Re-Judge
```typescript
// tests/judgment-day/pipeline.e2e.test.ts
import { runJudgmentDay } from '../src/judgment-day/pipeline';

test('Full pipeline: different findings → fix → re-judge → APPROVED', async () => {
  const target = 'src/test/target.ts';
  const initialReviews = [
    { profile: 'architect', verdict: 'FIX', findings: [{ line: 10, type: 'coupling' }] },
    { profile: 'security', verdict: 'FIX', findings: [{ line: 50, type: 'injection' }] }
  ];
  const fixDiff = 'src/test/target.ts:10:-tightCoupling();+looseCoupling(); src/test/target.ts:50:-rawSQL();+paramSQL();';
  
  const result = await runJudgmentDay({ target, initialReviews, fixDiff, maxRejudge: 2 });
  
  expect(result.rounds).toBe(2);
  expect(result.finalVerdict).toBe('APPROVED');
  expect(result.calibration).toBe('OK');
});
```

## Edge Cases

### Edge Case 1: Review Timeout & Retry
- **Scenario**: One `code-review-agent` exceeds 120s timeout
- **Behavior**: Auto-retry once with same profile; if second attempt fails → mark review as ERROR, synthesize with available review only
- **Output flag**: `JDGMNT: ESCALATED | CALIB: TIMEOUT_RETRY_FAILED`

### Edge Case 2: Profile Selector Returns No Matches
- **Scenario**: `jd_profile_selector` has patterns but none match target file
- **Behavior**: Fallback to `["architect", "security"]` — never run with single profile
- **Log**: `WARN: No profile match for {target}, using fallback [architect, security]`

### Edge Case 3: Re-Judge Round 3 Attempted
- **Scenario**: After 2 re-judge rounds, findings still differ
- **Behavior**: STOP, do NOT auto-continue. Output: `JDGMNT: ESCALATED | CALIB: MAX_REJUDGE_EXCEEDED` → ASK user for direction
- **User prompt**: "3rd re-judge needed. Findings: {summary}. Proceed? (y/n/force-approve)"

### Edge Case 4: External Auditor Calibration Gap
- **Scenario**: `external-auditor` returns severity gap >1.5 vs JD synthesis
- **Behavior**: Trigger `immune-system` with permanent fix — create anti-pattern rule in AGENTS.md
- **Output**: `CALIB: IMMUNE_TRIGGERED | Rule: {anti-pattern-id}`

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| JD on VERDE | Zone filter (P0) |
| Same profile both | Force second "security" (Rule 4) |
| Cross-contamination | Blind, no shared context (Rule 2) |
| 3+ re-judge | Cap 2 → ASK (Rule 3) |
| Skip FIX calibration | → external-auditor (Rule 5) |
| Push ROJA no JD | Block (Rule 6) |

## Refs
- [code-review-agent](../code-review-agent/SKILL.md) · [external-auditor](../external-auditor/SKILL.md) · [immune-system](../immune-system/SKILL.md) · [quality-gate](../quality-gate/SKILL.md) · `review-rules.jsonc`
