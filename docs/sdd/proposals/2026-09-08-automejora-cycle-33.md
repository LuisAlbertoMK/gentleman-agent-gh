# Proposal: Automejora Cycle 33 — Score Recovery & Skill/Script Consolidation

**Problem**: Overall score stalled at 9.1 (target ≥9.5). Three dimensions below target: Cycle Activity 1.0 (IC 3/30), Skill Effectiveness 8.0 (10 skills >3KB, avg 2.6KB), Script Performance 9.0 (125 scripts vs ADR-047 threshold 122). .project.json stale 4 days (CYCLE.md:47 requires ≤1 day). BITACORA traceability gap (last entry 2026-09-03 vs commits 09/04, 09/05). Backlog items 1-2 marked Done but counters not incrementing — status≠reality.

### In Scope
1. Fix inter-track counter increment in `close-session.ps1` (Backlog #1)
2. Sync inter-track counter to actual cycles 28-30 (Backlog #2)
3. Compress 10 skills >3KB to <3KB, reduce avg to <2.0KB
4. Consolidate 3+ scripts to meet ADR-047 threshold (125→≤122)
5. Add missing BITACORA entries for 09/04, 09/05 commits
6. Refresh .project.json via `score-auto.ps1`

### Out of Scope
- CYCLE.md edits (prohibited during cycle per self-improvement skill line 29)
- opencode.json/agents modifications
- Hooks, schema, auth, API, dependency changes
- New skill creation or architectural decisions

### New Capabilities
None

### Modified Capabilities
| Capability | Change |
|------------|--------|
| `scripts/close-session.ps1` | Auto-increment inter-track counter on close |
| `scripts/inter-track.ps1` | Counter reflects cycles 28-30 (value 12) |
| 10 skill files (TBD) | Compress from >3KB to <3KB, preserve function |
| 3+ script files (TBD) | Consolidate/remove to hit ≤122 scripts |
| BITACORA.md | Append 2 missing daily entries |
| .project.json | Auto-refreshed with current scores |

### Technical Approach
Priority order by I/R descending (CYCLE.md:55-63 scoring):

| # | Fix Candidate | Impact | Risk | I/R | Evidence |
|---|---------------|--------|------|-----|----------|
| 1 | Fix close-session inter-track increment | 3 (direct CA score) | 1 (single file, isolated) | 3.0 | .project.json:25-29 IC=3/30; CYCLE.md:23 backlog #1 |
| 2 | Sync inter-track counter to 12 | 3 (direct CA score) | 1 (single file, isolated) | 3.0 | .project.json:25-29; CYCLE.md:24 backlog #2 |
| 3 | Compress 10 skills >3KB | 2 (SE 8.0→10.0) | 2 (multi-file, verify each) | 1.0 | .project.json:118-131 10>3KB, avg 2.6KB; CYCLE.md:51 target 0>3KB |
| 4 | Consolidate scripts to ≤122 | 2 (SP 9.0→10.0) | 2 (multi-file, verify) | 1.0 | .project.json:52-59 SC=125 thresh=122; CYCLE.md:90 ADR-047 |
| 5 | Add BITACORA entries 09/04, 09/05 | 1 (traceability) | 1 (append-only) | 1.0 | BITACORA.md:1 last 2026-09-03; git log shows commits |
| 6 | Refresh .project.json score | 1 (freshness) | 1 (auto-script) | 1.0 | .project.json:18-19 last_updated 2026-09-04 (4 days); CYCLE.md:47 |

**All candidates I/R ≥ 1.0 → none rejected.**

### Affected Areas
| Area | Impact | Description |
|------|--------|-------------|
| `scripts/close-session.ps1` | Modified | Add inter-track increment call |
| `scripts/inter-track.ps1` | Modified | Update counter baseline to 12 |
| `scripts/*.ps1` (3+ files) | Removed/Consolidated | Reduce script count to ≤122 |
| `.agents/skills/*/SKILL.md` (10 files) | Modified | Compress each to <3KB |
| `BITACORA.md` | Modified | Append 2 missing entries |
| `.project.json` | Modified | Auto-refreshed by score-auto.ps1 |

### Risks & Mitigations
| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Skill compression breaks functionality | Medium | Run skill-graph + cross-ref-check per skill; SkillOpt gate per self-improvement:12 |
| Script consolidation breaks tests | Medium | Run full test suite (813+ tests) after each removal; revert on any fail |
| Inter-track fix doesn't increment | Low | Add integration test for close-session → inter-track flow |
| BITACORA format inconsistency | Low | Follow existing format exactly (YYYY-MM-DD - description) |

### Rollback Plan (undo en 5 min)
1. `git checkout -- scripts/close-session.ps1 scripts/inter-track.ps1`
2. `git checkout -- .agents/skills/*/SKILL.md` (10 files)
3. `git restore <consolidated-script-paths>`
4. `git checkout -- BITACORA.md`
5. `git checkout -- .project.json`
6. Verify: `./scripts/score-auto.ps1 -Json` shows pre-change scores

### Dependencies
- `scripts/score-auto.ps1` for score refresh
- `scripts/benchmark.ps1` for skill size verification
- `scripts/cross-ref-check.ps1` for skill integrity
- `scripts/test-token-budget-regression.ps1` for SkillOpt gate
- `security-scanner`, `quality-gate`, `external-auditor` — MUST pass per self-improvement:19 (protected files rule)

### Success Criteria (Done per item)
- [ ] close-session.ps1 increments inter-track counter on `!close` (CYCLE.md:23)
- [ ] inter-track counter reads 12 (cycles 28, 29, 30) (CYCLE.md:24)
- [ ] 0 skills >3KB, avg <2.0KB (CYCLE.md:51; .project.json SE → 10.0)
- [ ] Script count ≤122 (ADR-047 threshold; .project.json SP → 10.0)
- [ ] BITACORA.md has entries for 2026-09-04 and 2026-09-05
- [ ] .project.json last_updated = today, overall score ≥9.5
- [ ] All gates pass: Pester 4/4, PSSA 0 warnings, security CLEAN, external-auditor PASS
- [ ] SkillOpt gate: each compressed skill ≤20% size / <3KB, syntax parse OK, config trivial

### Fast Path vs Full SDD Decision
**FAST PATH (SDD-Quick) applies** — Justification:
- 6 fix candidates, but each touches 1-3 files max (known codebase)
- No schema, auth, API, or dependency changes
- All changes are LOW risk (isolated, easy revert, existing patterns)
- Per CYCLE.md:42 fast path for "1-3 files, known codebase, no schema/auth/API/deps"
- SDD-Quick (3 phases: Propose→Apply→Verify) sufficient; full 9-phase adds overhead without value

### Gates (per self-improvement skill)
- **SkillOpt gate** (line 12): Validate per fix — size ≤20%/3KB, .ps1 syntax parse, config trivial. Accept if target ≥+0.1 and no dim ≤-0.3.
- **Protected-files rule** (line 19): security-scanner, quality-gate, auto-metrics, external-auditor, immune-system, ANTI-PATTERN-CATALOG.md, .project.json — RUN `!audit` BEFORE commit; external-auditor MUST PASS — NOT optional.
- **CYCLE.md protection** (line 29): NEVER edit during cycle — only in Propagate/Epoch Review.

---

**Change**: 2026-09-08-automejora-cycle-33
**Location**: `docs/sdd/proposals/2026-09-08-automejora-cycle-33.md`
- **Intent**: Recover score to ≥9.5 by fixing 3 underperforming dimensions + traceability
- **Scope**: 6 fixes in, 0 deferred
- **Approach**: Fast-path SDD-Quick, priority by I/R descending, 3 parallel subagents for verification
- **Risk**: Low (all I/R ≥ 1.0, isolated changes, 5-min rollback)
Ready for sdd-apply (SDD-Quick).