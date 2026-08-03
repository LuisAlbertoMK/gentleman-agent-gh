# ADR-010: Revertir hallazgo falso positivo (engram = 18 tools, no 8)

- **Status**: Accepted · **Ciclo**: C9 (2026-08-03) · **Tipo**: proceso/verificación
- **Context**: Hallazgo INFRA-3 del análisis multi-auditoría afirmaba que `check-mcp-security.ps1` estaba stale (reportaba engram=18 cuando "el MCP actual expone 8 herramientas"). `confidence: medium`, sin verificación directa.
- **Decision**: REVERTIDO. Conteo verificado en el toolset real = **18 tools**. El cambio a `8` se deshizo; 26/26 tests OK. Regla de proceso: un hallazgo con `confidence: medium` sin verificación directa debe validarse contra el sistema real antes de propagarse como fix.
- **Alternatives**: Aplicar el "fix" a ciegas — rechazado: habría degradado el chequeo de seguridad con datos falsos.
- **Consequences**: `check-mcp-security.ps1` intacto. El breaker por ciclo es la red que atrapa este tipo de ruido antes del merge.
- **Refs**: `mejora-log.md` §Ciclo 9; `scripts/check-mcp-security.ps1`; `docs/mejoras/2026-08-03-gentleman-agent-gh-analisis.md` (INFRA-3).
