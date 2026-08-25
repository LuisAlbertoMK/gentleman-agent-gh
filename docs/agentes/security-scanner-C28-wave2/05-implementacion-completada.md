# Security-Scanner C28 Wave 2 — Implementation Report

**Task**: Wave 2 (retry) — transform `security-scanner/SKILL.md` from diagnostic guidance to actionable (real security scanning examples, testing patterns, edge cases). Quality-first: examples > token budget.
**Agent**: plan-execution · **Date**: 2026-08-16 · **Branch**: `wip/c28-wave2-perf-api-security`

## Decision Taken
Completed Wave-2 transform of `security-scanner/SKILL.md`: 4 real scanning examples (trufflehog secrets, SQLi/XSS injection, dependabot/npm-audit CI, cosign supply chain), 2 testing patterns (FP reduction, zero-secret gate), 4 edge cases (FP secrets, encrypted vars, CI secrets vs leaks, timing) — restoring the Sensitive-APIs/API-Security/Go-SQLi greps the prior attempt had dropped, at 3066B (under the 3072B o3 threshold).

## Files Changed
| Path | Before | After | Delta |
|---|---|---|---|
| `.agents/skills/security-scanner/SKILL.md` | 2713B (UTF-8+BOM, LF, backup baseline) | 3066B (UTF-8+BOM, LF, trailing NL) | +353B |

Rollback: restore `docs/ciclos/c28-w2-backup/security-scanner/SKILL.md` (pristine byte-identical copy).

## Key Findings
1. [HIGH] **Prior attempt (working tree) had already added all mandated sections but DROPPED functional greps** — `git diff` showed the in-progress edit removed the Sensitive APIs (`eval(/exec(/shelljs/child_process/os/exec/subprocess.`), API Security (`rate.limit/RateLimiter`, `zod/joi/pydantic` input validation) and Go SQLi (`sql.Exec/.Raw(`) quick-patterns while compressing QUICK PATTERNS into one line. SCAN DIMENSIONS still listed "Sensitive APIs" and "API security" with no tooling to detect them — a silent coverage regression. Restored all three grep families compactly in the single QUICK PATTERNS line.
2. [MEDIUM] **3066B stays under the 3072B o3 threshold — no SE regression.** Current o3=3 (mini-orchestrator 3109B, perf-profiling 3881B, ui-engine 3931B — all pre-existing/concurrent, none mine). Crossing would have pushed o3→4 (SE −2 vs −1 at `score-dims.ps1:427-434`). Byte budget was tight (initial draft 3191B, −125B via prose trims: When-to-Use line, example labels, second `--include` on the validation grep) without cutting any mandated item or functional rule.
3. [MEDIUM] **SD 8.4→8.4 and Security 10→10 unchanged, as predicted.** SD sub-dims are repo-structural (skill counts, frontmatter coverage, refs coverage, freshness — `score-dims.ps1:697-699`); none measure content depth. `## Refs` line preserved byte-identical → refs-coverage contribution unchanged. Security: `weak_crypto`/`secrets` evidence untouched → 10.0. Overall printed 9.1 before and after (verified by backup-swap score-auto run: identical dims).
4. [MEDIUM] **All mandated depth targets delivered**: secrets regex + `trufflehog filesystem . --only-verified`; SQLi regex (`SELECT .*\+|WHERE .*\$|execute\(.*\+` → parameterize) + XSS (`innerHTML\s*=|dangerouslySetInnerHTML` → escape output); dep-vuln CI (`.github/dependabot.yml` + `npm audit --audit-level=high || exit 1`); supply-chain integrity (`cosign verify-blob --signature img.sig --cert img.pem artifact.tar.gz` + `sha256sum -c checksums.txt`); testing (fixture FP-reduction, `trufflehog --fail` + inverted grep zero-secret CI gate); 4 edge cases incl. `.env.enc/age/sops` ciphertext-only scanning and `${{ secrets.X }}` legit-ref vs committed-raw-value.
5. [LOW] **Gates verified clean**: E1 gate 3/3 (PS Syntax PASS, Skill Frontmatter PASS — all frontmatter valid, Cross-Ref exit 0); cross-ref-check 9/9 `allClean: true` (89 skills, brokenCrossRefs 0, errors 0); check-adversarial exit 0 (no profile-matched files staged — SKILL.md-only change, 22/22 gate unaffected as documented in perf-profiling's report); skill-drift: security-scanner NOT in drift list (3 pre-existing drifts: cancel-ralph/help/ralph-loop, non-blocking); frontmatter lines 1-6 byte-identical to backup; description 114 chars ≤120B (C4); no Pester test references security-scanner (grep Tests/ = 0 hits).
6. [LOW] **verify.ps1 pre-existing failures documented, not caused by this change**: PSSA gate 1 pre-existing `&&` violation (baseline deuda 93, no regression); Secrets Scan flags `gaps-log.md` + `patterns-guide.md` (tracked docs, matched `password\s*=`/`secret\s*=`/`api[_-]?key\s*=` — my SKILL.md has 0 secret-pattern matches); Git Hygiene = expected uncommitted state of concurrent Wave-2 work.

## Metrics (verify post-change)
| Metric | Target | Result |
|---|---|---|
| Real examples | ≥4 | ✓ 4: secrets+trufflehog, SQLi/XSS, dependabot/npm audit CI, cosign/sha256 supply chain |
| Testing patterns | ≥2 | ✓ 2: FP reduction, zero-secret CI gate |
| Edge cases | ≥4 | ✓ 4: FP secrets, encrypted vars, CI-vs-leaks, pre-commit-vs-CI timing |
| Restored baseline greps | no regression | ✓ Sensitive APIs + API Security + Go SQLi restored |
| Size ≤3072B | ✓ | 3066B (UNDER — o3 stays 3, SE unchanged) |
| cross-ref 9/9 | ✓ | `allClean: true`, brokenCrossRefs 0, exit 0 |
| Gate 22/22 | — | check-adversarial exit 0 (SKILL.md-only change unaffected); E1 3/3 PASSED |
| Frontmatter preserved | ✓ | 6 lines byte-identical (name/description/triggers/changelog) |
| SE delta | report | 8.0→8.0 (o3 unchanged at 3; prior-attempt drop of greps fixed) |
| SD delta | report | 8.4→8.4 (structural only) |
| Security delta | report | 10→10 (untouched) |
| Score before/after | report | 9.1 → 9.1 (backup-swap score-auto before, final after — identical) |

## Nuance
- **The retry's real defect was the prior attempt's grep-drop, not missing sections.** All mandated EXAMPLES/TESTING/EDGE CASES were already in the working tree; what needed fixing was the silent loss of 3 grep families during the earlier compression. This is exactly the perf-profiling standard: "all baseline functional rules preserved, only annotations/tightened" — verified restored: `eval(`/`child_process`/`os/exec`/`subprocess.` (Sensitive APIs), `rate.limit`/`RateLimiter`/`zod`/`joi`/`pydantic` (API Security), `sql\.Exec` (Go SQLi).
- **Byte math was the constraint**: 3191B draft → 3066B final by trimming only prose (When-to-Use: "scan secrets, injection, vuln deps, supply chain." dropped — SCAN DIMENSIONS line already enumerates them; "grep candidates → trufflehog verifies" → "grep → trufflehog"; second `--include="*.{ts,js,py}"` removed from validation grep since first already scopes TS/JS/Py). Every mandated example keeps its full runnable command.
- **Examples are real, runnable patterns, not prose**: each is an executable command with the tool chain (grep candidate → trufflehog verify; regex → parameterize/escape fix; CI gate → exit 1; cosign verify-blob → sha256sum check). The zero-secret gate shows the `--fail` + inverted-grep belt-and-suspenders pattern.
- **BOM/encoding**: file remains UTF-8+BOM+LF with trailing newline restored (backup had trailing NL, prior attempt's Write dropped it — restored to match baseline byte shape).
- **Concurrent agents**: `api-testing/SKILL.md` and `perf-profiling/SKILL.md` remain modified by parallel Wave-2 agents (perf-profiling 3881B already >3072B). If api-testing's final edit also crosses 3072, o3→4 and SE −2 applies at merge time — outside my ownership; my file's 3066B adds no pressure (a +7B change would cross).
- **confidence**: high — every claim backed by tool output (byte counts via ReadAllBytes, `score-dims.ps1:404/427-434` math, backup-swap score-auto 9.1→9.1, cross-ref JSON `allClean`, E1 PASS lines, check-adversarial exit 0, git diff/stat, secret-pattern grep = 0).
