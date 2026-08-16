---
name: karpathy-loop
description: "Iterative prompt optimization — write, measure, cut, repeat with progressive compression"
triggers: "Karpathy loop, optimize prompt, measure tokens"
changelog: docs/ciclos/cycle28-20260815.md
---

## When to Use

## STYLE (5 Rules)
1. **ID+TASK=ENOUGH** — identity+task = enough
2. **MINIMAL** — no 10+ item lists or paragraphs
3. **FORMAT=INSTRUCT** — "Respond ONLY in JSON:{...}"
4. **CONSTRAINTS=FORMAT** — max X chars / code only
5. **IMPLICIT CoT** — no "step by step"; "Reason ONLY if ambiguous"

## LOOP: Write→Measure→Cut→Repeat
1. **WRITE**: role + task + 1-2 examples + output. Don't optimize yet.
2. **MEASURE**: chars/4 ≈ tokens. Score: correctness/conciseness/robustness
3. **CUT**: remove redundant→merge→simplify. No output change→cut.
4. **REPEAT**: score improves+tokens down→continue. Drops→revert. Stagnant→new tactic.

### Concrete example
**Write** (680/170 tok): "Review the following code diff. Focus on error handling..." → 6.3 avg
**Cut T1** (480/120): "Review this diff. Focus on error handling, readability..." → 7.3 ✓
**Cut T2** (340/85): "Senior reviewer. Review diff: 4R (Risk/Readability/Reliability/Resilience). Issue→line+problem+fix..." → 7.3 ✓
**Cut T3** (260/65): "Review diff via 4R. Issue: ln+problem+fix. Rate 1-10. <4=BLOCKER. MD." → 5.3 ✗ → **REVERT** to T2. Final: 340 chars/85 tok, 7.3/10.

## Scoring Table
| Score | Correctness | Conciseness | Robustness |
|-------|-------------|-------------|------------|
| 9-10 | All intents preserved | No wasted tokens | Covers all edge cases |
| 7-8 | Intents preserved, minor rephrase | Some filler | Most edge cases |
| 5-6 | Intent preserved, nuance lost | Wordy but functional | Key edge case missing |
| 3-4 | Intent partially lost | Redundant >2x optimal | Multiple gaps |
| 1-2 | Wrong output format/behavior | Bloated >3x optimal | Critical gaps |
Stop: avg ≥7 AND tokens <100. Revert if any score drops ≥3.

## Compression Levels
| Level | Target | What to cut |
|-------|--------|-------------|
| T1 | 20-30% | filler, transitions, "step by step" |
| T2 | 30-50% | merge redundant→bullets, remove context |
| T3 | 50-70% | template structures, shortcuts, minimal identity |

## Budget
ID+TASK: 20-50 | +example: +100-200 | +constraints: +50-100 | **OPTIMAL: 50-300**

## Decision — Remove?
Output changes?→keep · else concision?→remove · else clarity?→keep · else→remove

## STOP
Tokens <50 + works · 3 iterations no improvement · Fits in 1 line
**NEVER**: sacrifice correctness for tokens, or leave edge cases uncovered.

## Refs
lean-context · skill-improver · metricas · code-review-agent

## Examples

### Example 1: Code Review Prompt
**T0** (820/205): "You are a senior engineer. Review the following code changes. Look for bugs, security issues, performance problems, and style violations. Provide specific line numbers and suggested fixes." → 6.1
**T1** (540/135): "Senior reviewer. Review diff for bugs, security, perf, style. Line + issue + fix." → 7.4 ✓
**T2** (380/95): "Review diff. 4R: Risk/Readability/Reliability/Resilience. Each: ln → issue → fix. Rate 1-10. <4 = BLOCKER. MD." → 7.4 ✓
**T3** (280/70): "4R diff review. ln→issue→fix. Rate 1-10. <4=BLOCK. MD." → 5.1 ✗ → **REVERT to T2**. Final: 380/95, 7.4

### Example 2: Commit Message Generator
**T0** (650/162): "Write a conventional commit message for the following diff. Include type, scope, and description. Follow angular convention." → 5.8
**T1** (420/105): "Conventional commit from diff. type(scope): desc. Angular rules." → 6.9 ✓
**T2** (290/72): "Commit: type(scope): desc. Angular. feat/fix/docs/refactor/perf/test/chore." → 7.1 ✓
**T3** (200/50): "Commit: type(scope): desc. Angular." → 4.2 ✗ → **REVERT to T2**. Final: 290/72, 7.1

### Example 3: API Design Review
**T0** (980/245): "You are an API architect. Review this OpenAPI spec. Check REST conventions, naming, versioning, error formats, pagination, auth. Output issues with paths." → 6.0
**T1** (620/155): "API architect. OpenAPI review: REST, naming, versioning, errors, pagination, auth. Path + issue." → 7.2 ✓
**T2** (410/102): "OpenAPI audit. REST/naming/version/errors/page/auth. path→issue. Rate 1-10." → 7.3 ✓
**T3** (310/78): "OpenAPI: REST/naming/ver/err/page/auth. path→issue. 1-10." → 5.0 ✗ → **REVERT to T2**. Final: 410/102, 7.3

### Example 4: Test Case Generator
**T0** (720/180): "Generate comprehensive test cases for this function. Cover happy path, edge cases, error conditions, boundary values. Use pytest format." → 5.5
**T1** (480/120): "pytest tests for fn. Happy, edges, errors, boundaries." → 6.8 ✓
**T2** (320/80): "pytest fn. happy/edge/error/boundary. Arrange-Act-Assert." → 7.0 ✓
**T3** (240/60): "pytest. happy/edge/err/bound. AAA." → 4.8 ✗ → **REVERT to T2**. Final: 320/80, 7.0

### Example 5: Refactoring Plan
**T0** (1100/275): "Create a refactoring plan for this legacy module. Identify smells, prioritize by impact, define steps, estimate risk, include rollback." → 5.2
**T1** (700/175): "Refactor plan: smells→priority→steps→risk→rollback. Impact first." → 6.5 ✓
**T2** (480/120): "Refactor: smell→priority(impact)→steps→risk(1-5)→rollback. Top 3 only." → 7.2 ✓
**T3** (350/88): "Refactor: smell→pri→steps→risk→rb. Top3." → 4.5 ✗ → **REVERT to T2**. Final: 480/120, 7.2

## Testing Patterns

### Pattern 1: Golden Output Comparison
- Keep reference output from T0 (or human-approved)
- After each cut, diff against golden output
- Score = 1.0 - (edit_distance / golden_length)
- Threshold: ≥0.95 for correctness

### Pattern 2: A/B Evaluation with LLM Judge
- Feed T0 and Tn outputs to independent evaluator prompt
- "Which better fulfills original intent? Score 1-10 each."
- Run 3x, average. Eliminates single-eval variance.
- Threshold: Tn avg ≥ T0 avg - 0.5

### Pattern 3: Regression Suite
- Build 10-20 diverse inputs per prompt type
- Run full loop on each, track token trajectory + score
- Detect: "this prompt type stalls at T1" or "T3 consistently reverts"
- Use to tune per-type T-targets (e.g., reviews tolerate T3, specs need T2)

## Edge Cases

### Edge 1: Implicit Context Dependencies
Prompt works in isolation but fails when preceding context changes (e.g., "continue the above" assumptions). Fix: make context explicit in T1 or add "standalone" constraint.

### Edge 2: Format Drift
JSON structure subtly changes across cuts (extra fields, nesting shifts). Fix: add schema constraint at T1: "Output ONLY valid JSON matching: {...}"

### Edge 3: Multi-Task Prompts
Single prompt does 3 things (analyze + decide + format). Cutting breaks one. Fix: split before loop, optimize each separately, then compose.

### Edge 4: Domain Jargon Compression
T3 abbreviates terms evaluator doesn't recognize ("4R" → "Risk/Read/Reliab/Resil" fails). Fix: keep domain acronyms expanded at T2; only compress at T3 if evaluator knows them.

## Anti-Patterns
Over-optimize before measuring · Cut context before identity · Sacrifice correctness · Stop at T1 when T2 possible · Apply T3 to underspecified prompts · Score subjectively without criteria
**Over-constraint early** — Adding "code only" or "<50 tokens" at T0 starves the model of reasoning space; constrain at T2+ only.
**Skip regression test** — Optimizing one prompt without verifying 5+ variants causes silent regressions on unseen inputs.
