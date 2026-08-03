# ADR-003: Des-envolver arrays PowerShell con `@(...)` en call-sites

- **Status**: Accepted · **Ciclo**: C4/C5 (2026-08-02) · **Tipo**: bugfix/PS-semantics
- **Context**: Funciones PowerShell que retornan arrays de 1 elemento se desenvuelven a objeto único → `.Count`/`.Length`/foreach con semántica rota. `run-dreaming.ps1` crasheaba con `ParentContainsErrorRecordException` (L134; luego L207/L224 con 0/1 keywords).
- **Decision**: Wrapper `@(...)` en TODOS los call-sites que usan `.Count`/`.Length`/foreach sobre resultados de funciones. `@(...)` es idempotente.
- **Alternatives**:
  - `return ,$result` (unary comma) en la función — rechazado: protege solo 1 caller.
  - Cast `[array]` en la variable — rechazado: mismo efecto, más ruido.
- **Consequences**: Count semánticamente correcto (0/1/2/3 patrones verificados en lab). Regla defensiva: SIEMPRE envolver con `@(...)` al consumir `.Count` de un retorno de función.
- **Refs**: `mejora-log.md` §Ciclo 4 y §Ciclo 5; `scripts/run-dreaming.ps1`.
