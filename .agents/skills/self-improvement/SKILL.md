---
name: self-improvement
description: "Continuous improvement cycle — diagnose, fix, verify, learn, propagate. inter(30) minimum. SkillOpt-style gated validation."
triggers: "Self-improvement, improvement cycle, auto-mejora, ciclo de mejora, comienza ciclo"
license: Apache-2.0
metadata:
  tags: [system, improvement, cicd, skillopt]
  author: gentleman-vMK
  version: "1.31"
  changelog: "1.31: Compressed 5.8→<3KB"
  dependencies: [triple-verify, quality-gate, bitacora, engram-protocol, commit-crafter]
---
## Trigger: "comienza ciclo de auto-mejora y aprendizaje"
## First Step: READ CYCLE.md
## Phases
### 0-1: Pre-Flight + Diagnose
LOAD CYCLE.md + engram · RUN check-skill-drift.ps1 · `score-auto.ps1 -Json > .project.json` · LOAD `.learnings/rejected-edits.json`+`accepted-edits.json` · Read `.project.json` → lowest dim → fix candidates.
### 2: SkillOpt Gate (per fix)
**a. Snapshot** · **b. Propose**: ≤10 lines OR ≤20%. **c. Validate**: SKILL.md: lines delta ≤20%; .ps1: syntax parse; config: trivial. **d. Apply** + triple-verify. **e. Score delta**: accept if target ≥+0.1 AND no dim ≤-0.3, OR net ≥+0.1 with no Sec/Or ≤-0.3. **f. REJECT** → append to rejected-edits.json, bitácora "[REJECTED]". **g. ACCEPT** → append to accepted-edits.json. **h. Max 3 rejections → SKIP**.
### 3-5: Verify + Learn + Propagate
Re-score full. `score-auto.ps1 -Json > .project.json`. Engram(cycle-results). Same rejection 3x → ANTI-PATTERN. `check-skill-drift.ps1` for junction sync.
### 6: Epoch Review (every 4 accepts)
LR compliance check + prune buffers >30d + pattern≥3 → consolidate.
## Validation Table
| Target | Pre | Post | Accept |
|--------|-----|------|--------|
| SKILL.md | Lines ≤20% | Size <3KB | Target ≥+0.1, no dim ≤-0.3 |
| .ps1 | Syntax parse | Exit 0 | Score ≥+0.1 |
| Config | Trivial | Trivial | No regression |
## Buffer Formats
Live schemas in `.learnings/rejected-edits.json` (key `rejectedEdits`: id/timestamp/target/edit/reason/delta) and `accepted-edits.json` (key `acceptedEdits`: id/timestamp/target/edit/delta/pattern). Both parseable JSON.
## Textual LR
Per edit: ≤10 lines OR ≤20%. Per epoch: ≤40. **Cosine decay**: `budget_n = max(4, base_budget × cos(π × n / (2 × N)))`. Early edits full, late taper to 4.
## Exit: inter≥30 + no dim<9.0 → SUCCESS; 7d exhausted → STOP; score -0.5 → revert; same fix 3x → SKIP
## Refs: CYCLE.md · inter-track · extract-skill · run-improvement-cycle · score-auto · SkillOpt arXiv:2605.23904 · SkillSpector
