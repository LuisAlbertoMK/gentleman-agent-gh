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
