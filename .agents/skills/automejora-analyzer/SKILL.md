---
name: automejora-analyzer
description: "Analyzes auto-mejora cycles — detects patterns, scores improvements, validates SkillOpt gates, surfaces drift."
triggers: "auto-mejora, automejora, improvement analysis, cycle analysis, SkillOpt validation, improvement scoring"
---

## When to Use
Analyze continuous improvement cycles (macro + micro). Detect patterns across cycles, validate SkillOpt gates, score deltas, surface drift/anti-patterns. Trigger via explicit request or auto after macro cycle completes.

## Core Responsibilities
1. **Pattern Detection**: Scan reflection logs, accepted/rejected edits, immune-system catalog for recurring themes
2. **SkillOpt Validation**: Verify each fix meets gate — size ≤20%/3KB, syntax parse, config trivial, target ≥+0.1, no dim ≤-0.3
3. **Drift Scoring**: Track dimension deltas across cycles; flag regression trends before they breach thresholds
4. **Cycle Health**: Verify budget decay compliance, inter-track ≥30, epoch review completeness
5. **Anti-Pattern Surfacing**: Cross-reference immune-system catalog + rejected-edits.json for repeat offenders

## Inputs
- `CYCLE.md` — current cycle state (budget, inter-track, phase)
- `.learnings/accepted-edits.json` / `rejected-edits.json` — edit history with deltas
- `reflection/{date}/*.md` — per-task micro-reflections
- `immune-system/ANTI-PATTERN-CATALOG.md` — known anti-patterns
- `auto-metrics` output (`!score` JSON) — dimension scores per cycle

## Outputs
- Analysis report: `docs/analisis/automejora-{cycle}-{date}.md`
- Drift alerts (if any dim trending ↓ across ≥3 cycles)
- SkillOpt gate pass/fail per fix with evidence
- Pattern summary: top 3 recurring themes + extraction candidates (≥2 reps)

## Examples

### Example 1: Macro Cycle Post-Mortem Analysis
**Trigger**: Cycle 28 completes (inter=31). User requests "analiza ciclo 28".
1. Load `CYCLE.md` → extract budget curve, phase timestamps, inter-track
2. Load all `reflection/2026-08-*/*.md` for this cycle
3. Load `accepted-edits.json` / `rejected-edits.json` for cycle 28
4. Run `!score --cycle 28` → get dimension deltas
5. Cross-reference immune-system catalog for patterns in this cycle
6. **Output**: `docs/analisis/automejora-28-20260815.md` with:
   - Budget compliance: actual vs cosine curve (PASS/FAIL)
   - SkillOpt gate results per fix (table: fix, target dim, delta, gate PASS/FAIL)
   - Top patterns: "empty catch blocks" (3 reps), "missing null checks" (2 reps)
   - Extraction candidates: `catch-block-logging` skill, `dto-null-guard` skill
   - Drift check: "query efficiency" trending -0.08/cycle → ALERT

### Example 2: SkillOpt Gate Validation (Pre-Commit)
**Trigger**: Fix proposed for `quality-gate` skill (protected file).
1. Parse proposed edit diff → calculate size % and KB
2. Run syntax check: `pwsh -noprofile -c ". 'D:\gentleman-agent-gh\scripts\bash-safe.ps1'; & 'D:\gentleman-agent-gh\scripts\syntax-check.ps1' -File .agents/skills/quality-gate/SKILL.md"`
3. Run `!score --baseline` → capture pre-fix dimensions
4. Apply fix in memory → run `!score --compare` → get deltas
5. **Validate**:
   - Size ≤20% of file AND <3KB → PASS
   - Syntax parse OK → PASS
   - Config trivial (no schema/auth/API change) → PASS
   - Target dim (e.g., "review thoroughness") ≥+0.1 → PASS
   - No dim ≤-0.3 → PASS
6. **Output**: Gate result + evidence. If any FAIL → block commit, log to rejected-edits.json

### Example 3: Drift Detection Across Cycles
**Trigger**: Scheduled (epoch review) or manual "check drift".
1. Load last 10 cycles' `!score` outputs from accepted-edits.json
2. Compute per-dimension slope (linear regression over cycle index)
3. Flag dimensions with slope < -0.05/cycle AND p-value < 0.1
4. **Output**: Drift report with:
   - Dimension | Slope | Cycles tracked | Trend | Alert?
   - query_efficiency | -0.08 | 10 | ▼▼▼ | YES (breach in ~4 cycles)
   - search_latency | -0.02 | 10 | ▼ | WATCH
   - review_thoroughness | +0.03 | 10 | ▲ | OK
5. Auto-create reflection task for flagged dimensions

### Example 4: Anti-Pattern Correlation Analysis
**Trigger**: "Why do we keep hitting empty catch blocks?"
1. Search immune-system catalog for "empty catch" → get pattern ID, count, first_seen
2. Search rejected-edits.json for edits touching catch blocks → count, contexts
3. Search accepted-edits.json for fixes → count, which rules applied
4. Correlate: pattern frequency vs. fix effectiveness (delta on "error visibility" dim)
5. **Output**: Correlation report:
   - Pattern: "empty catch" | Occurrences: 12 | First: cycle 3 | Last: cycle 28
   - Fix attempts: 5 | Successful (delta ≥+0.1): 2 | Failed: 3
   - Root cause: Template `try-catch` snippet lacks `Write-Debug`
   - Recommendation: Update template + add immune-system rule → `template-empty-catch`

### Example 5: Extraction Candidate Ranking
**Trigger**: End of macro cycle, auto-run before epoch review.
1. Aggregate all micro-reflection "Extract" sections across cycle
2. Group by proposed skill name / pattern keyword
3. Count reps per candidate; filter ≥2 reps
4. For each candidate: estimate impact (affected files × avg fix delta)
5. Rank by: reps desc → impact desc → novelty (not in existing skills)
6. **Output**: Ranked candidates table:
   | Rank | Candidate | Reps | Est. Impact | Novelty | Action |
   |------|-----------|------|-------------|---------|--------|
   | 1 | graphql-dataloader | 3 | 12 files × +0.25 | New | Create skill |
   | 2 | dto-validation | 4 | 8 files × +0.15 | Partial (exists) | Extend skill |
   | 3 | catch-block-logging | 5 | 20 files × +0.10 | New | Create skill |

## Testing Patterns

### Pattern 1: SkillOpt Gate Integration Test
```bash
# Setup: create temp skill with known-good fix
cp .agents/skills/self-improvement/SKILL.md /tmp/test-skill.md
edit /tmp/test-skill.md "Anti-Patterns" "Anti-Patterns\n6. **New anti-pattern** — description"
# Run analyzer gate
!automejora-analyzer validate-gate --file /tmp/test-skill.md --baseline-cycle 27
# Assert: gate PASS (size<3KB, syntax OK, trivial config, target dim +0.1, no dim -0.3)
```

### Pattern 2: Drift Detection Accuracy Test
```python
# Generate synthetic 10-cycle score history with known drift
import numpy as np
cycles = 10
base = {"query_eff": 8.5, "search_lat": 7.0, "review_thor": 6.0}
drift = {"query_eff": -0.08, "search_lat": -0.01, "review_thor": +0.02}
history = []
for i in range(cycles):
    scores = {k: base[k] + drift[k]*i + np.random.normal(0, 0.05) for k in base}
    history.append(scores)
# Feed to analyzer drift detection
result = automejora_analyzer.detect_drift(history, min_slope=-0.05, min_cycles=3)
# Assert: "query_eff" flagged (slope ≈ -0.08), "search_lat" NOT flagged (slope ≈ -0.01), "review_thor" NOT flagged
```

### Pattern 3: Pattern Correlation Test
```bash
# Create test immune-system catalog + edit logs with known correlation
echo '{"patterns": [{"id": "empty-catch", "count": 12, "first_cycle": 3}]}' > /tmp/catalog.json
echo '[{"cycle": 5, "pattern": "empty-catch", "delta": 0.15}, {"cycle": 12, "pattern": "empty-catch", "delta": -0.05}]' > /tmp/edits.json
# Run correlation
!automejora-analyzer correlate --catalog /tmp/catalog.json --edits /tmp/edits.json
# Assert: Output shows 2 fix attempts, 1 success (delta≥0.1), 1 failure, root cause identified
```

## Edge Cases

### Edge Case 1: Cycle Boundary Ambiguity
**Scenario**: Reflection logs span cycle boundary (e.g., task starts cycle 27, ends cycle 28).
**Resolution**: Attribute to cycle where `mem_save` timestamp falls. Use `CYCLE.md` phase timestamps as tiebreaker. Log ambiguity to analysis report.

### Edge Case 2: SkillOpt False Negative (Noise)
**Scenario**: Valid fix passes all objective checks but SkillOpt scores < threshold due to measurement noise.
**Resolution**: Allow 1 manual override per cycle with `override: true` + human justification in `mem_save`. Track override rate; if >20% of fixes overridden → recalibrate SkillOpt thresholds.

### Edge Case 3: Missing Baseline for Score Comparison
**Scenario**: `!score --baseline` never run for cycle N; cannot compute delta for cycle N+1.
**Resolution**: Synthesize baseline from last available `accepted-edits.json` scores + dimension definitions. Flag as `synthesized_baseline=true` in report. Do NOT block gate — but require explicit acknowledgment.

### Edge Case 4: Protected File Change Without Audit Trail
**Scenario**: Direct edit to protected file (e.g., `security-scanner/SKILL.md`) bypassing `!audit`.
**Resolution**: Pre-commit hook detects via git diff — blocks commit. Analyzer logs attempt to `rejected-edits.json` with reason="protected_file_no_audit". Requires `!audit` PASS + new commit.

## Anti-Patterns

### Anti-Pattern 1: Analysis Without Action
**Symptom**: Analyzer runs, produces report, but no follow-up (no skill extraction, no template fix, no immune-system update).
**Root Cause**: Treating analysis as "done" instead of "input to next step".
**Fix**: Enforce pipeline: Analysis → Extraction Candidates → SkillOpt Gate → Create/Extend Skill → Verify. Track in `accepted-edits.json`.

### Anti-Pattern 2: Cherry-Picking Dimensions
**Symptom**: Reporting only improved dimensions; hiding regressions in non-target dims.
**Root Cause**: Optimizing for "green report" instead of system health.
**Fix**: Mandatory output includes: worst dimension delta, all dimensions table, drift flags. Gate FAIL if any dim ≤-0.3 regardless of target.

## Non-Overlapping Boundaries
| Skill | Owns | automejora-analyzer Does NOT |
|-------|------|------------------------------|
| `self-improvement` | Macro/micro cycle execution, reflection capture | Execute cycles (analyzes completed cycles only) |
| `auto-metrics` | Scoring engine, dimension definitions | Calculate scores (consumes auto-metrics output) |
| `immune-system` | Anti-pattern catalog, immunization rules | Define anti-patterns (reads catalog for correlation) |
| `opencode-skill-creator` | Skill creation interview, scaffold | Create skills (recommends candidates to creator) |
| `external-auditor` | Blind review of protected files | Audit (validates SkillOpt gate, not code correctness) |

## Commit Simple
- One logical change per commit
- Conventional commits: `fix(automejora-analyzer): add drift detection edge case`
- No Co-Authored-By, no AI attribution

## Verify
Run `!automejora-analyzer validate-gate --file <skill>` after any skill edit. Run full analysis `!automejora-analyzer analyze --cycle <N>` at epoch review.