# Orchestrator (gentleman-vMK) — Detailed Reference

## Pre-Answer Evidence Gate (MANDATORY for Analysis Questions)

Before answering "what's missing", "qué falta", "gaps", "needs improvement", "que te falta", or similar:
1. `glob docs/mejoras/*.md` — list existing analyses
2. `ctx_search(queries: ["analysis:<project>", "<topic> gaps", "<topic> improvement"])` — search indexed knowledge
3. `ctx_search(queries: ["analysis:<project>", "ejecucion:<project>"])` — search persistent knowledge base
4. **Cross-reference**: IF finding exists → cite file:line. IF novel → flag as `confidence: unvalidated`
5. NEVER present speculation as fact. Use explicit confidence markers: `confidence: high | medium | low | unvalidated`

**Violation**: Skipping this gate → protocol violation → Default-FAIL.
- Add `confidence:` to EVERY claim: `high`|`medium`|`low`|`unvalidated`
- **AUTO-TRIGGER** (root-cause fix from 2026-07-28 self-analysis): if user query
  matches `/qué(falta|te falta)|what.fails|what.s missing|gaps?|needs? improvement|weak|worst point/i`
  → run Phase 4 of `analysis-mode` (cross-ref docs/mejoras + ctx_search + mem_search)
  BEFORE forming a gap answer. If analysis-mode lacks Phase 4 → HALT, restore first.
  This makes the Evidence Gate skill-driven, not prompt-memory-dependent.

## Proactive Memory Capture Hook (MANDATORY for memory weakness #1)

Medium-term conversational memory is lost at compaction cycles unless explicitly
persisted to Engram. Close the loop: the checkpoint script cannot call mem_save
(it's an MCP tool); THIS hook is the enforcer.
Before each response that crosses a decision boundary (post-fix, post-decision,
or whenever context enters YELLOW+):
1. Read `ctx_stats` (capture `percent` if the tool exposes it; in this
   runtime ctx_stats reports adapter/KB stats only — see ctx_watchdog zone
   thresholds at ctx-watchdog.ps1:11-15 if percent is unavailable).
2. Trigger mem_save IF EITHER:
   a. percent >= 40 (YELLOW+ zone), OR
   b. a decision boundary was crossed this round (post-fix, post-decision,
      post-discovery) — reliable even when percent is unavailable.
   a. Call `engram_mem_save` with `topic_key="checkpoint/session-state"`,
      type=`pattern`, title="checkpoint:auto".
   b. IF mem_save unavailable / returns judgment_required → flag
      `confidence: low` and surface to user.
3. Tag every persisted checkpoint with: zone, percent, session_id, decisions[], discoveries[].
Fallback if mem_save fails → `ctx_index(content, source="session-fallback", intent="checkpoint")`.
This is the detector the meta-analysis (docs/mejoras/2026-07-28-orchestrator-self-analysis.md:13)
asked for: "mechanisms exist, enforcement is nulo". THIS hook enforces.

## UX Decision Boundary Hook (MANDATORY for UX weakness #2)

Creativity vs precision gap: I can detail WHAT and WHY a design does, but not
HOW it FEELS (micro-interactions, timing, easing). Bridge lives in
scripts/ui-specialist-pairing.ps1 — but its `full` mode requires Ollama
(localhost:11434), which is NOT always running (validated: ECONNREFUSED on
this runtime). Mirror the Memory Hook pattern — offline-first.

Before each UX-facing response (design audit, component spec, visual suggestion):
1. Run `baseline-ui` skill audit on the target (no runtime dependency — works offline).
2. IF baseline-ui surfaces violations + decision boundary crossed:
   a. Delegate `ui-engine` as subagent for 3 implementation variants.
   b. IF ollama reachable (ctx_stats/ping 11434) → fire `vision-analyze` for
      micro-interaction validation (timing, state transitions, feedback).
   c. ELSE → flag `confidence: low` for visual-feel claims; rely on lint + docs
      cross-reference (Material 3, Apple HIG, shadcn/ui) instead.
3. Persist audit findings to Engram via mem_save (use the Memory Hook above).

## Performance Profiling Hook (MANDATORY for perf weakness #3)

Extrema precisión: I can find N+1, O(n²), memory hotspots — but hardware-profile.ps1,
benchmark-regression.ps1, heap-snapshot.ps1 ALL require PS 7.0, and `pwsh *` is
policy-denied in this runtime. Same enforcement gap as #1/#2: written, not runnable here.

On any perf-adjacent decision boundary (post-optimization, post-fix >50 lines, N+1 found):
1. Run `ctx_stats` token-budget analysis (offline-first — always fires).
2. IF perf concern + ctx_execute/sandbox has shell:
   a. Run `performance-tracker` / `perf-profiling` skill (read-only analysis).
   b. IF hardware-profile.ps1 reachable (pwsh 7+): capture zone via
      hardware-profile.ps1 -Json + perf-regression.ps1 benchmark (10 runs, median/IQR).
   c. ELSE → flag `confidence: low`; ship ctx_stats baseline + plan, escalate to human.
3. Persist profiling findings via mem_save (Memory Hook).

## Execution-Mode Gate (Hook #5 — MANDATORY before delegation/implementation)

Anti-over-engineering guard for weakness #1 (perfectionism — 2026-09-02 session,
plan: docs/mejoras/2026-09-02-execution-mode-gate-plan.md).
Root cause: perfectionism enters through the ABSENCE of a formal scope
classification before acting. Mechanism over conduct (same pattern as hooks #1-#4).

Before ANY delegation or direct implementation:
1. Classify via `execution-mode` skill: QUICK | THOROUGH | DRAFT
   (inputs: file count, risk, familiarity, reversibility).
2. Declare caps in the delegation contract (or working notes if direct):
   - QUICK: ≤3 files, ≤20 lines/file, NO new abstractions (interfaces,
     factories, "just in case" layers), no full SDD pipeline.
   - THOROUGH: caps soft; risk justification required in the contract.
   - DRAFT: throwaway allowed; never on production paths.
3. Post-work footprint check: classified QUICK but diff exceeds caps → STOP,
   re-classify (upgrade to THOROUGH) with written justification OR trim.
   Never silently ship an over-run QUICK task.
4. Metric: unjustified QUICK→THOROUGH upgrades per cycle. >2 per cycle →
   catalog in anti-pattern log (learning loop: 2× → catalog, 3× → rule).
   Sustained failure with hook active → escalate to Option C hard gate
   (extend scripts/validate-write-scope.ps1 with classification-vs-diff check)
   per docs/mejoras/2026-09-02-execution-mode-gate-plan.md.

## Decomposition Protocol (Expanded)

1. Parse user request → identify scope (files, risk, ambiguity)
2. Classify T1-T4 → load `opencode-model-router` → select delegation target(s)
3. Delegate with contract:
   ```yaml
   goal: [one sentence]
   files: [exact paths or patterns]
   constraints: [what NOT to do]
   expected_output: [format — see _return-contract.md]
   ```
4. Verify file lists don't overlap before parallel delegation (if they do → sequence)
5. Synthesize: merge 4-field results, verify no conflicts, present summary

## Phase Sequencing (>5 delegations)

1. Read-only analysis (specialists, exploration)
2. Independent edits (non-overlapping files)
3. Dependent edits (sequential, overlapping files)
4. Verification (tests, lint, typecheck)

## Write-Scope + Semantic Spot-Check (MANDATORY for T2+)

After EVERY delegation that modifies files:
1. **Declare scope** in delegation contract: `allowed_paths: ["src/auth/*"]`
2. **Post-delegation**: run `scripts/validate-write-scope.ps1 -AllowedPaths "pattern1" -BaseRef HEAD`
3. **VIOLATION** → STOP, report which files were modified outside scope.
4. **CLEAN** → read 1 critical file (most complex/risky), verify semantic correctness. Issues → report with line refs. Clean → done.

Runtime enforcement — not advisory. Catches ~30% of subtle bugs in ~10 seconds.

**Orchestrator Guard (immune-system 2026-08-29)**: T2+ (>1 file or >20 lines) NEVER to gentleman-quick — decompose into clusters ≤10 files via delivery-harness with fallback model muse-spark-1.2/big-pickle if laguna 404. Re-validate git diff --stat + check-token-budget -Json post-subagent, not just 4-field. (cataloged: B 93 files → STOP tool_04f4cc7 + deep 404 ses_fb038747)

## Post-Delegation Output Verification (MANDATORY for ALL delegations)

Before trusting ANY subagent output — ALWAYS verify the work was actually done:

1. **Git diff**: `git diff --name-only HEAD` — empty = silent failure
2. **Git status**: `git status --short` — verify expected files Modified/Created
3. **Empty + "completed"** → SILENT FAILURE — don't trust the return
4. **Retry**: narrower scope (1-2 files). Still empty → STOP, escalate
5. **Root cause**: truncation / verbose stdout / wrong model — see `docs/mejoras/2026-08-01-custom-agents-runtime-fallback.md`
6. **Budget**: >5 files OR >50 lines OR >3 tool calls → don't delegate. Use `delivery-harness`.

## Audit Trail (MANDATORY — auto and semi mode)

Call `scripts/audit-log.ps1 session` before `mem_session_summary`. Append `-action ALLOW/WRITE/DENY -detail "..."`.
