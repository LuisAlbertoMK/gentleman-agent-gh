# ADR-004: Helper central para esquema-ausente en scripts SQL

- **Status**: Accepted · **Ciclo**: C6 (2026-08-02) · **Tipo**: bugfix/robustez
- **Context**: `engram-compact.ps1` crasheaba con traceback Python crudo al procesar una DB sin tabla `user_prompts` (DBs pre-schema). El purge además usaba `cur.execute` directo, heredando el mismo hueco.
- **Decision**: Helper central `has_table()` consultando `sqlite_master`; `count()` y `dup_rows()` devuelven `0`/`[]` si la tabla no existe. Guard extra en el purge (`if purge_days > 0 and has_table("sync_mutations")`).
- **Alternatives**:
  - try/except por call-site — rechazado: 5 wrappers, riesgo de ocultar errores SQL reales.
  - `CREATE TABLE IF NOT EXISTS` (migración) — rechazado: muta el esquema del usuario y falsearía el "before".
- **Consequences**: Contrato JSON limpio en todos los casos de tabla ausente (dry/apply exit 0, `prompts: 0`). 2 tests de regresión nuevos.
- **Refs**: `mejora-log.md` §Ciclo 6; `scripts/engram-compact.ps1`.
