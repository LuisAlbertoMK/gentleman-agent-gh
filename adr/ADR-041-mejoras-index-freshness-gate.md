# ADR-041: Gate de frescura del índice docs/mejoras/

**Fecha**: 2026-08-20 · **Ciclo**: 29/C2 (G2) · **Estado**: Aceptado

## Contexto
`docs/mejoras/` fue flaggeado UNANIMOUS como "sink" (finding #3, self-analysis 2026-07-28): análisis escritos pero nunca re-leídos. El Pre-Answer Evidence Gate del orquestador depende de que el índice README.md esté completo. Evidencia viva 2026-08-20: solo 19/54 análisis indexados; knowledge base ctx vacía y engram sin hits pese a 57 docs.

## Decisión
Script standalone fail-closed `scripts/mejoras-index-check.ps1` + 14 tests Pester:
- Candidatos: `*.md` top-level excluyendo README.md, plan-template.md, mejora-log.md
- Un doc cuenta como indexado si su filename aparece como substring en README.md
- Exit 0 solo si 0 faltantes; directorio/README ausente o ilegible (locked) → exit 1
- `-Json` emite `{indexed,total,missing,valid}` para integración CI/futuras hooks

## Alternativas descartadas
- **Generar índice automáticamente desde filenames**: cero mantenimiento pero pierde las columnas semánticas (dominio/hallazgos) que hacen útil el índice al Evidence Gate.
- **Hook de opencode que bloquee commit**: enforcement fuerte pero toca runtime config — riesgo fuera del presupuesto del ciclo.

## Consecuencias
- Índice sincronizado a 54/54 (35 rows agregadas).
- El gate fallará si se agrega un análisis sin indexarlo — convierte la higiene del sink en chequeable.
- Limitación conocida (LOW, breaker): matching case-insensitive; en FS case-sensitive (Linux) un mismatch de caso pasaría el gate. Aceptado: repo primario Windows, impacto cosmético.
- README count drift de scripts (117→118) corregido en el mismo ciclo.
