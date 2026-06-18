---
name: self-improvement
description: "Continuous improvement cycle — diagnose, fix, verify, learn, propagate. inter(30) minimum."
triggers: "Self-improvement, improvement cycle, auto-mejora, ciclo de mejora, comienza ciclo"
license: Apache-2.0
metadata:
  tags: [system, improvement, cicd]
  author: gentleman-vMK
  version: "1.0"
  dependencies: [triple-verify, quality-gate, bitacora, engram-protocol, commit-crafter]
---

## When
User says "comienza ciclo de auto-mejora y aprendizaje" or any self-improvement trigger.

## First Step
READ CYCLE.md — defines objective, metrics, and loop behavior.

## Phases

### 0: Pre-Flight
LOAD CYCLE.md · READ Engram #645 (external repos) · CHECK repos for new features: autoresearch (patterns), GGA (caching/AGENTS.md checks), gentle-ai (MCP), engram (cloud/query) · RUN `check-skill-drift.ps1` · CAPTURE baseline: `score-auto.ps1` + `run-improvement-cycle.ps1 -Quiet`

### 1: Diagnose
Read `.project.json` + `PROJECT-SCORE.md` → identify lowest dimension or gap → generate fix candidates by impact/ease.

### 2: Execute (per fix)
1. **Backup** git snapshot if modifying existing file
2. **Apply** change
3. **Determine difficulty** from CYCLE.md → triple-verify:
   - Fácil=E2 · Medio=E1+E2 · Medio-Dif=E1+E2+E3 · Difícil=Full+4R · Complejo=Full+judgment-day · Muy Compl=Full+SDD
4. **Verify** per level + **Cache** result (skip if unchanged)
5. **Log**: `inter-track.ps1 -Increment` + bitácora entry

### 3: Verify Cycle
Re-score → compare delta → inter≥30? → score improved? keep; else revert.
**Score auto-update**: Run `score-auto.ps1 -Json | Set-Content .project.json -Encoding UTF8` to persist. Update PROJECT-SCORE.md with changelog entry.

### 4: Learn
Engram (`self-improvement/cycle-results`) · anti-patterns if introduced · CYCLE.md notes · auto-metrics 6-dim.

### 5: Propagate
opencode → opencode-vmk → gentleman-vMK · Update junctions via `check-skill-drift.ps1`.

## Difficulty → Verify
See CYCLE.md table. Copied here for quick ref:

| Level | Verify | Budget |
|-------|--------|--------|
| Fácil | E2 only | 2 min |
| Medio | E1+E2 | 5 min |
| Medio-Dif | E1+E2+E3 | 10 min |
| Difícil | Full+4R | 15 min |
| Complejo | Full+judgment-day | 30 min |
| Muy Complejo | Full+SDD | 60 min |

## Exit Conditions
- inter≥30 + no dim <9.0 → SUCCESS
- Time budget exhausted → STOP
- Same fix fails 3x → SKIP
- Score drop >0.5 → full revert

## References
CYCLE.md · inter-track.ps1 · extract-skill.ps1 · run-improvement-cycle.ps1 · score-auto.ps1 · Engram #645
