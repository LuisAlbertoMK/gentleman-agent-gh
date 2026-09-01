# R2-1 Playbook — Estructura addyosmani para las 93 skills (rollout incremental)

> **Scan 2026-09-01**: 93/93 sin anti-rationalization · 93/93 sin red flags · 49/93 sin verification · 0/93 con las 3. **Exemplares** (esta parte): `opencode-model-router`, `context-watchdog`, `session-resume` (commiteados juntos). Restantes: 90.

## Patrón addyosmani (referencia: KB `r2-fundesk-skills-guide`, repo `addyosmani/agent-skills` 18.1k★, v0.5.0 MIT)

Cada skill debe tener, en este orden, antes de `## Refs`:

```markdown
## Anti-Rationalization
| Rationalization | Red Flag | Verification |
|-----------------|----------|--------------|
| "Atajo X" | Señal observable | Paso verificable tool-backed |

## Red Flags
- bullet list (2-4) de señales de parada

## Verification
- bullet list (2-3) de pasos con comando/tool citado (git, cross-ref, Pester)
```

## Plantilla por dominante de skill

| Dominio | Anti-rationalization típica | Red flag | Verification |
|---------|-----------------------------|----------|--------------|
| Infra/Deploy | "Deploy directo sin canary" | Sin rollback plan | `infra-audit` checklist + dry-run |
| Frontend/UI | "Pixel perfect sin token" | Hardcode hex/rgb | `baseline-ui` tokens OKLCH |
| Performance | "Optimizar sin perfilar" | Sin baseline | `benchmark-core.ps1 -Gate` antes/después |
| Security | "Escanear después" | `.breaker-cleared` sin review | `security-audit-mcp.ps1` + JD dual |
| Data/Science | "EDA rápido sin pipeline" | Sin `data-pipeline.ps1` | Pipeline stages 1-3 PASS |

## Rollout incremental (3-5 skills por sesión — respeta delivery-harness ≤10 files)

1. Lote por affordance (e.g., sesion: 3 skills de misma área — infra)
2. Por skill: leer `SKILL.md` → añadir secciones → bump `token_budget` (~+400 chars → budget+=500) → `cross-ref-check.ps1` OK
3. Commit por lote: `feat(skills): R2-1 estructura addyosmani — <batch> (3 skills)`

## Orden sugerido (por impacto)

1. Lote 1 (HECHO): `opencode-model-router` + `context-watchdog` + `session-resume`
2. Lote 2: `judgment-day` + `security-scanner` + `testing-strategy` (ROJA zone heavy)
3. Lote 3: `delivery-harness` + `skill-graph` + `skill-creator` (orquestación)
4. Lote 4+: restantes por `scripts/skill-registry` usage DB (716 sessions — baja cobertura primero)

## Verificación por lote

- `& scripts/cross-ref-check.ps1` → `SKILL.md... OK` + `INDEX count 92→93` según lote
- Gate: `[2/13] SKILL.md frontmatter` + `[24/24] Token budget` deben pasar (bump si needed)
- `ctx_search(source: "r2-fundesk")` para refrescar plantilla si dudas

## Trazabilidad

- KB: `r2-fundesk-skills-guide` (24 secciones), `r2-hn-agents-truths`
- Engram: este playbook + scan results (bloque anterior)
- Métrica: `has_all_3: 3/93` tras lote 1 → target `93/93` al cerrar
