# Cheatsheet — gentleman-agent-gh

## Shortcuts

| Shortcut | Acción |
|----------|--------|
| `!score` | Score-auto + docs update + cross-ref |
| `!compress` | Karpathy compression skills >2.5KB |
| `!sync` | Pull upstream → drift check → score |
| `!health` | Git status, drift, cross-ref, score |
| `!close` | Pipeline de cierre unificado |
| `!manifest` | Lee CYCLE.md, reporta ciclo actual |
| `!setup` | Setup máquina nueva (.ps1 o .sh según OS) |
| `!dev` | Manage background dev servers |
| `!gentleman` | Heredar config en otro proyecto |
| `!ponytail` | Cambiar intensidad: lite / full / ultra / off |
| `!analisis` | Análisis multi-agente profundo |
| `!audit` | Blind audit por subagente externo |
| `!dream` | Extracción de patrones cross-session |
| `!batch` | Batch auto-incremental + bitácora |
| `!cycle` | Inter-track + score + upstream |

## Ponytail Modes

| Modo | Rungs | Cuándo |
|------|-------|--------|
| `lite` (default) | 0-3 (necesidad) | Uso diario |
| `full` | 0-8 + seguridad | Cambios complejos |
| `ultra` | 0-8 + revisión agresiva | Refactors grandes |
| `off` | Ninguno | Debugging |

## Risk Zones (ceremony level)

| Señal | Ceremonia |
|-------|-----------|
| 🟢 1 file, ≤3 líneas | Commit + secrets scan |
| 🟡 ≤3 files, test-only | + quality-gate |
| 🟠 3-8 files, lógica existente | + triple-verify |
| 🔴 >8 files o auth/data/API | Full pipeline + !audit |

## Quick cmds

```bash
# Diagnóstico
!health          # todo en uno
!score           # score + métricas
!manifest        # ciclo actual

# Setup
!setup           # máquina nueva
!gentleman       # en otro proyecto

# Cierre
!close           # BITACORA + resumen
```
