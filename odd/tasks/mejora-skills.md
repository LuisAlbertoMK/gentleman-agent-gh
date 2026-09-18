# ODD Task — mejora-skills

Branch: `mejora-skills` · Base: `main` (intacto) · Rule: max deliverable = open PR (fase aparte, NOT done here).

## Context
`.agents/skills/` are REAL repo directories (177 tracked files). Global junctions point INTO the repo,
so any edit here propagates globally at once — edits are surgical by design.

## Slices

| # | Slice | Status | Deliverable |
|---|-------|--------|-------------|
| 1 | Spike — junctions/estructura (read-only) | done | Verificado: junctions → repo, sin escritura |
| 2 | Gates medibles — X/Y numéricos en skill-testing / skill-improver | done (slice 1) | `fix(skills): define measurable token thresholds in testing/improver gates` |
| 3 | Disambiguar `!metrics` — metricas vs auto-metrics | done (slice 2) | `fix(skills): disambiguate !metrics trigger to auto-metrics` |
| 4 | Archivos duplicados entre skills | done (slice 3) | `chore(skills): archive duplicate skill-creator, keep opencode-skill-creator` |
| 5 | Skills muertas (deletion candidates) | pending | candidate list |
| 6 | Frontmatter consistency | pending | metadata normalizado |
| 7 | Prosa → reglas accionables | pending | prose-to-rules pass |

## Slice 1 — Gates medibles
- Files: `.agents/skills/skill-testing/SKILL.md`, `.agents/skills/skill-improver/SKILL.md`
- Criterion source: `scripts/check-token-budget.ps1` (`-BudgetBytes` default **3200 B**; per-file
  `overBudgetFiles` = files > 3200 B). Declared `token_budget` max fits the cap.
- X = 3200 B (avg SKILL.md) · Y = 3200 B (longest single template/file).
- Verify: frontmatter parses (YAML); diff limited to the threshold lines.
- Gate [25/26] note: `skill-improver` was 1 B under its enforced ceiling (2793 B / limit 2794 B).
  Per repo precedent `e47d202f` ("bump budgets safely, not trim") its `token_budget` was raised
  2540 → 2600 B so the added threshold stays within budget*1.1 (limit 2860 B).

## Slice 2 — Disambiguar `!metrics`
- Decision: `auto-metrics` KEEPS `!metrics` (scoring); `metricas` DROPS `- "!metrics"` (keeps
  `!metricas` + other triggers). Migration note added to both skills.
- Files: `.agents/skills/metricas/SKILL.md`, `.agents/skills/auto-metrics/SKILL.md`
- `SKILLS-INDEX.md`: not edited — it lists skill names/groups, it does NOT document triggers.
- Verify: grep confirms only `auto-metrics` declares `!metrics`; YAML valid.

## Review Log

| Slice | Reviewed | Evidence | Verdict |
|-------|----------|----------|---------|
| 1 | threshold line diff + validator | skill-testing L17 / skill-improver L20 | PASS |
| 2 | trigger grep + YAML validator | only auto-metrics retains `!metrics` | PASS |
| 3 | grep `!metrics` across `.agents/skills` + YAML validator | residual declarations: auto-metrics only | PASS |
| 4 | git mv + frontmatter check + refs grep | `skill-creator` → `.archive/skills/skill-creator` (plain-name pattern); `opencode-skill-creator` KEPT (8 triggers, agents/references/templates, ecosystem refs); sole live stale ref migrated: `commands/skill-creator.md` L2+L7 | PASS |

## Guardrails
- No skill deletion · no other skill triggers touched · no edits outside listed files.
- Archive (git mv → `.archive/skills`, plain-name pattern) per precedent `9f238a81`; nothing destroyed — full recovery via git history.
- No push, no PR, no merge (separate phase, explicitly NOT performed).
