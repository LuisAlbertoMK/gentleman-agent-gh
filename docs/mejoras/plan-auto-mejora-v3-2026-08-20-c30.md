# Plan: Auto-Mejora v3 — Ciclo 30 (2026-08-20b)

**Protocolo**: `docs/protocolos/protocolo_mejora_autonoma_v3.md`
**Base**: `main` HEAD `85176d54`
**Branch**: `experimento/mejora-autonoma-2026-08-20-c30`
**Baseline**: heredado de Ciclo 29 (mismo árbol): 1304 pass / 31 fails pre-existentes / 1336 total, verificado ×2 idéntico

## G1: monitor-subagent.ps1 sin integración C4d — drift doc↔código

- **Fuente**: grep main `85176d54`: 0 matches para `SubagentOutputFile|contract_valid` en `scripts/monitor-subagent.ps1`; `docs/mejoras/2026-08-15-subagent-result-quality.md` documenta la integración como hecha
- **Impacto**: la ruta async de delegación corre SIN validación de contrato 4-field; un subagente con output malformado pasa en modo async (la ruta sync SÍ valida desde Ciclo 29)
- **Blast Radius**: Medio · **ICE**: 8×9×7 = 504

### Scope Lock
```
IN:  scripts/check-subagent-output.ps1 (solo nuevo param -AgentOutputFile),
     scripts/monitor-subagent.ps1 (-SubagentOutputFile + contract check + campos JSON),
     tests/post-delegation-async.Tests.ps1, scripts/tests/check-subagent-output.Tests.ps1,
     docs/mejoras/{mejora-log.md,rollback-map.md}, adr/
OUT: post-delegation-check.ps1 (sync path ya correcto), prompts/, skills/, AGENTS.md,
     validate-write-scope.ps1
```

### 3 Enfoques
| Enfoque | Descripción | Pros | Contras |
|---|---|---|---|
| **A** | Nuevo `-AgentOutputFile` en cso (lee archivo→valida) + monitor pasa path escapado por subprocess | Cero contenido en command-line (sin quoting/injection de texto multilinea); reusa validador único | Toca 2 scripts |
| **B** | Monitor embebe CONTENIDO del archivo en la command line escapada | Un solo script tocado | Frágil con newlines/CRLF/comillas; superficie de injection |
| **C** | Monitor duplica Validate-AgentReturnContract localmente | Sin cambios en cso | Drift del validador — exactamente el anti-patrón que combate el ciclo |

### Ganador esperado
**A** — seguridad (no pasar contenido por command-line) > DRY > minimal-diff.

### Especificación
- cso: `-AgentOutputFile <path>` → lee contenido como `$AgentOutput` (override si ambos); archivo ilegible → exit 1 fail-closed
- monitor: `-SubagentOutputFile <path>` → si existe, agrega `-AgentOutputFile` al csoCmd; parsea `contract_valid`/`contract_detail` del JSON Quiet; agrega check `contract_validation`; expone ambos campos top-level en async-result.json; archivo inexistente → warning + skip (espeja sync path); ausente del param → comportamiento actual intacto (backward-compat)
- Tests: extender T3 (params), +3 monitores (válido/inválido/archivo faltante), +1 unit cso para -AgentOutputFile

### DoD
- [ ] Tests nuevos verdes; suite completa ×2 idéntica, 0 NEW failures vs baseline
- [ ] Breaker adversarial PASS (o notes corregidos)
- [ ] ADR-042 + mejora-log + rollback-map
- [ ] Commits separados fix/feat dentro de scope; gate 22/22
- [ ] Merge autorizado por usuario (pre-aprobación standing "todo verde → merge", gaps Medio/Bajo)
