# ADR-019: Mejora Autónoma Iterativa v2 — Corrida 3 Kickoff

- **Status**: Accepted · **Date**: 2026-08-05 · **Type**: process
- **Context**: Corridas 1 y 2 completadas con merge verificado a main (7f3861d4). El usuario pidió corrida nueva con presupuesto explícito: N=6 ciclos máx, umbral decreciente 5%.
- **Decision**: Corrida 3 en `experimento/mejora-autonoma-2026-08-05` desde main (ab553823). Métricas: Pester suite completa (732/0 baseline), opencode.json ≤65,536B (53,556B baseline), gate 18/18, counts skills (79/88), npm audit vulns (2 baseline: 1 high fast-uri, 1 moderate hono). Presupuesto N=6 ciclos; rendimiento decreciente <5% vs. ciclo anterior → STOP; checkpoint humano cada 2 ciclos; ICE prioritización; costo cero (orchestrator ejecuta todos los roles, patrón corridas previas).
- **Alternatives**: Reabrir lever `prompts/shared/` — rechazado: bloqueado por policy de seguridad (ADR-018, requiere decisión humana). Sin presupuesto fijo — rechazado: el protocolo exige presupuesto para converger.
- **Consequences**: Ciclo 1 = fix vulns npm (fast-uri HIGH, hono moderate, ambas transitivas con fix). Entregables `mejora-log.md`/`benchmarks.md`/`adr/` actualizados por ciclo; merge a main solo si se cumplen condiciones §5 del protocolo.
- **Refs**: `mejora-log.md` §Corrida 3 — 2026-08-05; memoria #2378 (cierre corrida 2); ADR-018 (blocker prompts).
