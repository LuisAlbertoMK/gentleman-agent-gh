# analysis-mode — Reference Materials

> **Externalized from** .agents/skills/analysis-mode/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
## EXAMPLES (4-5)

### Example 1: Full Codebase Health Analysis
```bash
!analisis
```
**Trigger**: User runs `!analisis` on a 15-file PR
**Flow**: project-mapper detects React+Node stack → 6 specialists (security, infra, frontend, perf, datascience, docs) → parallel analysis → synthesis table → persist to `docs/mejoras/2026-08-16-gentleman-agent-gh-analisis.md` → Engram save with topic_key `analysis/gentleman-agent-gh`
**Output**: 8-dim findings table, risk matrix, top-15 recommendations, trend vs previous baseline

### Example 2: Process/Workflow Meta-Analysis
```bash
!analisis --meta
```
**Trigger**: User wants to analyze team workflow, not code
**Flow**: Bypasses scope guard (no file-count check) → specialists focus on: communication patterns, tooling friction, protocol adherence, handoff quality → output: `docs/mejoras/2026-08-16-meta-workflow-analisis.md`
**Key difference**: No code specialists; adds process-analyst, comms-analyst roles

### Example 3: Targeted Subsystem Analysis
```bash
!analisis --scope auth
```
**Trigger**: Focus on authentication subsystem only
**Flow**: project-mapper scopes to `src/auth/**` → 3 specialists (security, infra, arch) → reduced synthesis → output scoped to auth findings only
**Use case**: Pre-deploy audit of critical path

### Example 4: Cross-Project Pattern Analysis
```bash
!analisis --cross-project
```
**Trigger**: Analyze patterns across multiple indexed projects
**Flow**: Loads cross-project-wisdom skill → searches Engram for `analysis:*` across projects → synthesizes recurring patterns → outputs `docs/mejoras/2026-08-16-cross-project-patterns.md`
**Specialists**: pattern-miner, architecture (shared)

### Example 5: Regression-Focused Analysis
```bash
!analisis --since v2.1.0
```
**Trigger**: Compare current state vs tagged release
**Flow**: git diff v2.1.0..HEAD → scope to changed files only → specialists validate no regressions in 8 dims → trend analysis auto-populated from Engram baseline
**Output**: Regression report with delta from baseline

---

## TESTING (3 scenarios)

### Test 1: Scope Guard Enforcement
```bash
# Setup: Create PR with 5 changed files
git diff --name-only HEAD~1 | wc -l  # → 5
!analisis
```
**Expected**: HALT with message "Scope guard: <10 files changed. Use code-review-agent instead."
**Verification**: No analysis file created, no Engram save, BLOCKED logged for forbidden tools

### Test 2: --meta Bypass Works
```bash
# Same 5-file PR
!analisis --meta
```
**Expected**: Analysis proceeds (no HALT), process-focused specialists run, output to `docs/mejoras/*-meta-*.md`
**Verification**: Engram save with type=architecture, topic_key includes "meta"

### Test 3: Persistence & Trend Detection
```bash
# Run analysis twice, 1 week apart
!analisis  # Run 1: baseline
# ... make changes ...
!analisis  # Run 2: should show trend
```
**Expected**: Run 2 output includes `## Trend vs Previous` with delta: improvements/regressions/new/stale counts
**Verification**: Engram has two observations with same topic_key `analysis/<project>`, mem_search returns both

---

## EDGE CASES (4)

### Edge Case 1: No Previous Analysis Baseline
**Situation**: First-ever analysis on a project
**Handling**: P4a Compare → `mem_search` returns empty → output "No previous analysis—baseline" in Trend section
**No error**: Graceful degradation, not a failure

### Edge Case 2: Specialist Returns No Findings
**Situation**: e.g., datascience specialist on pure frontend project
**Handling**: P1 step 4 → output `SKIPPED-datascience`, synthesis continues with remaining specialists
**No gap**: Synthesis table notes "N/A" for that dimension

### Edge Case 3: >30 Findings Truncation
**Situation**: Large legacy codebase produces 45 findings
**Handling**: P3 → top-15 by risk in main table, remaining 30 in `## Appendix: Additional Findings`
**Verification**: Total findings count preserved in metadata, none lost

### Edge Case 4: Engram Conflict on Save
**Situation**: Concurrent analysis on same project creates conflicting observations
**Handling**: `mem_save` returns `judgment_required=true` → agent iterates `mem_judge` per candidate → relation=compatible (same topic, different timestamps) → both persisted
**Verification**: Two observations with same topic_key, different timestamps, both retrievable

---

## ANTI-PATTERNS (2)

### Anti-Pattern 1: Implementing Fixes During Analysis
**Violation**: Analysis output includes code changes or commits
**Why it breaks**: Gate explicitly forbids Write/Edit/Bash (except git read-only). Analysis is PLAN-ONLY.
**Correct**: Output → `docs/mejoras/**` only. Implementation is separate task/delegation.
**Detection**: `BLOCKED:Write[analysis-gate]` / `BLOCKED:Edit[analysis-gate]` in logs

### Anti-Pattern 2: Skipping Specialist Diversity
**Violation**: Running only 1-2 specialists (e.g., just security + perf)
**Why it breaks**: 8-dim validation requires coverage. Missing dims = blind spots (e.g., no datascience → data quality issues missed; no docs → DX gaps invisible).
**Correct**: Always 5-6 specialists minimum. Public site → +seo = 7.
**Detection**: Synthesis table shows N/A for unassigned dimensions → flagged in risk matrix
