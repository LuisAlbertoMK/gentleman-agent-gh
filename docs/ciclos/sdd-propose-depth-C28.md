# SDD-Propose Depth Analysis (C28)

## Overview
The `sdd-propose` skill creates Structured Design Document (SDD) change proposals from explorations or user descriptions. It operates in four storage modes (`engram`, `openspec`, `hybrid`, `none`) and follows a 6-step process with interactive proposal shaping.

---

## 4-5 Examples

### Example 1: Feature Addition — JWT Refresh Token Rotation (openspec mode)
**Input**: User wants to add automatic refresh token rotation to auth system.
**Exploration**: `sdd/auth-refresh/explore` exists with risk analysis.
**Proposal Output** (`openspec/changes/auth-refresh/proposal.md`):
```markdown
# Proposal: JWT Refresh Token Rotation

Add automatic refresh token rotation with sliding window expiry to mitigate token theft.

### In Scope - Auth Middleware + Token Service
### Out of Scope - Password reset flow, OAuth2 providers

> Contract with sdd-spec. Research `openspec/specs/` first.
### New Capabilities - `rotateRefreshToken`: Issues new refresh token on each access token refresh, invalidates old
### Modified Capabilities - `validateAccessToken`: Accepts rotated refresh tokens within grace window

| Area | Impact | Description |
|---|---|---|
| `src/auth/tokens.ts` | Modified | Add rotation logic, grace window config |
| `src/auth/middleware.ts` | Modified | Handle rotated token validation |
| `src/config/auth.ts` | New | Rotation window, max rotations per session |

| Risk | Likelihood | Mitigation |
|---|---|---|
| Token replay during grace window | Medium | Short grace window (30s), audit log on reuse |
| Clock skew causing premature invalidation | Low | NTP sync, configurable skew tolerance |

- Revert: Toggle `AUTH_REFRESH_ROTATION=false` env var, deploy previous token service
- [ ] 99.9% refresh requests succeed without re-login
- [ ] Zero token reuse incidents in audit log over 30 days
```

### Example 2: Technical Debt — Replace Legacy Event Bus (hybrid mode)
**Input**: Exploration `sdd/event-bus-replace/explore` documents current pub/sub coupling issues.
**Proposal Output** (Engram `sdd/event-bus-replace/proposal` + `openspec/changes/event-bus-replace/proposal.md`):
```markdown
# Proposal: Replace Legacy Event Bus with Typed Event Channels

Decouple domain events from infrastructure; add compile-time event contracts.

### In Scope - Event definitions, publisher/subscriber interfaces, migration adapters
### Out of Scope - External webhook integrations, message persistence layer

> Contract with sdd-spec. Research `openspec/specs/` first.
### New Capabilities - `EventChannel<T>`: Type-safe publish/subscribe with schema validation
### Modified Capabilities - `DomainEventBus`: Deprecated in favor of `EventChannel`, adapter provided

| Area | Impact | Description |
|---|---|---|
| `src/events/channel.ts` | New | Generic channel implementation |
| `src/events/legacy-adapter.ts` | New | Bridge for gradual migration |
| `src/modules/*/events.ts` | Modified | Migrate to typed channels per module |

| Risk | Likelihood | Mitigation |
|---|---|---|
| Runtime type mismatches in production | High | Schema validation at channel boundary, integration tests |
| Migration partial completion | Medium | Feature flag per module, rollback adapter |

- Revert: Flip `EVENT_CHANNELS_ENABLED=false`, legacy bus remains active
- [ ] All 12 domain modules migrated within 2 sprints
- [ ] Zero type-related event failures in staging
```

### Example 3: Bug Fix — Race Condition in Cache Invalidation (engram mode)
**Input**: User describes "cache sometimes serves stale data after write".
**Proposal Output** (Engram `sdd/cache-race-fix/proposal` only):
```markdown
# Proposal: Fix Cache Invalidation Race Condition

Write-through cache invalidation race allows stale reads between DB commit and cache purge.

### In Scope - Cache invalidation path, write transaction boundary
### Out of Scope - Read-replica lag, distributed cache coherence

> Contract with sdd-spec. Research `openspec/specs/` first.
### New Capabilities - None
### Modified Capabilities - `invalidateCache`: Now awaits DB commit confirmation before purge

| Area | Impact | Description |
|---|---|---|
| `src/cache/invalidator.ts` | Modified | Move invalidation after transaction commit hook |
| `src/db/transaction.ts` | Modified | Add post-commit callback registry |

| Risk | Likelihood | Mitigation |
|---|---|---|
| Increased write latency | Low | Async invalidation with idempotency key |
| Double invalidation on retry | Low | Idempotency keys deduplicate |

- Revert: Revert `invalidator.ts` to pre-fix version
- [ ] Zero stale reads in 1M write/read cycles (load test)
- [ ] Write latency p99 < 5ms increase
```

### Example 4: Architectural Change — Introduce Feature Flag Framework (none mode)
**Input**: Team needs progressive rollout capability; no exploration exists.
**Proposal Output** (inline return only, no persistence):
```markdown
# Proposal: Feature Flag Framework

Lightweight feature flag system for progressive rollouts and kill switches.

### In Scope - Flag definition, evaluation, audit logging, admin UI
### Out of Scope - A/B testing analytics, user segmentation engine

> Contract with sdd-spec. Research `openspec/specs/` first.
### New Capabilities - `FeatureFlags`: Evaluation API, `FlagDefinition`: Schema with targeting rules
### Modified Capabilities - None

| Area | Impact | Description |
|---|---|---|
| `src/flags/` | New | Core framework (evaluation, storage, admin) |
| `src/middleware/flags.ts` | New | Request-scoped flag evaluation |

| Risk | Likelihood | Mitigation |
|---|---|---|
| Flag evaluation latency on hot paths | Medium | In-memory cache, eval at middleware entry |
| Flag drift across instances | Low | Centralized config source, short TTL |

- Revert: Remove `src/flags/`, remove middleware registration
- [ ] Flag evaluation p99 < 1ms
- [ ] 100% flag changes audited with user/context
```

### Example 5: Migration — Database Schema v2 (openspec mode)
**Input**: Exploration `sdd/db-migration-v2/explore` covers zero-downtime migration strategy.
**Proposal Output**:
```markdown
# Proposal: Database Schema Migration v2 — Zero-Downtime

Expand `users` table with profile JSONB, add `audit_log` table, migrate indexes.

### In Scope - Schema changes, migration scripts, backward-compatible reads
### Out of Scope - Data warehouse sync, CDC pipeline changes

> Contract with sdd-spec. Research `openspec/specs/` first.
### New Capabilities - `AuditLogRepository`: Immutable event store
### Modified Capabilities - `UserRepository`: Profile now JSONB, backward-compatible getters

| Area | Impact | Description |
|---|---|---|
| `migrations/002_profile_audit.sql` | New | Expand users, create audit_log, dual-write triggers |
| `src/repos/user.ts` | Modified | JSONB profile accessors with fallback |
| `src/repos/audit.ts` | New | Append-only audit log queries |

| Risk | Likelihood | Mitigation |
|---|---|---|
| Migration lock contention | High | Online schema change (pt-online-schema-change), batch size 1000 |
| Dual-write inconsistency | Medium | Transactional outbox pattern, reconciliation job |

- Revert: Run `migrations/002_down.sql`, rollback deploy
- [ ] Migration completes < 10 min on 50M rows
- [ ] Zero data loss verified by row count reconciliation
```

---

## 3 Testing Patterns

### Pattern 1: Proposal Contract Validation (Unit)
```typescript
// tests/sdd-propose/contract.test.ts
import { createProposal } from '../../.agents/skills/sdd-propose';

describe('Proposal Contract', () => {
  it('includes all required sections', () => {
    const proposal = createProposal({
      change: 'test-change',
      mode: 'none',
      exploration: { problem: 'X', approach: 'Y' }
    });
    
    expect(proposal).toContain('# Proposal:');
    expect(proposal).toContain('### In Scope');
    expect(proposal).toContain('### Out of Scope');
    expect(proposal).toContain('### New Capabilities');
    expect(proposal).toContain('### Modified Capabilities');
    expect(proposal).toContain('| Area | Impact | Description |');
    expect(proposal).toContain('| Risk | Likelihood | Mitigation |');
    expect(proposal).toMatch(/Revert:/);
    expect(proposal).toMatch(/\[ \] .*Measurable/);
  });

  it('enforces <450 word budget', () => {
    const proposal = createProposal({ /* large input */ });
    const words = proposal.split(/\s+/).length;
    expect(words).toBeLessThan(450);
  });

  it('uses tables over prose for Affected Areas & Risks', () => {
    const proposal = createProposal({ /* input */ });
    const areaTableMatches = proposal.match(/\| Area \| Impact \| Description \|\n\|[-\|]+\|\n(\|.*\|\n)+/g);
    const riskTableMatches = proposal.match(/\| Risk \| Likelihood \| Mitigation \|\n\|[-\|]+\|\n(\|.*\|\n)+/g);
    expect(areaTableMatches).toBeTruthy();
    expect(riskTableMatches).toBeTruthy();
  });
});
```

### Pattern 2: Mode Behavior Verification (Integration)
```typescript
// tests/sdd-propose/modes.test.ts
import { runPropose } from '../../.agents/skills/sdd-propose';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

describe('Storage Modes', () => {
  const tempDir = '/tmp/sdd-propose-test';

  beforeEach(() => {
    if (existsSync(tempDir)) rmSync(tempDir, { recursive: true });
  });

  it('openspec: creates proposal.md in openspec/changes/{change}/', async () => {
    await runPropose({ change: 'test-feat', mode: 'openspec', root: tempDir });
    const path = join(tempDir, 'openspec/changes/test-feat/proposal.md');
    expect(existsSync(path)).toBe(true);
    expect(readFileSync(path, 'utf8')).toContain('# Proposal:');
  });

  it('engram: saves to Engram with topic_key sdd/{change}/proposal', async () => {
    const mockEngram = { save: jest.fn() };
    await runPropose({ change: 'test-feat', mode: 'engram', engram: mockEngram });
    expect(mockEngram.save).toHaveBeenCalledWith(
      expect.objectContaining({ topic_key: 'sdd/test-feat/proposal', type: 'architecture' })
    );
  });

  it('hybrid: does both openspec AND engram', async () => {
    const mockEngram = { save: jest.fn() };
    await runPropose({ change: 'test-feat', mode: 'hybrid', root: tempDir, engram: mockEngram });
    expect(existsSync(join(tempDir, 'openspec/changes/test-feat/proposal.md'))).toBe(true);
    expect(mockEngram.save).toHaveBeenCalled();
  });

  it('none: returns inline only, no persistence', async () => {
    const mockEngram = { save: jest.fn() };
    const result = await runPropose({ change: 'test-feat', mode: 'none', engram: mockEngram });
    expect(result).toContain('**Change**: test-feat');
    expect(result).toContain('inline');
    expect(mockEngram.save).not.toHaveBeenCalled();
    expect(existsSync(join(tempDir, 'openspec'))).toBe(false);
  });
});
```

### Pattern 3: Interactive Question Round Simulation (E2E)
```typescript
// tests/sdd-propose/question-round.test.ts
import { shapeProposal } from '../../.agents/skills/sdd-propose';

describe('Interactive Proposal Shaping', () => {
  it('generates 3-5 questions covering all 10 categories', () => {
    const questions = shapeProposal({
      problem: 'Users abandon cart at payment',
      exploration: { gap: 'No saved payment methods' }
    });
    
    const categories = [
      'business problem', 'target users', 'business rules',
      'product outcome', 'current-state gap', 'impact',
      'edge cases', 'decision gaps', 'scope boundaries', 'business risk'
    ];
    
    expect(questions.length).toBeGreaterThanOrEqual(3);
    expect(questions.length).toBeLessThanOrEqual(5);
    
    categories.forEach(cat => {
      const covered = questions.some(q => q.toLowerCase().includes(cat));
      expect(covered).toBe(true);
    });
  });

  it('summarizes assumptions and offers correction round', () => {
    const result = shapeProposal({ /* input */ }, { answers: { /* mock answers */ } });
    expect(result).toContain('## Proposal question round');
    expect(result).toContain('Assumptions:');
    expect(result).toMatch(/Round 2|correction/);
  });

  it('writes question round marker when blocked from asking', () => {
    const result = shapeProposal({ /* input */ }, { blocked: true });
    expect(result).toContain('## Proposal question round');
    expect(result).toContain('blocked from asking');
  });
});
```

---

## 4 Edge Cases

### Edge Case 1: Exploration Missing or Corrupted
**Scenario**: `sdd/{change}/explore` doesn't exist or has parse errors.
**Behavior**: 
- Skill continues with user description as primary input
- Logs warning: "Exploration not found at sdd/{change}/explore — using user description only"
- Proposal notes: "Exploration unavailable; proposal based on user input"
- Does NOT fail — exploration is optional per spec

### Edge Case 2: Existing Proposal in openspec Mode (Update vs Create)
**Scenario**: `openspec/changes/{change}/proposal.md` already exists.
**Behavior**:
- Reads existing proposal
- Merges: preserves user-edited sections (marked with `<!-- USER_EDIT -->`)
- Updates: In Scope, Out of Scope, Affected Areas, Risks from new exploration
- Adds changelog entry: `## Changelog\n- YYYY-MM-DD: Updated from exploration v2`
- Never overwrites without preserving user annotations

### Edge Case 3: Spec Changes Conflict with Proposal
**Scenario**: `openspec/specs/` has capabilities that contradict proposed New/Modified Capabilities.
**Behavior**:
- Detects conflict during "Research `openspec/specs/` first" step
- Adds `## Spec Conflict Warning` section listing each conflict
- Example: Spec says `UserRepository` is final; proposal says Modified
- Requires human resolution before sdd-spec can proceed
- Does NOT auto-resolve — escalates to orchestrator

### Edge Case 4: Zero In-Scope Items (Pure Deletion/Removal)
**Scenario**: Proposal only removes code (e.g., "Remove deprecated v1 API").
**Behavior**:
- In Scope lists removal deliverables: "Remove `src/api/v1/`, `tests/api/v1/`"
- New Capabilities: "None"
- Modified Capabilities: Lists each removed capability with "→ Removed"
- Affected Areas table uses `Removed` impact type
- Success criteria: "Zero references to v1 API in codebase", "All v1 tests deleted"

---

## 2 Anti-Patterns

### Anti-Pattern 1: Proposal as Implementation Spec (Over-Specification)
**Bad**: Writing pseudo-code, exact function signatures, or algorithm details in proposal.
```markdown
# BAD — Implementation detail leak
### New Capabilities - `calculateShipping`: 
  function calculateShipping(cart: Cart, zone: Zone): Promise<number> {
    const base = zone.baseRate;
    const weight = cart.items.reduce((sum, i) => sum + i.weight, 0);
    return base + weight * zone.perKg;  // ALGORITHM HERE
  }
```
**Why it fails**: 
- Violates SDD phase separation — proposal owns *what* and *why*, sdd-spec owns *how*
- Blocks sdd-design from exploring alternatives
- Creates merge conflicts when design evolves
- Budget overflow (>450 words)

**Correct**: 
```markdown
### New Capabilities - `calculateShipping`: Returns shipping cost for cart + zone, supports per-kg and flat-rate models
```

### Anti-Pattern 2: Vague Scope Boundaries (Scope Creep Enabler)
**Bad**: In Scope / Out of Scope written in prose without concrete deliverables.
```markdown
# BAD — Unverifiable scope
### In Scope - Improve authentication experience
### Out of Scope - Everything else not mentioned
```
**Why it fails**:
- No contract for sdd-spec to verify against
- Impossible to write measurable success criteria
- Reviewers cannot assess completeness
- "Improve auth experience" could mean 5 files or 50

**Correct**:
```markdown
### In Scope - `src/auth/login.ts`, `src/auth/register.ts`, `src/middleware/auth.ts` — JWT issuer, refresh flow, rate limiting
### Out of Scope - Password reset, OAuth2, MFA, session management
```

---

## Summary
The `sdd-propose` skill is a critical SDD phase gate that transforms exploration into a reviewable, contract-driven proposal. Key success factors:
1. **Strict word budget** (<450) forces clarity
2. **Tables over prose** enables mechanical verification
3. **Four storage modes** support different team workflows
4. **Interactive shaping** catches ambiguity early
5. **Rollback + success criteria** makes proposals actionable

Violations of the two anti-patterns above are the #1 cause of SDD pipeline rework.