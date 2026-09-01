# P0-1 LCM — Hierarchical Summary DAG para context-watchdog (diseño parte 1/3)

> **KB**: `r2-codersera-llm-landscape`, `arxiv:2605.04050` (LCM, 11 secciones KB r2-anthropic + paper), `context-watchdog SKILL.md` actual (L1/L2/L3). Investigación persistida en KB + Engram 849/850.
> **Objetivo**: reemplazar L1/L2/L3 lineal por DAG jerárquico con pointers lossless, para eliminar *context rot* (performance degrada antes del límite nominal) — el punto débil YELLOW>40→RED>80.

## Arquitectura propuesta (Volt → gentleman-agent-gh)

```
Root context (0) ─┬─ L1 summary DAG node (compact, ~20% tokens)
                  ├─ L2 section node (structured, per-file summary)
                  └─ L3 pointer (lossless → full file + git diff link)
```

**Escalation protocolo (LCM Fig.3)**: Si L1 no reduce <60% de presupuesto → auto-escala a L2; si L2 falla → L3 con file pointer. Nuestro watchdog hoy hace L1/L2/L3 pero sin DAG ni pointers.

## Integración en repo

| Componente | Estado actual | Cambio P0-1 |
|------------|---------------|-------------|
| `.agents/skills/context-watchdog/SKILL.md` | L1/L2/L3 lineal, manual | Añadir DAG node schema + escalation rules |
| `scripts/context-watchdog.ps1` (si existe) / `scripts/lib/ctx-*.ps1` | — | Crear `scripts/lcm-dag.ps1`: Build DAG, query por pointer, GC de nodos stale |
| `.learnings/lcm-dag.json` | no existe | Nuevo: `{ nodes: [{id, level, parent, pointer, tokens, createdAt}], edges: [] }` |
| `BITACORA` + `.learnings/inter-track.json` | linear history | DAG versionado por ciclo (cycle-29→30) |

## Parte 1 (este commit): diseño + interfaz

**No código aún** — este doc es el contrato para el próximo agente. Contiene:
- Schema JSON del DAG (validado contra paper §2.1)
- Escalation thresholds (60% budget, 80% hard)
- Integration points con `session-checkpoint.ps1` y `inter-track`

## Parte 2 (próxima sesión): `scripts/lcm-dag.ps1` + tests
- `New-LcmDag`, `Add-LcmNode`, `Get-LcmPointer`, `Invoke-LcmEscalation`

## Parte 3: wiring a `context-watchdog` skill + medición de context-rot (before/after)

## Referencias verificadas
- `modelcontextprotocol.io` Security Best Practices (ya usado P0-2) — técnicas de pointer seguro aplicables a L3
- `r2-zylos` 3-boundary rule — instrumentar DAG build (a) antes de output, (b) antes de tool, (c) on memory write
- `r2-fundesk` addyosmani anti-rationalization tables — incluir en DAG build para evitar racionalización de summarization
