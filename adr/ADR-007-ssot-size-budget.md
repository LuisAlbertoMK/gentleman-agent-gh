# ADR-007: opencode.json SSoT + size budget guard (fail-closed por agente)

- **Status**: Accepted · **Ciclo**: C8/C9 (2026-08-03) · **Tipo**: architecture
- **Context**: opencode.json creció 35.5KB → 52.2KB (+47%) sin protección durante el experimento. El SSoT `scripts/lib/permission-templates.json` (1 template × 10 agentes) ya deduplica el contenido; editar opencode.json a mano se pierde con la regeneración.
- **Decision**: (1) `regenerate-opencode.ps1` con parámetro `-MaxBytes` (default 65,536) + check config-size-budget post-write. (2) Gate pre-commit check 14/14: validar sync SSoT↔opencode.json cuando cambia `scripts/lib/` u `opencode.json`. (3) Fail-closed por agente es diseño intencional: la compactación root→agentes (PERF-1, "27% duplicado") es **won't-fix** — heredar root arriesga la semántica de merge de opencode con beneficio de mantenimiento nulo.
- **Alternatives** (PERF-1): compactar root→agentes — rechazado (won't-fix justificado arriba).
- **Consequences**: Guard verificado en ambos sentidos (52,205 fail / 52,206 pass, `-gt` correcto). Regeneración idempotente (SHA256 idéntico). Gate 14/14.
- **Refs**: `mejora-log.md` §Ciclo 8/9; `scripts/regenerate-opencode.ps1`, `.githooks/pre-commit-gate.ps1`, `docs/mejoras/2026-08-03-gentleman-agent-gh-analisis.md` (PERF-1 won't-fix).
