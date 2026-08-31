# Punto más débil del Orquestador — Análisis 2026-08-29

**Fecha**: 2026-08-29
**Método**: Pre-Answer Evidence Gate (glob docs/mejoras/*.md + ctx_search + mem_search) + lectura verificada
**Engram ID**: #504 discovery/punto-m-s-d-bil-orquestador-an-lisis-2026-08-29

## Resumen

Vulnerabilidad arquitectónica por diseño: el orquestador NUNCA edita archivos directamente, depende 100% de delegación correcta. Si descompone mal el scope/contract o permite overlap de archivos, falla él. Catalogado 2026-08-29: B 93 files a quick → STOP tool_04f4cc7 + deep 404 ses_fb038747.

## 3 Debilidades históricas (docs/mejoras/2026-08-14-weakness-improvement-plan.md:9-58) — marcadas ✅ COMPLETADAS pero con gap residual

1. Memoria de mediano plazo (plan:11) — "Si no guardo en Engram lo pierdo entre compaction" — Mitigado con session-checkpoint.ps1 + mem_save proactivo
2. Creatividad vs precisión UX (plan:29) — Mitigado con vision-analyze + Ollama + baseline-ui/ui-engine pairing
3. Optimización extrema de performance (plan:47) — Mitigado con hardware-profile.ps1 + CI regression gate

## Gaps residuales vigentes (docs/mejoras/2026-08-26-gentleman-agent-gh-analisis.md:85-89)

- G7 RESUELTO (hard gate IMPLEMENTADO): session-checkpoint.ps1 + close-session.ps1 hard gate verificado — Decisions param + pending-engram.json fallback + process-pending mode + engram_mem_save consumo obligatorio por orchestrator. Citas: scripts/session-checkpoint.ps1:247-280 (process-pending mode), scripts/close-session.ps1:256-310 (Phase 2 hard gate blocks close until save confirmed). Pester 13/13 + 43/43 PASS.
- G8 RESUELTO (offline-first hardening): ui-specialist-pairing.ps1 degradación verificada, confidence:low flag, decisión owner = aceptar fallback offline documentado (no requiere Ollama local). Si owner quiere full mode, instalar Ollama 0.11+ y set OLLAMA_CLOUD=0. Cita: scripts/ui-specialist-pairing.ps1:232-235,259-262,266

## Punto más débil HOY

1. Ventana de contexto YELLOW>40% → RED>80% (_core-behavior-gp.md) — sin checkpoint a tiempo, alucina/olvida
2. Enforcement nulo (2026-07-28-orchestrator-self-analysis.md:13) — "Mecanismos existen, enforcement es nulo. Como tener extintores pero sin detector de humo." — Tools existen (Engram, ctx_search, codebase-memory) pero nada obliga a usarlos antes de responder.

## Propuesta Next

Wirear inter-track.ps1 + callback MCP real para G7. Convertir enforcement conductual en hard gate — **IMPLEMENTADO** (process-pending mode + close-session Phase 2 gate). G8 ya no es blocker tras este hardening (offline-first con confidence:low flag documentado).

## Evidencia

- docs/mejoras/2026-08-14-weakness-improvement-plan.md:9-58, 71-89
- docs/mejoras/2026-07-28-orchestrator-self-analysis.md:10-15, 191-221
- docs/mejoras/2026-08-26-gentleman-agent-gh-analisis.md:85-89
- AGENTS.md guard T2+

## Learned

Aunque las 3 debilidades históricas están Done, el gap real HOY es de enforcement. El orquestador falla si descompone mal.