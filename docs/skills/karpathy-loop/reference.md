# karpathy-loop — Reference Materials

> **Externalized from** .agents/skills/karpathy-loop/SKILL.md to keep the skill under the 3KB
> token budget (ADR-007). Contains worked examples, testing patterns, edge cases,
> anti-patterns, and quick-reference cards.
> **Consumable by**: $Skill sub-agent when producing output.
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

### Example 6: SQL Query Optimizer
**T0** (890/222): "You are a database expert. Analyze this slow query. Identify missing indexes, rewrite for performance, explain the execution plan, suggest schema changes." → 5.9
**T1** (560/140): "DB expert. Slow query analysis: missing indexes, rewrite, explain plan, schema fixes." → 7.1 ✓
**T2** (380/95): "Slow SQL: indexes→rewrite→explain→schema. Output: original→optimized→why." → 7.4 ✓
**T3** (260/65): "SQL opt: idx→rewrite→plan→schema. orig→opt→why." → 4.9 ✗ → **REVERT to T2**. Final: 380/95, 7.4

### Example 7: Security Audit Prompt
**T0** (1050/262): "You are a security auditor. Review this code for vulnerabilities: injection, XSS, auth bypass, crypto misuse, secrets exposure, path traversal. Rate severity CVSS." → 5.4
**T1** (680/170): "Security audit. Check: injection/XSS/auth bypass/crypto/secrets/path-traversal. CVSS rate." → 7.0 ✓
**T2** (440/110): "Sec audit: inj/XSS/auth/crypto/secret/path. file:ln→vuln→CVSS→fix." → 7.3 ✓
**T3** (300/75): "Sec: inj/XSS/auth/crypto/sec/path. ln→vuln→CVSS→fix." → 5.2 ✗ → **REVERT to T2**. Final: 440/110, 7.3

### Example 8: Documentation Generator
**T0** (780/195): "Write comprehensive documentation for this API endpoint. Include description, parameters, request/response examples, error codes, authentication, rate limits." → 5.7
**T1** (500/125): "API doc: desc, params, req/resp examples, errors, auth, rate limits. Markdown." → 7.2 ✓
**T2** (340/85): "Doc endpoint: desc→params→req/resp→errors→auth→limits. MD table." → 7.5 ✓
**T3** (220/55): "API doc: desc/params/req/resp/err/auth/limit. MD." → 4.6 ✗ → **REVERT to T2**. Final: 340/85, 7.5

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

### Pattern 4: Token-Quality Pareto Frontier
- Plot (tokens, avg_score) for each T-level across all test inputs
- Identify knee point: max score per token
- Set that T-level as default for the prompt type
- Re-evaluate quarterly or when model changes

### Pattern 5: Adversarial Stress Test
- Feed adversarial inputs: empty, huge, malformed, ambiguous, contradictory
- Verify prompt doesn't hallucinate, crash, or leak
- Score robustness dimension separately on adversarial set
- Threshold: adversarial score ≥ nominal score - 1.0

### Pattern 6: Cross-Model Portability
- Run optimized prompt on 2+ models (e.g., GPT-4, Claude, local)
- Compare score delta. If >1.5, prompt is model-specific
- Add model-agnostic constraints or create model-specific variants
- Document model sensitivity in prompt metadata

## Edge Cases

### Edge 1: Implicit Context Dependencies
Prompt works in isolation but fails when preceding context changes (e.g., "continue the above" assumptions). Fix: make context explicit in T1 or add "standalone" constraint.

### Edge 2: Format Drift
JSON structure subtly changes across cuts (extra fields, nesting shifts). Fix: add schema constraint at T1: "Output ONLY valid JSON matching: {...}"

### Edge 3: Multi-Task Prompts
Single prompt does 3 things (analyze + decide + format). Cutting breaks one. Fix: split before loop, optimize each separately, then compose.

### Edge 4: Domain Jargon Compression
T3 abbreviates terms evaluator doesn't recognize ("4R" → "Risk/Read/Reliab/Resil" fails). Fix: keep domain acronyms expanded at T2; only compress at T3 if evaluator knows them.

### Edge 5: Conditional Logic Collapse
Prompt has "if X then A else B". Compression merges branches → wrong output for one path. Fix: keep conditional structure explicit until T2; test both branches at each level.

### Edge 6: Example-Dependent Behavior
Prompt relies on few-shot examples for format. Cutting examples breaks format adherence. Fix: keep 1 minimal example at T2; only remove at T3 if format constraint is explicit.

### Edge 7: Numeric Precision Loss
Financial/scientific prompts lose decimal places or significant figures in compression. Fix: add "preserve numeric precision" constraint at T1; verify with known-value tests.

### Edge 8: Cultural/Linguistic Assumptions
Prompt assumes US date format, English idioms, Western business context. Compression amplifies bias. Fix: add locale/context constraints at T1; test with non-US inputs.

## Anti-Patterns
Over-optimize before measuring · Cut context before identity · Sacrifice correctness · Stop at T1 when T2 possible · Apply T3 to underspecified prompts · Score subjectively without criteria

**Over-constraint early** — Adding "code only" or "<50 tokens" at T0 starves the model of reasoning space; constrain at T2+ only.

**Skip regression test** — Optimizing one prompt without verifying 5+ variants causes silent regressions on unseen inputs.

**Chase tokens over quality** — Token count is a proxy, not the goal. A 40-token prompt that fails is worse than a 120-token prompt that works.

**Ignore score variance** — Single-run scores have ±1.5 noise. Always run 3x and average before deciding.

**Compress identity** — "Senior engineer" → "Expert" → "" loses authority signaling. Keep minimal identity (role) until T3.

**Blind template reuse** — Applying T3 pattern from code-review to spec-writing fails. Each prompt type has different compressibility.
