# Changelog: Intake & Verification System v2.1

**Date**: 2026-06-13
**Type**: System Improvement
**Scope**: gap-analysis, project-mapper, AGENTS.md, SKILLS-INDEX.md, new scripts/templates

---

## Changes Made

| File | Action | Detail |
|------|--------|--------|
| `scripts/intake-verify.ps1` | **NEW** | Full intake verification with 7 checks + -Iterations 3 + metrics saving |
| `skills/gap-analysis/assets/fe-template.md` | **NEW** | Frontend-specific template (UI/UX 35%, Responsive 20%, Perf 20%) |
| `skills/gap-analysis/assets/be-template.md` | **NEW** | Backend-specific template (Security 30%, Perf 25%, Opt 20%) |
| `skills/gap-analysis/assets/db-template.md` | **NEW** | Database-specific template (Perf 30%, Security 25%, Resource 20%) |
| `skills/gap-analysis/SKILL.md` | **UPDATED** | v2.0 → v2.1: 3-iteration cycle, intake-verify.ps1 integration, PR desambiguation, 10 templates total |
| `skills/project-mapper/SKILL.md` | **UPDATED** | v1.3 → v1.4: auto-chain gap-analysis now MANDATORY (not optional) |
| `AGENTS.md` | **UPDATED** | Pre-Flight Gate step 3: MANDATORY INTAKE CHAIN (project-mapper → intake-verify.ps1 → gap-analysis) |
| `SKILLS-INDEX.md` | **UPDATED** | v1.4 → v1.5: Load rule with fallback for skills not in available_skills; new version refs |

---

## Metrics: Before vs After

### Artifact Coverage (self-test on gentleman-agent-gh)

| Artifact | Before | After | Delta |
|----------|--------|-------|-------|
| Roadmap | ⚠️ manual lookup | ✅ automated 3-location check | +automation |
| PR | ⚠️ git log only | ✅ git log + gh pr list + PROBLEM-REPORT | +desambiguation |
| PRD | ⚠️ manual lookup | ✅ automated recursive search, 5 file types | +coverage |
| README | ⚠️ existence only | ✅ quality scoring (8 criteria, 0-10) | +depth |
| Tests | ⚠️ manual lookup | ✅ dir + files + config detection | +reliability |
| CI/CD | ⚠️ manual lookup | ✅ 6 providers auto-detected | +breadth |
| Monitoring | ⚠️ manual lookup | ✅ 12 APM patterns auto-detected | +coverage |
| 3-Iteration Cycle | ❌ not existent | ✅ full cycle: detect → fix → verify → confirm | +process |
| Metrics Persistence | ❌ not existent | ✅ docs/metricas/ with JSON + MD reports | +history |
| Project Classification | ❌ manual only | ✅ auto-detect tech layer by package.json/go.mod/signals | +automation |

### Score Comparison

| Dimension | Before | After | Improvement |
|-----------|--------|-------|-------------|
| Gap detection speed | ⚠️ minutes (manual) | ✅ seconds (automated) | ~10x faster |
| Verification iterations | 1 (manual) | 3 (automated) | 3x more thorough |
| Project types covered | 7 (business) | 10 (7 business + 3 tech layer) | +43% coverage |
| Quality dimensions | 8 defined | 8 defined + weighted per type | +context |
| Artifacts checked | 5-6 (manual) | 7 (automated, comprehensive) | +2-3 depth |
| Re-verification | ❌ none | ✅ delta tracking per iteration | new capability |

### Skill Health

| Metric | Before | After | Status |
|--------|--------|-------|--------|
| Skill test suite | 47/47 PASS | 47/47 PASS | ✅ maintained |
| Cross-ref errors | 0 | 0 | ✅ maintained |
| Cross-ref warnings | 2 (pre-existing) | 2 (pre-existing) | ✅ no regression |

---

## Files Changed
- 4 modified (AGENTS.md, SKILLS-INDEX.md, gap-analysis/SKILL.md, project-mapper/SKILL.md)
- 4 new (intake-verify.ps1, fe-template.md, be-template.md, db-template.md)
- 1 new metrics dir (docs/metricas/)

## Next Steps
1. Use intake-verify.ps1 as entry point for ALL new project scans
2. Monitor docs/metricas/ trend data after 5+ project intakes
3. Consider adding gaming/IoT/ML project type templates if needed
4. The 3-iteration cycle will auto-detect recurring gaps for ANTI-PATTERN-CATALOG
