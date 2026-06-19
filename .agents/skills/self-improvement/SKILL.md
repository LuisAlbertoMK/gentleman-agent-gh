---
name: self-improvement
description: "Continuous improvement cycle — diagnose, fix, verify, learn, propagate. inter(30) minimum."
triggers: "Self-improvement, improvement cycle, auto-mejora, ciclo de mejora, comienza ciclo"
license: Apache-2.0
metadata:
  tags: [system, improvement, cicd]
  author: gentleman-vMK
  version: "1.1"
  changelog: "1.1: karpathy compress"
  dependencies: [triple-verify, quality-gate, bitacora, engram-protocol, commit-crafter]
---
## Trigger: "comienza ciclo de auto-mejora y aprendizaje"
## First Step: READ CYCLE.md
## Phases
### 0: Pre-Flight
LOAD CYCLE.md · READ Engram #645 (external repos) · CHECK autoresearch/GGA/gentle-ai/engram · RUN `check-skill-drift.ps1` · CAPTURE baseline: `score-auto.ps1`
### 1: Diagnose
Read `.project.json`+`PROJECT-SCORE.md` → lowest dimension → fix candidates by impact/ease.
### 2: Execute (per fix)
Backup git snapshot → Apply change → Determine difficulty (CYCLE.md table) → triple-verify per level → Cache result → Log: `inter-track.ps1 -Increment` + bitácora
### 3: Verify Cycle
Re-score → compare delta → inter≥30? → score improved? keep; else revert.
Score: `score-auto.ps1 -Json | Set-Content .project.json -Encoding UTF8`
### 4: Learn
Engram (`self-improvement/cycle-results`) · anti-patterns if introduced · CYCLE.md notes
### 5: Propagate
opencode→opencode-vmk→gentleman-vMK · Update junctions via `check-skill-drift.ps1`
## Difficulty→Verify table: See CYCLE.md. Summary: Fácil=E2 · Medio=E1+E2 · Medio-Dif=E1+E2+E3 · Difícil=Full+4R · Complejo=Full+judgment-day · Muy Compl=Full+SDD
## Exit: inter≥30 + no dim<9.0 → SUCCESS · Time budget exhausted → STOP · Same fix fails 3x → SKIP · Score drop >0.5 → revert
## Refs: CYCLE.md · inter-track.ps1 · extract-skill.ps1 · run-improvement-cycle.ps1 · score-auto.ps1 · Engram #645
