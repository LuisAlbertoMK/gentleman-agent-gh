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
| 5 | Skills muertas (deletion candidates) | done (slice 4) | `chore(skills): archive 3 retired skills to .archive` |
| 6 | Frontmatter consistency | done (slice 5) | `fix(skills): complete immune-system description and document vision vs visual-testing scope` |
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

## Slice 5 — Frontmatter (immune-system truncation) + vision/visual-testing differentiation
- Files: `.agents/skills/immune-system/SKILL.md`, `.agents/skills/vision-analyze/SKILL.md`,
  `.agents/skills/visual-testing/SKILL.md`.
- immune-system L10 completed to mirror frontmatter: "detect, diagnose, document to anti-pattern
  catalog, immunize in AGENTS.md rules." — no meaning change.
- Differentiation: explicit `## Differentiation` line added in BOTH vision-analyze (LLM local via
  Ollama, NOT visual regression) and visual-testing (screenshots/regression via Playwright, NOT LLM);
  mutual cross-ref: vision-analyze already listed `visual-testing`; `vision-analyze` appended to
  visual-testing's `## Cross-Refs` line.
- **Decision (d) triggers array-vs-string**: NOT normalized (see below).
- Budget: immune-system completed line pushed file 2084 → 2149 B over enforced ceiling
  (budget 1898 × 1.1 = 2088 B). Per precedent `e47d202f` ("bump budgets safely, not trim",
  same as slice 1 skill-improver note) → `token_budget` 1898 → 2000 (limit 2200, margin 51 B).
  Explicit deviation, gate-forced.

## Decision (d) — triggers array vs string: no mass normalization
- Loader: `scripts/build-skill-registry.ps1` L47-56 parses `triggers:` three ways — quoted
  comma-separated string, bare string, AND YAML inline array `[a, b]` (L51 strips quotes, L52 strips
  brackets, L54 splits/trims/lowercases). Resolution chain: build-skill-registry (raw YAML) →
  skill-registry.json → skill-resolver-fast.ps1 / skill-graph.ps1.
- Runtime proof: vision-analyze (inline array, `[capture, vision, ...]`) → registry entry
  `['capture','vision','analyze-ui','visual-review','captura','analizar-imagen']` — identical
  normalization to quoted-string files (visual-testing, immune-system, skill-improver). BOTH formats
  function → mass normalization has unjustified blast radius → NOT performed. vision-analyze's array
  kept as-is.
- Canonical format (documented, not enforced): comma-separated quoted string
  `triggers: "a, b, c"` — listed first in loader comment, majority usage across skills.
- Nuance: `scripts/scan-skills.ps1` L72 (audit/diff tool, NOT the trigger resolver) does not strip
  brackets in its output for inline arrays — cosmetic audit output only, not a loader limitation.
- Totals check (git-tracked registry untouched): `build-skill-registry.ps1` → 97 skills, 645 triggers.

## Review Log

| Slice | Reviewed | Evidence | Verdict |
|-------|----------|----------|---------|
| 1 | threshold line diff + validator | skill-testing L17 / skill-improver L20 | PASS |
| 2 | trigger grep + YAML validator | only auto-metrics retains `!metrics` | PASS |
| 3 | grep `!metrics` across `.agents/skills` + YAML validator | residual declarations: auto-metrics only | PASS |
| 4 | git mv + frontmatter check + refs grep | `skill-creator` → `.archive/skills/skill-creator` (plain-name pattern); `opencode-skill-creator` KEPT (8 triggers, agents/references/templates, ecosystem refs); sole live stale ref migrated: `commands/skill-creator.md` L2+L7 | PASS |
| 5 | git mv ×3 + grep archived names in `.agents/skills` + index count | `.archive/skills/{cognitive-doc-design,prompt-engineering,senior-engineer}` slots replaced (old July copies recoverable @ `9f238a81`); residual refs in `.agents/skills`: only karpathy-loop cross-ref; active count 99→96; SKILLS-INDEX v5.9 | PASS |
| 6 | YAML validator (frontmatter-only) ×3 + registry build + diff minimal | immune-system L10 completed (mirrors frontmatter); `## Differentiation` added in vision-analyze + visual-testing; mutual cross-ref (visual-testing L49 `| vision-analyze` appended); loader build-skill-registry.ps1 L47-56 accepts string AND inline array (vision-analyze `[capture, vision, ...]` → registry list OK) → no mass trigger normalization (blast radius unjustified), canonical = quoted comma-separated string | PASS |

## Guardrails
- No skill deletion · no other skill triggers touched · no edits outside listed files.
- Archive (git mv → `.archive/skills`, plain-name pattern) per precedent `9f238a81`; nothing destroyed — full recovery via git history.
- No push, no PR, no merge (separate phase, explicitly NOT performed).
