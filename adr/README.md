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
| [ADR-014](ADR-014-size-budget-enforcement.md) | Size budget enforcement | — | Ver archivo |
| [ADR-015](ADR-015-write-scope-failclosed.md) | Write-scope fail-closed on invalid patterns | C1-close | Malformed pattern → ERROR + exit 1 |
| [ADR-016](ADR-016-backlog-integrity-gate-json.md) | Backlog integrity gate JSON | — | Ver archivo |
| [ADR-017](ADR-017-skill-token-reduction.md) | Skill token reduction | — | Ver archivo |
| [ADR-018](ADR-018-security-policy-blocks-prompts-token-lever.md) | Security policy blocks prompts token lever | — | Ver archivo |
| [ADR-019](ADR-019-automated-empty-output-detection.md) | Automated post-delegation empty-output detection | C1 | check-subagent-output.ps1 + 4/4 tests |
| [ADR-020](ADR-020-jd-clearance-markers.md) | JD clearance markers | — | Ver archivo |
| [ADR-021](ADR-021-auto-register-template-map.md) | Auto-register template map | — | Ver archivo |
| [ADR-022](ADR-022-package-manager-deny-floor.md) | Package manager deny floor | — | Ver archivo |
| [ADR-023](ADR-023-fail-closed-write-scope.md) | Fail-closed write scope | — | Ver archivo |
| [ADR-024](ADR-024-auto-sub-permission-merge-safety.md) | Auto-sub permission merge safety (guard dinámico) | Cycle #1 v3 B2 | `Object.keys(template)` fail-closed |
| [ADR-025](ADR-025-ci-coverage-root-tests.md) | CI coverage for root `tests/` | Ciclo 1 v2 | Job paralelo tests-v1 |
| [ADR-026](ADR-026-mejora-autonoma-v2-corrida3-kickoff.md) | Mejora Autónoma v2 — Corrida 3 kickoff | 2026-08-05 | Presupuesto N=6, umbral 5% |

> **Nota**: ADR-024/025 vienen de `docs/adr/` (desviación de convención documentada en los cycle logs); ADR-019 (kickoff) renumerado a ADR-026 por colisión con automated-empty-output-detection.

**Convención**: Status = Accepted salvo indicación; decisiones con `confidence: high` verificadas por breaker por ciclo.
