# ADR-009: Modelo híbrido de junctions (health-check)

- **Status**: Accepted · **Ciclo**: C9 post (2026-08-03) · **Tipo**: architecture
- **Context**: `health-check.ps1` reportaba 3 junctions globales "degradadas" contra un modelo obsoleto de "junction total por directorio". Verificación en vivo: 1 ya reparada (vmk-prompts-junction), 2 eran falsos positivos del chequeo.
- **Decision**: El modelo real es híbrido: `~/.config/opencode/skills` = 78 junctions por-skill (todas vivas) + 10 dirs reales deliberados (`_shared` con sdd-status-contract.md fuera de repo + 9 sdd-* global-only sin contraparte en repo). Fix: `vmk-skills-junction` valida cobertura real (cada skill del repo, excepto allowlist `_shared`, debe tener junction viva); `global-skills-junction` permite dirs reales solo si deliberados; semántica WARN (no FAIL).
- **Alternatives**: Borrar los dirs deliberados para "sanear" — rechazado: rompe consumo de skills global-only.
- **Consequences**: health-check 3/3 OK (antes 2× WARN falsos). Baseline del gate [8/13] actualizado a 78/78 (snapshot `20260803-051109_benchmark.json`).
- **Refs**: `mejora-log.md` §Cierre pendiente entorno; commit `a6e64345`; `docs/metricas/snapshots/20260803-051109_benchmark.json`.
