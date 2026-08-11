# ADR-007: opencode.json SSoT + size budget guard (fail-closed por agente)

- **Status**: Accepted · **Ciclo**: C8/C9 (2026-08-03) · **Tipo**: architecture
- **Context**: opencode.json creció 35.5KB → 52.2KB (+47%) sin protección durante el experimento. El SSoT `scripts/lib/permission-templates.json` (1 template × 10 agentes) ya deduplica el contenido; editar opencode.json a mano se pierde con la regeneración.
- **Decision**: (1) `regenerate-opencode.ps1` con parámetro `-MaxBytes` (default 98,304 = 65,536×1.5, headroom para crecimiento de auto-sub twins) + check config-size-budget post-write. (2) Gate 17/17 fail-closed en pre-commit `.githooks/pre-commit-gate.ps1:14` + mirror en CI `.github/workflows/quality-gate.yml:87`; ambos a 98,304.
- **Amendment 2026-08-11**: el código enqueña consistentemente 98,304B (3 sites) pero este ADR/ADR-014/ADR-019 citan 65,536B → prosa desactualizada. Archivo actual 72,983B (74% de 98,304 → GREEN). Reducir a 65,536B requiere compactar PERF-1 (instrucción root→agentes), declarado won't-fix por riesgo en semántica de merge de opencode. Revisión a 65,536B bloqueada hasta que PERF-1 se reconsidere con checkpoint humano (ver plan `docs/mejoras/plan-kimi-k3.md` §P0.1).
- **Alternatives** (PERF-1): compactar root→agentes — rechazado (won't-fix justificado arriba).
- **Consequences**: Guard verificado en ambos sentidos (52,205 fail / 52,206 pass, `-gt` correcto). Regeneración idempotente (SHA256 idéntico). Gate 14/14.
- **Refs**: `mejora-log.md` §Ciclo 8/9; `scripts/regenerate-opencode.ps1`, `.githooks/pre-commit-gate.ps1`, `docs/mejoras/2026-08-03-gentleman-agent-gh-analisis.md` (PERF-1 won't-fix).
