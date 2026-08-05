# ADRs mini — Experimentos de Mejora Autónoma (2026-08-02/03)

> Entregable §7 del protocolo. ADRs extraídos de las decisiones documentadas en
> `mejora-log.md` (secciones C1–C9) y en `docs/mejoras/`. Formato compacto por decisión:
> Context / Decision / Alternatives / Consequences. Autoridad de detalle: mejora-log.md.

| ADR | Título | Ciclo | Decisión |
|---|---|---|---|
| [ADR-001](ADR-001-backward-compat-force-switch.md) | Backward-compat de switches destructivos | C1 | `[Alias('Yes')][switch]$Force` en clean-repo/engram-compact |
| [ADR-002](ADR-002-regex-word-boundaries.md) | Triggers de recomendación con word boundaries | C2/C5 | `\bprs?\b` en agentRecommendations |
| [ADR-003](ADR-003-powershell-array-wrapper.md) | Des-envolver arrays PowerShell | C4/C5 | Wrapper `@(...)` en call-sites, no `return ,` |
| [ADR-004](ADR-004-central-schema-guard.md) | Política de esquema-ausente en SQL | C6 | Helper central `has_table()` en engram-compact |
| [ADR-005](ADR-005-permission-layering.md) | Layering de permisos por modo | C7 | deny → destructive → mode |
| [ADR-006](ADR-006-dead-frontmatter-keys.md) | Claves frontmatter muertas | C8 | Strip de user-invocable / disable-model-invocation |
| [ADR-007](ADR-007-ssot-size-budget.md) | opencode.json SSoT + budget de tamaño | C8/C9 | Regeneración desde templates + guard -MaxBytes; fail-closed por agente |
| [ADR-008](ADR-008-whitespace-normalization.md) | Normalizar input antes de clasificar comandos | C9 | `-replace '\s+',' '` + Trim previo a Get-CommandClass |
| [ADR-009](ADR-009-hybrid-junction-model.md) | Modelo híbrido de junctions | C9 post | Junctions por-skill + dirs reales deliberados |
| [ADR-010](ADR-010-revert-false-positive.md) | Revertir hallazgo falso positivo | C9 | engram = 18 tools (no 8) |
| [ADR-011](ADR-011-mejora-autonoma-v2-kickoff.md) | Mejora Autónoma v2 — kickoff | 2026-08-04 | Accepted |
| [ADR-012](ADR-012-sync-global-deny-count-fix.md) | sync-global deny-count fix | 2026-08-04 | Accepted |
| [ADR-013](ADR-013-backlog5-criterion-conjunctive.md) | Backlog 5 criterion conjunctive | 2026-08-04 | Accepted |

**Convención**: Status = Accepted salvo indicación; decisiones con `confidence: high` verificadas por breaker por ciclo.
