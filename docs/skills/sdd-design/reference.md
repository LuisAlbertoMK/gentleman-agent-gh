# sdd-design — Reference Materials

> **Externalized from** .agents/skills/sdd-design/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## Testing Patterns (verify design before implementation)

### 6.1 Design Review Checklist

- [ ] **Traceability**: Every requirement in proposal has ≥1 design decision addressing it
- [ ] **Completeness**: All 5 sections (Arch, Data, API, Security, Testing) filled or explicit "N/A"
- [ ] **Alternatives**: ≥2 alternatives documented with rejection rationale for each major decision
- [ ] **Dependencies**: No cycles in module dependency graph (verify with `madge --circular`)
- [ ] **Testability**: Domain has zero external deps; ports defined for all outbound calls
- [ ] **Rollback**: Explicit migration rollback steps for every schema change
- [ ] **Observability**: Logging/metrics/tracing points identified per module boundary

### 6.2 Requirements Traceability Matrix

| Proposal Requirement | Design Section | Decision | Verification Method |
|---|---|---|---|
| REQ-001: Idempotent orders | API Design | IdempotencyKey in request | Integration test: duplicate POST returns same order |
| REQ-002: Stripe payment | Arch Decision | Ports & Adapters | Unit test: PaymentPort mock; E2E: Stripe webhook |
| REQ-003: GDPR delete | Security | Data port + erase endpoint | Integration test: erase removes all PII |

### 6.3 Risk-Based Verification Gates

| Risk Factor | Gate | Pass Criteria |
|---|---|---|
| Cross-context boundary | Contract test | Consumer-driven contract (Pact) passes |
| Async/concurrency | Chaos test | No data loss under 100 concurrent creates |
| Performance (N+1) | Load test | p95 < 200ms at 10x expected load |
| Error paths | Fault injection | All 5xx paths return structured error, no crashes |

## Edge Cases (when to adapt or skip)

### 7.1 Trivial Changes — Skip Design Phase

**Criteria**: Single file, <50 lines changed, no API/schema/security impact, no new dependencies.
**Action**: Orchestrator routes directly to `sdd-tasks` with proposal as input.
**Document**: Add `design: skipped — trivial change` to proposal.

### 7.2 Legacy Migration — Strangler Fig Pattern

**Context**: Replacing legacy module incrementally.
**Design additions**:
- Legacy adapter implementing new port (wraps old code)
- Feature flag to route traffic: `useNewOrderModule: boolean`
- Parallel run: both paths execute, compare results, log discrepancies
- Cutover: flip flag, monitor, remove legacy after N releases

### 7.3 Distributed Systems Boundaries

**Additional design sections required**:
- **Service contract**: Consumer-driven contract (Pact) or gRPC protobuf
- **Failure modes**: Timeout, retry, circuit breaker config per downstream
- **Consistency**: Eventual vs. strong — saga vs. 2PC, compensation logic
- **Observability**: Distributed trace headers (W3C trace-context), correlation IDs

### 7.4 Hotfix / Expedited Path

**Criteria**: Production incident, <4 hour fix window.
**Process**:
1. 15-min design sketch (arch decision + risk + rollback only)
2. Verbal review with 1 peer (async if needed)
3. Implement → verify → deploy
4. **Within 48h**: Expand to full design doc, add missing sections, link ADR

## Anti-Patterns (STOP doing these)

### 8.1 Over-Engineering / Design by Committee

**Symptoms**: 3+ design reviews for a 2-file change; "future-proofing" for hypothetical requirements; abstract factory for single implementation.
**Fix**: Time-box design to 2h max. Default to simplest architecture that satisfies current requirements. Add abstraction only when second implementation exists (Rule of Three).

### 8.2 Design Without Implementation Path

**Symptoms**: Beautiful architecture diagram but no migration plan, no adapter wiring, no test strategy; "we'll figure it out in tasks."
**Fix**: Design MUST include: module wiring (DI config), migration phases with rollback, and test strategy per risk factor. If any missing → design is incomplete, return `partial`.

## Output Envelope

```markdown
**Status**: success | partial | blocked
**Summary**: [1-3 sentences of what was designed]
**Artifacts**: Engram `sdd/{change-name}/design` | `openspec/changes/{change-name}/design.md`
**Next**: sdd-spec or sdd-tasks
**Risks**: [risks discovered, or "None"]
**Skill Resolution**: injected | fallback-registry | fallback-path | none
```

## Constraints

- Output must be implementation-ready — the `sdd-tasks` phase should be able to consume it directly
- Do NOT write implementation code — only design
- Flag any unknowns as risks, do NOT make assumptions
- Size budget: design doc ≤ 2KB; ADR ≤ 500 words per decision
- Time budget: 2h max for design phase (triggers escalation if exceeded)

(End of file - total ~2800 bytes)
