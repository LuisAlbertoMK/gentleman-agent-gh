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

## Judge Pattern Taxonomy — Extended (movido por ADR-048, cycle32-p2)

> Fuente: Zylos 2026-04-10 — 6 patterns. Detalle movido de .agents/skills/judgment-day/SKILL.md líneas 41-55 para cumplir ≤3200B.

| # | Pattern | Latency/Cost | When (JD mapping) |
|---|---------|--------------|-------------------|
| 1 | Offline eval | async, large judge OK | This skill (ROJA dual blind) |
| 2 | Online runtime verifier | 76–162ms budget, small judge (Luna-2 3–8B, Prometheus 7B, Lynx 8B ≈97% cheaper at 0.88–0.95 acc) | ROJA hotfix fast-path (optional, not default) — **gated-optional**: small judge, opcional pre-output. Ver Pattern 2 en SKILL.md |
| 3 | Self-consistency / self-critique | Best-of-N + majority vote, cheapest, strongest in code/math | Our 2-profile blind → implicit majority-of-2 |
| 4 | Reflexion | Only with external grounding (tests, git diff, retrieval) — intrinsic "check your work" degrades reasoning | Grounded re-judge (max 2 rounds): `-Rounds 1|2 -GroundingEvidence '<citations>'` → `GROUNDED` exit 0; ungrounded → `UNGROUNDED` exit 1 — **operational Ronda3-S2** |
| 5 | Constitutional / RLAIF | training-time; runtime = generate→critique against constitution→revise | Runtime loop operational Ronda3-S2: `-RepeatFinding` → `CONSTITUTIONAL-LOOP: generate→critique→revise`; gap>1.5 → immune-system; repeat offense → permanent rule |
| 6 | Inference-time reward model | ranker over N samples, gated before output | Operational Ronda3-S2 as verifier mode: `-Rank 'label:score,...'` → argmax winner (manual pre-push); auto hook wiring = future boundary |

> **3-boundary rule** (Zylos): instrument judges before (a) user-facing output, (b) irreversible tool exec (git push, file Write), (c) persistent memory writes (Engram). Skip per-step judging to manage cost. Our gate covers (a)+(b); (c) is future.

**Small vs Large judges:** large proprietary (GPT-4o, Claude 3.7) for high-stakes ROJA; small distilled for throughput inline. JD two profiles should diverge on that axis when one is "reasoning" tier. Small judges (Luna-2, Prometheus, Lynx ~97% cheaper) para Pattern 2; large judges para Pattern 1/3. Gated-optional patterns 2/5/6 — detalle aquí, SKILL.md deja 1 línea cada una apuntando aquí.

**Gated-optional guidance:**
- Pattern 2 (online verifier 76–162ms): small judge opcional pre-output — activar solo en hotfix ROJA donde latencia <200ms importa; default OFF.
- Pattern 5 (constitutional/RLAIF): runtime loop operational Ronda3-S2 (`-RepeatFinding` → loop lines); training-time RLAIF stays out of scope.
- Pattern 6 (reward model): operational as manual verifier mode (`-Rank`); auto pre-push hook wiring is future (touches `.githooks/`, out of scope) — documented boundary, not phantom wire.

## Pattern 1 — Offline Eval (operational, Ronda2-S3)

> Scope: ROJA dual blind with LARGE judge. Small judges never decide ROJA (see Pattern 2).

**Procedure**
1. Select target + freeze diff — cite `git diff HEAD | git hash-object --stdin` in the verdict.
2. Resolve 2 profiles via `jd_profile_selector` first-match; identical → second = `security` (SKILL.md Rule 4).
3. Run 2× `code-review-agent` blind (no shared context), 120s timeout, retry once.
4. Synthesize per P2; write eval-log entry (format below); FIX/BLOCKER → `external-auditor` calibration (Rule 5).

**Eval-log entry** (attach for ROJA FIX/BLOCKER):
```json
{
  "target": "src/api/users.ts",
  "freeze": "HEAD-<short>-<diff8>",
  "profiles": ["architect", "security"],
  "blind": true,
  "verdicts": ["FIX", "FIX"],
  "synthesis": "Confirmed — same root cause (users.ts:51-52, ±5 lines)",
  "calibration": "external-auditor AGREE | gap 0.0"
}
```

**Anti-rationalization (P1)**

| Rationalization | Red Flag | Verification |
|---|---|---|
| "Small judge is enough for ROJA" | Small-only verdict on ROJA | P1 mandates LARGE-judge dual blind; small judge = P2 pre-check only |
| "Pre-fix eval covers post-fix code" | Eval-log freeze ≠ current diff | Re-run eval on post-fix diff; freeze hash must match HEAD diff |

**Verification (P1)**
- Eval log present with freeze hash matching `git diff HEAD | git hash-object --stdin`.
- `blind: true` + two distinct profiles (or architect/security fallback) recorded in the log.

## Pattern 2 — Online Runtime Verifier (operational, Ronda2-S3)

> Gated-optional, ROJA hotfix fast-path only, default OFF. Mechanical pre-check — NEVER a final verdict (SKILL.md Rule 2 still mandates dual blind).

**Activation criteria** (all must hold; else skip straight to dual blind):
1. Zone = ROJA hotfix where latency <200ms matters.
2. `scripts/jd-verifier.ps1 -Zone ROJA -FastPath` reachable (`bin/fast.exe` present).
3. Caller accepts ESCALATE fallback (over-budget/slow → dual-judge, exit 1).

**Budget — design vs measured**
- Design (Zylos, `docs/mejoras/2026-09-01-agent-improvement-research-plan.md:208-211`): 76–162ms;
  enforced upper bound in `scripts/jd-verifier.ps1:103` (`$elapsedMs -le 162` → `VERIFY-OK`, else `ESCALATE`).
- Measured 2026-09-23, `bin/fast.exe --gate --json` internal `elapsedMs`, n=12:
  `100, 109, 111, 112, 120, 126, 145, 151, 155, 166, 176, 178` —
  min 100ms · max 178ms · median ~136ms · 10/12 ≤162ms (83%) ·
  2/12 over-budget → `ESCALATE` exit 1 (fail-closed).
- Live fail-closed proof (same session): `151ms → VERIFY-OK` exit 0;
  `166ms → ESCALATE` exit 1. Over-budget never passes.
- Note: wall-clock process spawn (~240–460ms observed) is NOT the gated quantity — the gate consumes
  internal `elapsedMs` only. Do not "optimize" wall-clock; the budget contract is internal.

**Live transcript (2026-09-23, this repo)**
```powershell
PS> & scripts/jd-verifier.ps1 -Zone ROJA -FastPath
SELF-CONSISTENCY: profiles A/B = majority-of-2 (diverge → tie-break by higher severity)
VERIFY-OK mechanical (151ms)   # exit 0
PS> & scripts/jd-verifier.ps1 -Zone ROJA -FastPath -Json
{"verifier":"jd-verifier","zone":"ROJA","fastPath":{"ran":true,"passed":true,"elapsedMs":166,"decision":"ESCALATE"},"rounds":{"value":0,"capped":false},"constitutional":false,"timestamp":"..."}   # exit 1
```

**Anti-rationalization (P2)**

| Rationalization | Red Flag | Verification |
|---|---|---|
| "VERIFY-OK = APPROVED" | VERIFY-OK cited as final verdict | Mechanical pre-check only; dual blind still mandatory (SKILL.md Rule 2) |
| "Over-budget still counts" | elapsedMs >162 treated as pass | Over budget → ESCALATE exit 1, never VERIFY-OK (fail-closed, 166ms case above) |
| "Wall-clock must fit 162ms" | Spawn time cited as budget breach | Budget contract = internal elapsedMs; wall-clock includes spawn, not gated |

**Verification (P2)**
- `& scripts/jd-verifier.ps1 -Zone ROJA -FastPath` → `VERIFY-OK (≤162ms)` exit 0 or `ESCALATE` exit 1; any other outcome → treat as ESCALATE.
- Pester `scripts/tests/jd-verifier.Tests.ps1` PASS — covers budget boundary (97ms→OK, 200ms→ESCALATE) and missing-exe ESCALATE.

## Pattern 3 — Self-Consistency (operational, Ronda2-S3)

> Cheapest pattern; strongest in code review. Our 2-profile blind IS the majority-of-2 vote.

**Procedure**
1. Prerequisite: blind isolation (SKILL.md Rule 2) — shared-context verdicts are not votes.
2. Both CLEAN → APPROVED. Same root-cause (±5 lines) → Confirmed.
3. Diverge → triage → fix both → re-judge on diff delta only (max 2 rounds → ASK user, Rule 3).
4. Tie-break (irreconcilable within budget): higher severity wins, flagged `CALIB: GAP` → `external-auditor` on FIX/BLOCKER.

**Worked tie-break**
```json
{
  "target": "src/payments/stripe.ts",
  "votes": [
    {"profile": "architect", "verdict": "FIX", "severity": "MEDIUM"},
    {"profile": "security", "verdict": "FIX", "severity": "HIGH"}
  ],
  "synthesis": "Diverge → higher severity wins (HIGH) → fix both → re-judge round 1/2",
  "output": "JD-src/payments/stripe.ts | Profiles: architect/security | 4R | Confirmed:0 | JDGMNT: ESCALATED | CALIB: GAP"
}
```

**Anti-rationalization (P3)**

| Rationalization | Red Flag | Verification |
|---|---|---|
| "Agreed-with-myself counts" | Two verdicts, one shared context | Votes valid only blind (Rule 2); shared context → re-run blind |
| "3rd re-judge will converge" | Count >2 | Max 2 → ASK user (Rule 3); `jd-verifier.ps1 -Rounds 3` prints `ASK-USER`, exit 2 |
| "Lower severity is enough" | Diverge resolved downward | Tie-break = higher severity wins; downward resolution → re-triage |

**Verification (P3)**
- Confirmed claims cite file ±5 lines with both profiles' lines visible.
- Re-judge rounds ≤2 with diff-delta scope; round-3 attempt → `ASK-USER`, exit 2.

## Pattern 4 — Reflexion Grounded (operational, Ronda3-S2)

> Zylos constraint: Reflexion helps ONLY with external grounding (tests, git diff, retrieval).
> Intrinsic "check your work" without citations degrades reasoning — an uncited re-judge verdict
> is not evidence and fails closed.

**Procedure**
1. Re-judge scope = diff delta only (max 2 rounds, P3 cap still applies: round 3 → `ASK-USER` exit 2).
2. Every re-judge verdict MUST cite ≥1 external anchor: `tests:<file>#L<line>` (failing/passing test),
   `diff:<freeze8>` (re-captured `git diff HEAD | git hash-object --stdin`), or `retrieval:<KB-id>`.
3. Enforce mechanically: `scripts/jd-verifier.ps1 -Rounds <1|2> -GroundingEvidence '<citations>'`.
4. Initial review (`-Rounds 0`) needs no grounding — Reflexion constrains re-judges only.

**Live transcript (2026-09-23, this repo)**
```powershell
PS> & scripts/jd-verifier.ps1 -Zone ROJA -Rounds 1
UNGROUNDED re-judge (no tests/diff/retrieval citation) — ESCALATE   # exit 1
PS> & scripts/jd-verifier.ps1 -Zone ROJA -Rounds 1 -GroundingEvidence 'tests:jd-verifier.Tests.ps1#L12;diff:HEAD'
GROUNDED re-judge (tests:jd-verifier.Tests.ps1#L12;diff:HEAD)       # exit 0
```

**Anti-rationalization (P4)**

| Rationalization | Red Flag | Verification |
|---|---|---|
| "Re-check passed, trust me" | Re-judge verdict with zero citations | P4: no citations → `UNGROUNDED` exit 1; cite or it didn't happen |
| "Diff delta is grounding enough" | Delta cited but no test/retrieval anchor | ≥1 external anchor required (tests file:line, diff hash, or KB id) |
| "Initial review needs grounding too" | `-Rounds 0` blocked for no citations | Grounding gate applies to re-judges only (`Rounds ≥1`); initial review unaffected |

**Verification (P4)**
- `& scripts/jd-verifier.ps1 -Zone ROJA -Rounds 1` (no evidence) → `UNGROUNDED`, exit 1.
- Same with `-GroundingEvidence '<citations>'` → `GROUNDED`, exit 0.
- Pester `scripts/tests/jd-verifier.Tests.ps1` P4 context PASS (grounded/ungrounded/initial/JSON).

## Pattern 5 — Constitutional Runtime Loop (operational, Ronda3-S2)

> Training-time RLAIF is out of scope. Runtime subset only:
> generate → critique (against ROJA constitution) → revise → grounded re-judge (P4).

**Constitution (ROJA)**: SKILL.md Rules 1–6 + reference.md anti-patterns table.
Critique checks the candidate verdict against each rule; any violation → revise, then re-judge
grounded (P4 citations mandatory — an ungrounded revise never closes the loop).

**Procedure**
1. Generate: 2× blind verdicts (P1/P3).
2. Critique: test verdict against constitution; gap>1.5 vs `external-auditor` → flag.
3. Revise: fix flagged findings; emit loop marker:
   `scripts/jd-verifier.ps1 -RepeatFinding` → `CONSTITUTIONAL` + `CONSTITUTIONAL-LOOP: generate→critique→revise`.
4. Close: grounded re-judge (P4) on the revise diff; repeat offense (same root-cause twice)
   → `immune-system` permanent rule (`CALIB: IMMUNE_TRIGGERED | Rule: {anti-pattern-id}`).

**Anti-rationalization (P5)**

| Rationalization | Red Flag | Verification |
|---|---|---|
| "One critique pass fixes the constitution" | Single revise, loop never re-judged | P5: revise without grounded re-judge → re-run; loop closes on P4 evidence only |
| "Repeat offense, new verdict" | Same root-cause re-approved twice | Second occurrence → `immune-system` rule, not another revise |
| "RLAIF training covers this" | Training-time claim cited for runtime gap | Training-time RLAIF out of scope; runtime loop is the enforcement |

**Verification (P5)**
- `-RepeatFinding` emits both `CONSTITUTIONAL` and `CONSTITUTIONAL-LOOP` lines, exit 0.
- Repeat root-cause → `immune-system` rule recorded (Edge Case 4 output flags).

## Pattern 6 — Reward Ranker Pre-Push (operational verifier mode, Ronda3-S2)

> Ranker over N candidate verdicts, gated before push. Orders candidates — NEVER approves:
> winner still requires dual-blind confirmation (SKILL.md Rule 2).

**Procedure**
1. Collect N candidate verdicts with scalar scores (severity-weighted confidence, auditor delta, etc.).
2. Rank: `scripts/jd-verifier.ps1 -Rank 'label:score,label:score,...'` → deterministic argmax.
   Ties → first max wins (documented, tested). Malformed/empty spec → `RANKER-ERROR`, exit 1.
3. Take winner → dual-blind confirmation (P1) before APPROVED. Ranker output cited in verdict log.

**Live transcript (2026-09-23, this repo)**
```powershell
PS> & scripts/jd-verifier.ps1 -Zone ROJA -Rank 'a:0.7,b:0.9,c:0.4'
RANKER: winner=b (0.9) over 3 samples   # exit 0
```

**Boundary (honest, not phantom)**: ranker executes for real as a verifier mode (transcript above,
Pester P6 context). Automatic pre-push hook invocation (`.githooks/pre-push` calling the ranker)
is FUTURE — it touches hook files outside this slice's AllowedPaths, so it is documented here
instead of wired-in-false. Manual invocation pre-push is the operational contract until then.

**Anti-rationalization (P6)**

| Rationalization | Red Flag | Verification |
|---|---|---|
| "Ranker winner = APPROVED" | `RANKER: winner=` cited as final verdict | Ranker orders only; winner needs dual blind (rule 2) |
| "Hook runs the ranker" | Pre-push auto-wire claimed | No hook calls the ranker (verify: `pre-push` has zero `jd-verifier` refs); manual mode is the contract |
| "Ties mean consensus" | Tie silently picked | Ties → first max wins, deterministic and logged; re-judge on tie if stakes are ROJA |

**Verification (P6)**
- `-Rank 'a:0.7,b:0.9,c:0.4'` → `RANKER: winner=b (0.9) over 3 samples`, exit 0 (executed, not documented-in-false).
- Malformed spec → `RANKER-ERROR`, exit 1. Ties → first max. JSON `ranker` object carries winner/score/samples.
- Pester `scripts/tests/jd-verifier.Tests.ps1` P6 context PASS.

> **Ronda 3 closure (R3-S2, 2026-09-23):** Patterns 4–6 operational above (grounding gate + loop +
> ranker mode, all executed + Pester-covered). R2-4 (research-plan.md:208-211) CLOSED 6/6.
> Remaining future: P6 auto pre-push hook wiring (hook files out of scope) — see Pattern 6 boundary.
