# External Audit Findings — D:\mdShare Cross-Reference

> **Source**: 12 documentos en `D:\mdShare/` analizados el 2026-06-23
> **Propósito**: Centralizar hallazgos de auditoría externa, cotejar contra estado real del repo, y accionar mejoras.

## Findings Verified

### F1 — Skill count mismatch
| Fuente | Dice | Real |
|--------|------|------|
| README.md:3 | 69 skills | **70** (70 SKILL.md, 70 dirs) |
| `optimizacion-ram-cpu-gpu-gentle-ai-vs-gentleman-agent-gh.md` | 70 encontrados | ✅ Confirmado |
| `gentle-ai-mejoras-vs-gentleman-agent-gh.md` | "conteo inconsistente" | ✅ Confirmado |

**Diferencia**: 1 skill no contada (probablemente `karpathy-prompt` o `lean-context` agregada recientemente).

### F2 — README score desactualizado
| README dice | Real |
|-------------|------|
| 9.7/10 (12 dimensiones) | **9.9/10 (13 dimensiones)** |
| Cycle 7 activo | **Cycle 8** |

### F3 — install.ps1 e install.sh NO son de gentleman-agent-gh
Ambos scripts instalan **Gentle-AI** (`github.com/gentleman-programming/gentle-ai`), no este proyecto.
- README.md:68 referencia `.\scripts\install.ps1` como instalador → **incorrecto/misleading**
- `scripts/install.ps1` línea 6: `$o="Gentleman-Programming";$r="gentle-ai"`
- `scripts/install.sh` línea 2: "Gentle-AI Install Script"

**Riesgo**: Usuario ejecuta `.\scripts\install.ps1` esperando configurar gentleman-agent-gh y termina con Gentle-AI.

### F4 — README score-auto.ps1 descripción desactualizada
README.md:121: "Auto-scoring del proyecto en 12 dimensiones" → hoy son **13**.

### F5 — Model routing insights disponibles
De `opencode-free-specialities-v3(1).md`: jerarquía completa de modelos con fallback strategy.
Potencial mejora para skill `opencode-model-router`.

## Action Plan

| # | Acción | Archivos | Prioridad |
|---|--------|----------|-----------|
| A1 | Fix skill count: 69→70 | README.md | Alta |
| A2 | Fix score: 9.7→9.9, dims 12→13 | README.md, docs/operations/project-score.md | Alta |
| A3 | Fix cycle: 7→8 | README.md | Alta |
| A4 | Remove/replace misleading install.ps1/.sh | scripts/ | Crítica |
| A5 | Fix score-auto.ps1 description | README.md:121 | Media |
| A6 | Integrate model routing fallback | .agents/skills/opencode-model-router/ | Media |
| A7 | Sync BITACORA.md + metricas post-cambio | BITACORA.md, docs/metricas/ | Alta |

## Action Status

| # | Acción | Estado | Commit |
|---|--------|--------|--------|
| A1 | Fix skill count: 69→70 | ✅ Done (69 skills + _shared) | Pendiente |
| A2 | Fix score: 9.7→9.9, dims 12→13 | ✅ Done | Pendiente |
| A3 | Fix cycle: 7→8 | ✅ Done | Pendiente |
| A4 | Replace install.ps1/.sh con installer real | ✅ Done | Pendiente |
| A5 | Fix score-auto.ps1 description | ✅ Done | Pendiente |
| A6 | Integrate model routing fallback | ⏳ Pending (bajo impacto) | — |
| A7 | Sync BITACORA + metricas | ⏳ Pendiente (session close) | — |

## Source Documents Summary

| Documento | Relevancia para gentleman-agent-gh |
|-----------|------------------------------------|
| `agente-auto-modificable-host-aware-cuantizacion-extrema.md` | Teórico — no aplica (es sobre hardware extremo) |
| `agente-ia-vs-gentle-ai.md` | Informativo — no accionable |
| `aplicacion-plan-auto-mejora-auditoria.md` | Ejemplo de auto-auditoría — proceso ya implementado |
| `entrenar-vs-mejorar-ciclo-auto-mejora.md` | Informativo — no accionable |
| `gentle-ai-mejoras-vs-gentleman-agent-gh.md` | **Alta** — confirmó F1, F3, gaps del proyecto |
| `opencode-free-specialities-v3.md` | **Media** — model routing básico |
| `opencode-free-specialities-v3(1).md` | **Alta** — fallback strategy completo |
| `opencode-vs-luisalbertomk-opencode-optimizacion.md` | Informativo — sobre el fork de OpenCode, no este repo |
| `optimizacion-ram-cpu-gpu-gentle-ai-vs-gentleman-agent-gh.md` | **Alta** — confirmó F1, diferencias de recursos |
| `plan-auto-mejora-claude.md` | Informativo — concepto ya implementado en CYCLE.md |
| `plan-auto-mejora-claude-v2.md` | Informativo — mejoras incrementales ya presentes |
