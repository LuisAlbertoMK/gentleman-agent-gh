# ADR-006: Eliminar claves frontmatter muertas (user-invocable / disable-model-invocation)

- **Status**: Accepted · **Ciclo**: C8 (2026-08-03) · **Tipo**: optimization/tokens
- **Context**: Optimización de tokens/sesión pedida por el usuario. Las claves `user-invocable` y `disable-model-invocation` parecían control de routing en el frontmatter de 9 skills SDD globales.
- **Decision**: Remover ambas claves del frontmatter. Verificación previa: byte-scan del binario opencode 1.18.11 (0 hits), 0 consumidores en repo, schema oficial ignora. `metadata:` preservado (SÍ es reconocida).
- **Alternatives**: Dejarlas (inofensivas) — rechazado: 137 tokens/sesión desperdiciados en 9 skills.
- **Consequences**: −53 chars/skill, ~137 tokens/sesión. Regla: verificar claves de config contra schema/binario antes de asumir que tienen efecto — `limit.input` recomendado en análisis Jul-29 tampoco existe en el schema (corregido en C10).
- **Refs**: `mejora-log.md` §Ciclo 8; skills SDD globales en `~/.config/opencode/skills/sdd-*`.
