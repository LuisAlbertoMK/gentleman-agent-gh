# ADR-002: Triggers de recomendación con word boundaries

- **Status**: Accepted · **Ciclo**: C2/C5 (2026-08-02) · **Tipo**: bugfix/regex
- **Context**: La regla `pr` suelta en `agentRecommendations` (skill-graph.ps1 L175/L181) matcheaba la subcadena "pr" dentro de "improve"/"preview" → recomendaciones falsas de commit/PR (6 warnings en tests, falsos positivos ocultos en runtime).
- **Decision**: `\bprs?\b` (word boundary + plural opcional) en ambas reglas; `pull.request` preserva el wildcard.
- **Alternatives**:
  - Quitar `pr` de la regla — rechazado: pierde "open a PR" como trigger legítimo.
  - Case-sensitive global — rechazado: rompe los demás triggers case-insensitive.
  - `\bpr\b` sin plural — rechazado en breaker C5: rompe "PRs" legítimo.
- **Consequences**: singular y plural correctos; falsos positivos muertos (improve/preview). Tests de regresión añadidos (auto-registro de skills + aserciones).
- **Refs**: `mejora-log.md` §Ciclo 2 y §Ciclo 5 (breaker); `scripts/skill-graph.ps1`.
