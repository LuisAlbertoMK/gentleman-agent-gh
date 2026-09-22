# Optional Mejoras — Docs / Skill Quality / Security (Draft)

**Branch**: `analysis/mejoras-optional-2026-08-28`
**Date**: 2026-08-28
**State**: DRAFT — read-only audit. No `main`, no pushes, no code/target-file edits.
**Scope**: Optional improvements with real, verified aporte (discoverability, onboarding, pre-commit security). Nothing requires a merge to apply; all target files remain untouched here.

---

## Evidence Gate

- `glob docs/mejoras/*.md` — 66 prior mejora docs cross-referenced (security: `2026-07-29-gentleman-agent-gh-global-analysis.md`, `2026-07-30-auto-permission-analysis.md`, `2026-07-31-gentleman-agent-gh-tests-perf.md`; docs: `2026-08-12-v3-update-docs-stale.md`, `2026-07-31-skill-ecosystem-audit.md`).
- `ctx_search queries=["docs:drift","skill:quality","security:hardening"]` — prior work re: README drift (script/score counts), permission deny-list drift, gitleaks rules, pre-commit `-CaseSensitive` secrets bypass.
- Confirmed prior findings are RESOLVED where relevant: the old `-CaseSensitive` secrets-scan bypass (`2026-07-29...:264`) is fixed — `scripts/leak-guard.ps1` now uses case-insensitive `-match` (verified, leak-guard.ps1:37-47).

**New findings below are NOT duplicates of prior mejora docs** — none touch `.pre-commit-config.yaml` YAML validity, SKILLS-INDEX completeness-vs-count gap, or AGENTS.md skill-count staleness.

---

## Verified Facts

| # | Fact | Evidence | Confidence |
|---|------|----------|-----------|
| F1 | `.pre-commit-config.yaml:65` has `timeout: 120` indented at 10 spaces (deeper than 8-space sibling keys) under `pass_filenames: false` → the YAML document fails to parse | PyYAML `yaml.safe_load` throws `ScannerError: mapping values are not allowed here, line 65, column 18` | high (tool-verified) |
| F2 | Project skill dirs on disk = **92** (`Get-ChildItem .agents\skills -Directory`, excl. `_shared`) | terminal: "Actual project skill dirs: 92" | high |
| F3 | **41** of those 92 dirs are NOT mentioned anywhere in `SKILLS-INDEX.md` | regex diff of index vs dirs → 41 names missing | high |
| F4 | `SKILLS-INDEX.md:3-4` claims "read this file for complete list" / "Full table: all 92 skills" | Read SKILLS-INDEX.md L3-4 | high |
| F5 | `scripts/cross-ref-check.ps1:127-140` (`[3/9] INDEX count`) validates only the **declared count** against disk ("all 92 skills" 92=92 → PASS), NOT per-skill listing | Read cross-ref-check.ps1 L127-140 | high |
| F6 | `AGENTS.md:17` and `AGENTS.md:79` both claim "78 skills" | grep AGENTS.md → L17, L79 | high |

---

## Optional Improvements (Ranked by ROI)

### OPT-1 (PRIORITY #1) — Fix broken YAML in `.pre-commit-config.yaml:65` (security)
- **What**: `pester-gate` block ends with a stray, over-indented `timeout: 120` (line 65). This makes the entire `.pre-commit-config.yaml` **unparseable** → every YAML consumer (pre-commit loader, the `check-yaml` hook at L8-13, `yamllint`) rejects the file → **the whole pre-commit gate cannot run**, silently disabling gitleaks, secrets-scan, pssa-gate, cross-ref-check.
- **Validation of impact**: `yaml.safe_load` fails at line 65 col 18 (F1). Any consumer of this file gets a hard error, not a warning.
- **Fix (1 line)**: delete line 65. NOTE: pre-commit has no `timeout` hook key (valid keys: id/name/entry/language/files/types/pass_filenames/args/stages/additional_dependencies/…); if a per-hook wall-clock guard is desired, implement it inside `scripts/tests` runner or `pester-gate.ps1`, not in this file.
- **Impact**: restores the pre-commit security gate (HIGH).
- **Cost**: minutes. **Risk**: very low (removes 1 invalid line). **Blast radius**: Bajo.
- **Verification**: `python -c "import yaml; yaml.safe_load(open('.pre-commit-config.yaml'))"` → no exception after fix; `pre-commit run --all-files` green.
- **Note**: technically a bug, classified here as the highest-ROI optional *security* aporte (task allows "seguridad pre-commit").
- **conf file:line**: `.pre-commit-config.yaml:65`. **confidence: high**.

### OPT-2 (PRIORITY #2) — Close SKILLS-INDEX completeness gap with fail-closed index check (discoverability/docs)
- **What**: `SKILLS-INDEX.md` (top-20 + quick groups) omits 41 of 92 project skills (F3) while L3-4 claim it's a complete list (F4). The gate that should catch this (`cross-ref-check.ps1 [3/9]`) only compares the *declared count* (F5) — so 92=92 passes while 41 skills are undiscoverable via the index.
- **Aporte**: converting `[3/9]` to also flag any on-disk skill dir absent from the index makes the drift **fail-closed** and keeps future `skill` additions discoverable. Optionally regenerate a genuine complete appendix table.
- **Impact**: onboarding/routing discoverability (MEDIUM). **Cost**: small (extend one PS check + optionally fill table). **Risk**: low; guard may expose current gap (intended) — apply fix + table together.
- **Verification**: run `scripts/cross-ref-check.ps1` before (clean on count) and after adding listing check; do a trial run of `skill` tool on a previously-missing skill (e.g. `gap-analysis`) to confirm resolvable.
- **file:line evidence**: `SKILLS-INDEX.md:3-4`, `scripts/cross-ref-check.ps1:127-140`. **confidence: high**.

### OPT-3 (PRIORITY #3) — Sync AGENTS.md skill count 78 → 92 (docs drift)
- **What**: AGENTS.md Quick Navigation (`:17` "78 skills trigger table") and Skills section (`:79` "78 skills via SKILLS-INDEX.md") are stale by 14. README.md:18 already says "92 skills" correctly.
- **Aporte**: prevents an agent/onboarding reader under-estimating the skill inventory by 14 (incl. `sdd-*`, `chained-pr`, `judgment-day`, `gap-analysis`).
- **Impact**: LOW-MEDIUM (correctness of nav doc). **Cost**: minutes (2 text edits). **Risk**: none. **Blast radius**: Bajo.
- **Verification**: grep AGENTS.md for "78" → 0 hits; `cross-ref-check.ps1` still clean.
- **file:line evidence**: `AGENTS.md:17`, `AGENTS.md:79`, actual 92 (F2). **confidence: high**.

### OPT-4 (Optional, LOW) — Add a repeatable "optional-mejoras" draft naming convention
- **What**: today already produced `2026-08-28-optional-mejoras-perf-draft.md` (perf) and this doc (docs/skill/security). A tiny convention (suffixed `-draft-<domain>.md`) keeps parallel optional audits mergeable without collision.
- **Aporte**: DEVOPS/consistency only; no functional change. **confidence: medium** (inference — no governance doc mandates this yet, flagged as novel suggestion, low value on its own).

---

## Prioritized Recommendation (top 2-3 by ROI)

1. **OPT-1** — fix `.pre-commit-config.yaml:65` (restores broken pre-commit security gate). Highest safety value, trivial cost/risk.
2. **OPT-2** — fail-closed SKILLS-INDEX listing check + complete appendix (largest discoverability/onboarding aporte, bounded cost).
3. **OPT-3** — AGENTS.md count 78→92 (cheap correctness win).

OPT-4 is optional polish; include only if the team wants the naming convention formalized.

---

## Files Changed (this task)
- **Created**: `docs/mejoras/2026-08-28-optional-mejoras-docs-skill-security-draft.md` (this file, on `analysis/mejoras-optional-2026-08-28`).

No target files (`.pre-commit-config.yaml`, `SKILLS-INDEX.md`, `AGENTS.md`, `cross-ref-check.ps1`) were modified — task is read-only.
