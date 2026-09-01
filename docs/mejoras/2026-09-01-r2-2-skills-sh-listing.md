# R2-2 — Listing en skills.sh / awesome-opencode (distribución)

> **KB**: `r2-fundesk-skills-guide` (24 secciones, Vercel skills.sh Jan 2026, 19 agentes), `r2-awesome-opencode-registry` (8,947★, 643 forks). Investigación 2026-09-01, fetch persistido.

## Skills seleccionadas para submission (8/93 — alto impacto + novedad 2026)

| # | Skill | Descripción | Novedad 2026 | Target |
|---|-------|-------------|--------------|--------|
| 1 | `context-watchdog` | Recursive Summary Compression (L1/L2/L3) + Hierarchical DAG (P0-1 LCM) | LCM DAG wiring 3-boundary rule (nuevo) | skills.sh + awesome-opencode |
| 2 | `judgment-day` | Dual adversarial review + 6-pattern taxonomy Zylos (76-162ms, small/large judges) | Taxonomía 6 patrones (nuevo) | skills.sh |
| 3 | `security-scanner` | Pre-commit scan (secrets, injection, supply chain, deps) | + `security-audit-mcp.ps1` (P0-2) | skills.sh |
| 4 | `delivery-harness` | Multi-agent orchestration (≤10 files, 4-field contract) | Anti-rationalization (R2-1) | awesome-opencode |
| 5 | `opencode-model-router` | Route by model strength (reasoning tier nemotron) | Reasoning tier P0-3 (nuevo) | awesome-opencode |
| 6 | `skill-graph` | Sparse loading + dependency resolution | Anti-rationalization (R2-1) | awesome-opencode |
| 7 | `session-resume` | Save/restore, git gate, Engram recall | Anti-rationalization (R2-1) | skills.sh |
| 8 | `baseline-ui` | Anti-slop UI (tokens, @layer, container queries) | Anti-rationalization (R2-1) | skills.sh |

## Submission — skills.sh (Vercel, 19 agentes)

Repo: `vercel-labs/skills` — open directory, leaderboard por agente. Skills son `SKILL.md` con frontmatter `name/description/triggers/changelog/token_budget` (nuestros 93 ya cumplen 93/93 tras P1-1, presupuesto global 3200 ADR-048).

Pasos:
```bash
# 1. Fork + branch
gh repo fork vercel-labs/skills --clone
git checkout -b add/gentleman-agent-gh-context-watchdog

# 2. Copiar skill (conservar frontmatter + anti-rationalization)
cp -r .agents/skills/context-watchdog skills/context-watchdog/

# 3. Validar localmente
# skills.sh valida via skill_validate (mismo que repo)

# 4. PR con descripción: link a KB r2-fundesk + changelog 2026-09-01 P0-1/P0-2/R2-4
gh pr create --title "feat: add context-watchdog (Hierarchical DAG) from gentleman-agent-gh" --body "See KB r2-fundesk + P0-1 LCM DAG design..."
```

Repetir para 8 skills (1 PR por skill o 1 PR con 8 — seguir CONTRIBUTING.md de vercel-labs/skills).

## Submission — awesome-opencode (8,947★)

Repo: `anomalyco/awesome-opencode` o `brightcoding` fork (registry). Categorías: `memory persistence`, `multi-agent orchestration` (pedido en R2-1 playbook).

Pasos: Fork → editar `README.md` sección `Skills` → añadir fila por skill con `| gentleman-agent-gh/context-watchdog | Hierarchical DAG L1/L2/L3 + 3-boundary | [link]` → PR.

## Catálogo generado

Ver `scripts/skills-catalog-for-distribution.json` (8 entries, para automatizar submission o `find-skills` 500k installs).

## Estado

- [ ] PR `context-watchdog` → skills.sh
- [ ] PR `judgment-day` → skills.sh
- [ ] PR `security-scanner` → skills.sh (con referencia a `security-audit-mcp.ps1`)
- [ ] PR `awesome-opencode` → 8 skills

> Este doc es el plan de distribución; la ejecución es 8 PRs manuales (1 sesión, ~2h). No se pushea código de skills.sh aquí, solo el plan + catálogo.
