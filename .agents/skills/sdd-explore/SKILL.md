---
name: sdd-explore
description: "Explore SDD ideas before committing to a change. Trigger: orchestrator launches exploration or requirement clarification."
triggers: "SDD explore, explore ideas, investigation, discovery, SDD exploration"
delegate_only: true
changelog: docs/ciclos/cycle28-20260815.md
---

> **ORCHESTRATOR GATE**: `skill()` → ORCHESTRATOR STOP. Delegate to `sdd-explore` sub-agent. Executors only.

## Executor Override
If you ARE the `sdd-explore` sub-agent, gate does not apply. Execute directly.

## Language
Artifacts default to English. Spanish: neutral/professional unless regional variant requested.

## Purpose
Explore codebase for a topic/feature, compare approaches, return structured analysis. Research only by default; create `exploration.md` only for named changes.

## Input
- Topic or feature to explore
- Artifact store mode (`engram | openspec | hybrid | none`)

## Persistence
Follow §B (retrieval) and §C (persistence) from `skills/_shared/sdd-phase-common.md`:
- **engram**: Optionally read `sdd-init/{project}`. Save as `sdd/{change}/explore` (or `sdd/explore/{topic-slug}` standalone).
- **openspec**: Read `skills/_shared/openspec-convention.md`.
- **hybrid**: Both — Engram + filesystem.
- **none**: Return result only.
- **Retrieval**: engram searches `sdd-init/{project}` + `sdd/`; openspec reads config + specs; none uses orchestrator prompt.

## Workflow
1. **Load Skills** — §A from `sdd-phase-common.md`
2. **Understand Request** — Parse: feature? bug fix? refactor? Domain?
3. **Investigate** — Read entry points, search related code, check tests, identify patterns, map dependencies.
4. **Analyze Options** — Compare approaches:
| Approach | Pros | Cons | Complexity |
|---|---|---|---|
| Option A | ... | ... | Low/Med/High |
| Option B | ... | ... | Low/Med/High |
5. **Persist Artifact** — Mandatory for named changes. §C from `sdd-phase-common.md`: artifact `explore`, topic_key `sdd/{change}/explore`, type `architecture`
6. **Return Analysis** (write to `exploration.md` if saving):
```markdown
## Exploration: {topic}

### Current State
{How system works today relevant to topic}

### Affected Areas
- `path/file.ext` — {why}

### Approaches
1. **{Name}** — {desc}
   - Pros: ... | Cons: ... | Effort: Low/Med/High
2. **{Name}** — {desc}
   - Pros: ... | Cons: ... | Effort: Low/Med/High

### Recommendation
{Chosen approach and why}

### Risks
- {Risk 1}

### Ready for Proposal
{Yes/No — what to tell user}
```

## Rules
- Only file you MAY create: `exploration.md` in change folder
- DO NOT modify existing code
- ALWAYS read real code, never guess
- Keep CONCISE — summary, not novel
- State if info insufficient or request too vague
- Return envelope per §D from `sdd-phase-common.md`

## Examples

### Example 1: New Feature — Add Webhook Retry Logic
**Topic**: "Explore adding exponential backoff retry for webhook deliveries"
**Approaches Compared**:
| Approach | Pros | Cons | Complexity |
|---|---|---|---|
| In-process queue + worker | Simple, no infra | Loses retries on crash | Low |
| Redis-based queue (Bull/BullMQ) | Persistent, scalable | Adds Redis dependency | Medium |
| Message broker (RabbitMQ/Kafka) | Durable, observable | Operational overhead | High |
**Recommendation**: Redis queue — balances durability and complexity for most teams.

### Example 2: Bug Fix — Race Condition in Cache Invalidation
**Topic**: "Investigate cache stampede when multiple requests invalidate same key"
**Current State**: `CacheService.invalidate()` deletes key, then `get()` rebuilds — concurrent callers rebuild simultaneously.
**Approaches Compared**:
| Approach | Pros | Cons | Complexity |
|---|---|---|---|
| Mutex/lock per key | Prevents duplicate rebuilds | Lock contention at scale | Low |
| Stale-while-revalidate | Serves stale, rebuilds async | Stale data window | Medium |
| Request coalescing (single-flight) | One rebuild, all wait | Slightly more complex | Medium |
**Recommendation**: Request coalescing — eliminates stampede without locking.

### Example 3: Refactor — Extract Shared Validation Logic
**Topic**: "Explore consolidating duplicate validation across 5 controllers"
**Affected Areas**: `src/controllers/{user,order,product,cart,auth}.ts`
**Approaches Compared**:
| Approach | Pros | Cons | Complexity |
|---|---|---|---|
| Shared validation module | DRY, testable | Coupling risk | Low |
| Decorator-based | Declarative, composable | Learning curve | Medium |
| Zod schemas + central registry | Type-safe, self-documenting | Schema maintenance | Medium |
**Recommendation**: Zod schemas — best DX and type safety.

### Example 4: Architecture Decision — Auth Strategy Migration
**Topic**: "Explore migrating from session cookies to JWT + refresh tokens"
**Approaches Compared**:
| Approach | Pros | Cons | Complexity |
|---|---|---|---|
| Full cutover | Clean break | High risk, needs coordination | High |
| Dual-mode (both work) | Zero-downtime rollout | Complexity during transition | Medium |
| Per-route migration | Incremental | Long coexistence period | Medium |
**Recommendation**: Dual-mode with feature flag — safest migration path.

### Example 5: Performance — N+1 Query in GraphQL Resolvers
**Topic**: "Investigate DataLoader batching for User.posts resolver"
**Current State**: Each `user.posts` call executes separate query.
**Approaches Compared**:
| Approach | Pros | Cons | Complexity |
|---|---|---|---|
| DataLoader per-request | Standard, caches automatically | Requires context setup | Low |
| Join in root resolver | Single query | Tight coupling, less flexible | Low |
| Subgraph/@defer (Federation) | Native GraphQL | Requires Federation setup | High |
**Recommendation**: DataLoader — minimal change, maximal impact.

## Testing Patterns

### Pattern 1: Exploration Output Validation
```typescript
// Verify exploration.md follows required structure
const requiredSections = [
  'Current State',
  'Affected Areas',
  'Approaches',
  'Recommendation',
  'Risks',
  'Ready for Proposal'
];
requiredSections.forEach(section => {
  expect(explorationContent).toContain(`## ${section}`);
});
```

### Pattern 2: Approach Comparison Table Completeness
```typescript
// Each approach must have Pros, Cons, Complexity
const approaches = parseApproachesTable(explorationContent);
approaches.forEach(approach => {
  expect(approach.pros).toBeTruthy();
  expect(approach.cons).toBeTruthy();
  expect(['Low', 'Medium', 'High']).toContain(approach.complexity);
});
```

### Pattern 3: Artifact Persistence Verification
```typescript
// After explore phase, verify artifact saved correctly
const artifact = await engram.get('sdd/{change}/explore');
expect(artifact.type).toBe('architecture');
expect(artifact.topic_key).toMatch(/^sdd\/.*\/explore$/);
expect(artifact.content).toContain('Recommendation');
```

## Edge Cases

### Edge Case 1: Vague or Overly Broad Request
**Input**: "Explore improving performance"
**Handling**: Return early with clarification request — list specific areas (DB, API, rendering, bundle size) and ask user to narrow scope.

### Edge Case 2: No Existing Code to Reference
**Input**: "Explore adding GraphQL to a REST-only codebase"
**Handling**: Document as greenfield exploration. Current State = "No GraphQL infrastructure exists". Approaches = library comparison (Apollo, Yoga, Mercurius, gql.tada). Still produce valid exploration.md.

### Edge Case 3: Conflicting Patterns in Codebase
**Input**: "Explore standardizing error handling"
**Finding**: Codebase uses 3 patterns: try/catch, Result<T,E>, and exceptions.
**Handling**: Document all 3 in Current State. Approaches table includes "Adopt Pattern X" for each. Recommendation acknowledges migration cost.

### Edge Case 4: Exploration Reveals Blockers
**Input**: "Explore adding real-time notifications"
**Finding**: No WebSocket infrastructure; requires new service, load balancer config, scaling strategy.
**Handling**: Set `Ready for Proposal: No — infrastructure blockers identified`. List blockers in Risks. Still saves artifact for traceability.

## Anti-Patterns

### Anti-Pattern 1: Guessing Without Reading Code
**Bad**: "The auth middleware probably uses JWT, so I'll recommend RS256"
**Good**: Read `src/middleware/auth.ts`, check `package.json` for `jsonwebtoken` vs `jose`, verify algorithm in use. Evidence-backed only.

### Anti-Pattern 2: Creating Implementation Instead of Exploration
**Bad**: Writing `webhook-retry.ts` implementation during explore phase
**Good**: Produce `exploration.md` with approaches. Implementation happens in `sdd-spec` → `sdd-design` → `sdd-apply` phases only.