# Shortcuts

| Keyword | Qué hace |
|---------|----------|
| `!ship` / `!listo` | Pipeline completo: captura learnings → triple-verify → quality-gate → commit + push |
| `!check` | Solo quality-gate, sin commit |
| `!fast` | Hotfix: commit + push directo, saltea verificación |
| `!draft` | Modo exploración, sin verificaciones |
| `!compress` | Comprime skills >2.5KB + actualiza score |
| `!score` | Ejecuta score-auto.ps1 + actualiza docs |
| `!sync` | Pull upstream + chequea drift + sync agents |
| `!health` | Diagnóstico completo: git, drift, score, inter-track |
| `!batch` | Nueva batch auto-incremental + bitácora |
| `!cycle` | Resumen del ciclo actual: inter-track + score + upstream |
| `!close` | Pipeline de cierre: bitácora + inter-track + git status |
| `!manifest` | Lee CYCLE.md (reporta ciclo actual + score) + verifica/crea global shortcuts (opencode-vmk, gentleman-vmk) |

## Global Shell Shortcuts (en PATH)

| Comando | Qué hace | Equivale a |
|---------|----------|------------|
| `opencode` | Launch OpenCode con agente default (gentleman-vMK) | `opencode` |
| `opencode-vmk` | Launch OpenCode forzando gentleman-vMK | `opencode --agent gentleman-vMK` |
| `gentleman-vmk` | Alias de opencode-vmk | `opencode --agent gentleman-vMK` |

**Ubicación**: `%APPDATA%\npm\` (ya está en PATH global)
**Platforma**: Windows (.cmd + .ps1 wrappers)

### Instalación manual (si no existen):
```powershell
# Ya creados en %APPDATA%\npm\opencode-vmk.cmd/.ps1 y gentleman-vmk.cmd/.ps1
# Verificar que existen:
Get-Command opencode-vmk, gentleman-vmk
```
