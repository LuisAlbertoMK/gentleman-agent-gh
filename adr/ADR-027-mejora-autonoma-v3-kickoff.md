# ADR-027: Mejora Autónoma Iterativa v3 — Kickoff

- **Status**: Accepted · **Date**: 2026-08-13 · **Type**: process
- **Context**: Nueva corrida de mejora autónoma sobre `main` HEAD `0d88467c`. Protocolo `docs/protocolos/protocolo_mejora_autonoma_v3.md`. Presupuesto: 3 ciclos máx · 15 min/ciclo · $0 (free-tier models only). Escalado de prioridad: **correctness > security > performance > size**. Branch: `experimento/mejora-autonoma-2026-08-13`.
- **Decision**: 3 gaps priorizados por ICE (Impacto×Confianza×Esfuerzo inverso):
  - **G1** — `ConvertTo-Json` single-element array unwrapping. Fuente `sync-vmk.ps1:157` + `use-gentleman.ps1:106`. ICE 9×9×8 = **648**. Blast Radius Bajo. → Ciclo 1.
  - **G3** — `sync-vmk.ps1` no incluye `gentle-orchestrator` + `sdd-*` agents (39→50). Fuente `sync-vmk.ps1:54`. ICE 9×9×7 = **567**. Blast Radius **Alto** → **checkpoint humano obligatorio antes de merge**. → Ciclo 2.
  - **G2** — No CI quality gate valida config antes de deploy. ICE 8×7×6 = **336**. Blast Radius Medio. → Ciclo 3.
- **Baseline estadístico (§0.7)**: obligatorio mediana/IQR de 5-10 runs, no un número único. `benchmark-baseline.json` inicial contenía solo `BenchmarkSeconds: 0.763`; se reemplazó por muestra Count=10, Median=139.7ms, Q1=122.6, Q3=163.3, IQR=40.7 (commit `2e966e0b`).
- **Pester baseline (§3.5)**: 669 pass / **7 fail** pre-existentes en `destructive-scripts.Tests.ps1` (`clean-repo.ps1` 4 + `engram-compact.ps1` 3), documentados en `mejora-log.md:18-21`. DoD = **0 NEW failures**; los 7 pre-existentes fuera de scope (Blast Radius Alto, requerirían checkpoint humano separado).
- **Entorno aislado (§0.9)**: ciclos corren en GitHub Actions efímero (`ubuntu-latest`, `shell: pwsh`), paths relativos al workspace del runner — nada de rutas Windows `D:\...`.
- **Alternatives**: G1 evaluado en ADR-028 (3 enfoques A/B/C). G2/G3 con 3 enfoques cada uno en ADR-029 y Ciclo 3 (ver planes por ciclo).
- **Consequences**: Cada ciclo con Scope Lock estricto, commits conventional tags, rollback map con hashes reales (`docs/mejoras/rollback-map.md`), ADR por ciclo (ADR-027/028/029), y `mejora-log.md` actualizado. **No merge a main** — G3 (Alto) exige aprobación humana explícita; el resto espera revisión.
- **Refs**: `docs/mejoras/plan-auto-mejora-v3-2026-08-13.md`; `docs/protocolos/protocolo_mejora_autonoma_v3.md`; ADR-003 (array unwrapping para `function returns`); ADR-026 (corrida v2 previa).
