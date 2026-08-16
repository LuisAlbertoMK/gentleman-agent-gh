# UI-Engine C28 Wave 1 — Implementation Report

**Task**: UI/UX Depth Wave 1 — transform `ui-engine/SKILL.md` from theoretical to actionable
**Agent**: plan-execution · **Date**: 2026-08-15 · **Branch**: `wip/c28-ui-depth-wave1`

## Decision Taken
Added real component examples (Btn/Nav/Card) with `@supports` fallbacks (oklch/:has/CQ), a 4-point testing checklist (axe-core, CQ toggle, reduced-motion, keyboard) and an A11y section (color-scheme, focus-visible) to `ui-engine/SKILL.md`, compressing existing prose to the maximum possible without cutting any functional rule.

## Files Changed
| Path | Before | After | Delta |
|---|---|---|---|
| `.agents/skills/ui-engine/SKILL.md` | 2935B (UTF-8+BOM, CRLF) | 3931B (UTF-8, LF) | +996B |

Rollback: restore `docs/ciclos/c28-w1-backup/ui-engine/SKILL.md` (pristine copy, byte-identical to pre-change state).

## Key Findings
1. [HIGH] **Size metric NOT met** — 3931B vs ≤3KB (3072B) target, +859B over. Byte budget: frontmatter 409B (immovable, byte-exact mandated) + mandated additions (Examples 1000B + Testing 228B + A11y 197B = 1425B) + preserved rules 2087B. Fitting ≤3072B would require cutting 41% of functional rules — rejected per task priority "Quality-first: a good example or checklist > token savings" + "DON'T cut new examples". Prose compression already applied: dropped redundant `.ga` (dup of Decision Tree auto-fit), removed truncated When-to-Use line, tightened Responsive/Animation/Components prose, one-line chained fallbacks. **Scorer impact of the overshoot: zero** — SE/SD tier thresholds are o3 counts (see finding 4).
2. [HIGH] **SD target 8.5→8.7+ NOT moved** — SD 8.4 before → 8.4 after. Verified by reading `score-dims.ps1:560-715`: all 42 SD sub-dims are repo-structural (skill counts, sizes, frontmatter coverage, tool hygiene, freshness) — **none measure skill content depth**. Examples/testing cannot lift SD; only `## Refs:` addition bumps the refs-coverage sub-dim (+0.11/42 ≈ +0.003, rounds to no change). Task premise "ejemplos/testing may lift sub-dims" does not map to actual scorer sub-dims. confidence: high (verified against scorer source).
3. [MEDIUM] **SE 8.0→7.0 is a JOINT concurrent-work effect, not my regression** — o3 went 2→4 because `web-quality-audit/SKILL.md` (3135B, being edited by a parallel agent — `git status` shows `MM` staged+unstaged) also crossed 3072B. SE penalty jumps −1→−2 only at o3>3. My change alone (o3 2→3) keeps SE at 8.0 (same penalty tier). `git diff HEAD -- scripts/` is empty — no script-side cause.
4. [MEDIUM] **True baseline differs from task brief** — task stated "SD=8.5, SE 10.0" (stale `.project.json` cache). Fresh `score-auto` run: **SD=8.4, SE=8.0** (o3=2 pre-existing: baseline-ui, mini-orchestrator; +1 overweight from commands/prompts). Security 10.0 and cross-ref 9/9 confirmed as stated.
5. [LOW] **Pester failures all pre-existing** — full suite exit 1, but zero failures reference ui-engine (verified: no test file matches `ui-engine`; failing suites target unmodified scripts/README/permission-templates). The cycle-28 "22/22" reflects that era's suite size; the current suite carries pre-existing failures (babyagi-loop safety, SSoT npm policy, README drift, session-checkpoint env state, `ui-specialist-pairing` fixture bug: pattern `duration-[5[0-9][0-9]ms]` never matches fixture `transition: all 500ms ease`).

## Metrics (verify post-change)
| Metric | Target | Result |
|---|---|---|
| Size ≤3KB | ≤3072B | **3931B — NOT MET** (byte budget above; scorer impact zero) |
| ≥1 "## Examples" with real code | ✓ | 3 components: Btn/Nav/Card, real CSS |
| ≥3 testing bullets | ✓ | 4 bullets: axe-core, CQ DevTools toggle, prefers-reduced-motion, keyboard Tab |
| ≥1 `@supports` fallback | ✓ | 4: oklch (Btn `:root{--pri:#2563eb}`), `:has()` (Nav `selector()` probe), CQ→MQ (Nav), CQ→stack (Card) |
| SD 8.5→8.7+ | — | 8.4→8.4 (no content-depth sub-dims exist; see finding 2) |
| cross-ref 9/9 | ✓ | `allClean: true`, brokenCrossRefs 0, exit 0 |
| Frontmatter preserved | ✓ | 6 lines byte-identical (name/description/triggers/changelog) |
| Quality gate | — | E1 3/3 PASSED (PS Syntax, Skill Frontmatter, Cross-Ref). Pester: only pre-existing failures, none ui-engine-related |

## Nuance
- **The 3KB ceiling is mathematically incompatible with the mandate.** The task's "compress prose elsewhere" escape hatch is exhausted: the 2935B file was already maximal-density (cycle-28 compression), so freeing the ~900B needed by the additions would require deleting 41% of functional rules — the direct opposite of "Quality-first" and "DON'T cut new examples". Delivered 3931B of dense-but-complete content; if the orchestrator insists on ≤3072B, a second pass must decide WHICH rules to cut (my recommendation if forced: drop the `@media` variant of the Nav CQ fallback −33B, the Card CQ fallback −66B, and the `Tab.Group` compound example −77B).
- **Examples are token-driven, not literal** — Btn uses `var(--pri)/var(--sf)` and the oklch fallback overrides the token at `:root`, matching the skill's own PRIM→SEM→COMP rule (more idiomatic than a literal hex button). All 7 CSS snippets validated for syntax correctness.
- **`## Refs: baseline-ui·accessibility·performance`** replaces the old `## Loading:` line — it preserves the load-chain, feeds the SD refs-coverage sub-dim, and is invisible to the cross-ref parser (only `Cross-Refs:`/`Anti-Patterns:` patterns are validated; refs verified to be real skill dirs).
- **Encoding normalized**: BOM+CRLF → plain UTF-8+LF (−47B). All checks handle both (score-dims strips BOM at offset 3; verify.ps1 `ReadAllText` auto-detects).
- **Concurrent agents**: baseline-ui and web-quality-audit SKILL.md are mid-edit by parallel subagents (staged `MM`). Their final sizes decide whether the repo's o3 settles at 3 (SE 8.0) or 4 (SE 7.0) — a merge-time decision outside my ownership.
- **confidence**: high — every claim backed by tool output (byte counts, scorer source `score-dims.ps1:560-715/391-454`, cross-ref JSON, git status, Pester failure enumeration).