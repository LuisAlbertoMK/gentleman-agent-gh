# GAPS · Negocio/Edge Cases · gentleman-agent-gh
Fecha: 2026-07-03
Auditor: agente-optimizado v2.2 · 56 scripts PS1 analizados

## Hallazgos

| # | Severidad | Archivo:Línea | Descripción | Recomendación |
|---|---|---|---|---|
| 1 | 🔴 Crítico | scripts/backup.ps1:14 | **Sin \Continue**. Fallas silenciosas en git init, git add, git commit. Si un backup falla, el script reporta éxito igual. | Agregar \Continue = 'Stop'. Envolver git calls en try/catch con reporting. |
| 2 | 🔴 Crítico | scripts/install.ps1:46 | **Invoke-Expression desde URL sin checksum**. Invoke-WebRequest \| iex descarga y ejecuta script remoto sin verificar integridad (no hash, no firma). | Reemplazar con descarga a archivo temporal + verificación SHA256 antes de ejecutar. |
| 3 | 🔴 Crítico | scripts/dev-server.ps1:1,59-75 | **Sin Set-StrictMode ni \Continue**. Maneja procesos hijos con registro JSON sin locking. Un error en el manejo de procesos huérfanos puede dejar procesos vivos sin control. | Agregar ambos. Implementar Mutex o FileStream con Lock para el registro. |
| 4 | 🔴 Crítico | scripts/optimize-system.ps1:54-142 | **Sin rollback**. Modifica registro (HKLM), pagefile (CIM), deshabilita hibernate (powercfg), cambia fsutil. Cualquier error a mitad de camino deja el sistema en estado inconsistente sin capacidad de deshacer. | Implementar snapshot de configuraciones antes de modificar + función rollback en finally. |
| 5 | 🔴 Crítico | scripts/pull-upstream.ps1:71 | **Path hardcodeado a Git Bash**. "C:\Program Files\Git\bin\bash.exe" falla si Git está instalado en otra ruta (chocolatey, scoop, portable). | Usar Get-Command bash -ErrorAction SilentlyContinue o la lógica de ash-safe.ps1 como fallback. |
| 6 | 🔴 Crítico | scripts/check-upstream.ps1:71 | **Path hardcodeado a Git Bash**. Misma debilidad que pull-upstream. Además no hay validación de que la URL del upstream sea reachable antes de ejecutar git ls-remote. | Centralizar resolución de bash en función compartida. Agregar timeout y retry a ls-remote. |
| 7 | 🔴 Crítico | scripts/inter-track.ps1:56,104 | **Race condition en JSON read-modify-write**. Dos invocaciones simultáneas de -Increment pueden perder incrementos (leer mismo valor, incrementar, escribir). Ídem para -Reset. | Usar System.Threading.Mutex o file lock. Alternativa: append-only log + reducer, no read-modify-write. |
| 8 | 🟠 Alto | scripts/setup-machine.ps1:31 | **Sin Set-StrictMode**. Variables no declaradas pasan desapercibidas. Uso de \ sin garantía de inicialización en ciertos code paths. | Agregar Set-StrictMode -Version Latest al inicio. |
| 9 | 🟠 Alto | scripts/sync-global.ps1:130-165 | **Sin Set-StrictMode**. Además, New-Item -ItemType Junction requiere administrador en Windows. No hay verificación de privilegios ni fallback graceful si falla la creación de junctions. | Agregar Set-StrictMode. Verificar admin antes de junctions. Fallback a symlink o copy + watch. |
| 10 | 🟠 Alto | scripts/score-auto.ps1:1 | **Sin Set-StrictMode ni \Continue**. Script extenso (81 líneas) con lógica compleja que accede a archivos, ejecuta otros scripts, y modifica .project.json. Cualquier error intermedio pasa desapercibido. | Agregar ambos. Encerrar secciones críticas en try/catch. |
| 11 | 🟠 Alto | scripts/restore-project-score.ps1:8 | **Sin \Continue**. Usa git update-index y git checkout commands. Si git falla (ej. repo detached HEAD), el error puede ser silencioso. | Agregar \Continue = 'Stop'. Verificar \ después de cada git call. |
| 12 | 🟠 Alto | scripts/trend.ps1:4 | **Sin \Continue**. Get-Content \| ConvertFrom-Json puede fallar por JSON corrupto. Usa try/catch en loop pero no protege el script principal. | Agregar \Continue = 'Stop'. |
| 13 | 🟠 Alto | scripts/pull-upstream.ps1:44 | **Git errors silenciados**. git checkout ... 2>&1 \| Out-Null descarta errores de git. Si el checkout falla (conflictos, paths incorrectos), no se detecta. | Usar \ = git ... 2>&1 y verificar \. No silenciar stderr. |
| 14 | 🟠 Alto | scripts/backup.ps1:30 | **Git errors silenciados**. git add -A 2>&1 \| Out-Null descarta errores. Si hay archivos bloqueados o paths problemáticos, el backup parece exitoso pero no lo es. | Sacar del null pipe. Verificar \. |
| 15 | 🟠 Alto | scripts/restore.ps1:37 | **Destructivo sin confirmación real de riesgo**. git checkout "\" -- . sobrescribe archivos de trabajo. Usa Read-Host pero no muestra diff completo ni hay dry-run granular. | Mostrar diff completo antes de pedir confirmación. No usar -- . sin verificar que no hay cambios sin commit. |
| 16 | 🟠 Alto | scripts/ponytail-audit.ps1:2 | **Sin \Continue al nivel correcto**. Tiene solo Set-StrictMode. Si falla la lectura de un skill (permisos, encoding), el error se propaga como warning pero no se registra en el reporte. | Agregar \Continue = 'Stop' y envolver secciones en try/catch. |
| 17 | 🟠 Alto | scripts/smoke-all.ps1:13 | **Dependencia de archivo externo sin fallback**. Dot-source de bash-safe.ps1 desde ruta global asume que setup-machine.ps1 ya corrió. Si no, falla con error críptico. | Usar \ para localizar bash-safe.ps1 relativo al repo. |
| 18 | 🟠 Alto | scripts/intake-debug.ps1:10 | **Path hardcodeado a pwsh.exe**. Ruta fija a PowerShell 7 que no existe en todas las instalaciones. | Usar (Get-Command pwsh).Source o \C:\Program Files\PowerShell\7\pwsh.exe según contexto. |
| 19 | 🟡 Medio | scripts/bash-safe.ps1:2 | **Sin \Continue global**. La función Invoke-Bash setea \Continue = 'Continue' (línea 58), pero si el dot-source se hace desde script padre con 'Stop', hay inconsistencia. | Documentar contrato de ErrorAction. Usar \System.Management.Automation.DefaultParameterDictionary para no contaminar caller. |
| 20 | 🟡 Medio | scripts/score-auto.ps1:42 | **Lectura byte-level sin validación de encoding**. Lee bytes de SKILL.md buscando UTF-8 corruption. Si el archivo tiene BOM UTF-8 + ASCII, el byte 0xC3 no indica necesariamente corrupción. | Usar [System.Text.Encoding]::UTF8.GetString() o Get-Content -Encoding en lugar de raw bytes. |
| 21 | 🟡 Medio | scripts/check-skill-drift.ps1:42 | **Comparación de líneas como drift detection**. Compara cantidad de líneas entre SKILL.md canónico y global. Dos skills con mismo contenido pero distinto line ending (CRLF vs LF) se marcan como drift. | Usar hash de contenido (Get-FileHash) en modo Thorough siempre. |
| 22 | 🟡 Medio | scripts/verify.ps1:49-57 | **Detección de secretos con regex naive**. Busca password\s*=, secret\s*=, etc. Sin chequeo de contexto (ej. password = dummy en test). Falsos positivos garantizados. | Agregar exclusiones para archivos de test, ejemplos, y variables de entorno. |
| 23 | 🟡 Medio | scripts/extract-skill.ps1:94 | **Regex multilínea sin protección de ReDoS**. Patrón (?s)## [.*?].*?\n.*?\*\*Pattern-Key\*\*:  con .*? repetido sobre archivos largos puede causar backtracking catastrófico. | Acotar con límites: . → [^\n]{0,200}. Usar [regex]::Match() con timeout. |
| 24 | 🟡 Medio | scripts/tokenize-all.ps1:39 | **Python subprocess sin timeout**. python -c "..." puede colgarse si tiktoken no está instalado o el proceso se bloquea. | Agregar timeout de proceso (Start-Process -Wait) o usar System.Diagnostics.Process con WaitForExit(ms). |
| 25 | 🟡 Medio | scripts/session-miner.ps1:9-15 | **Parseo de tabla markdown con regex frágil**. Cualquier cambio de formato en ANTI-PATTERN-CATALOG.md rompe el parseo. | Usar ConvertFrom-Markdown o parser de pipe-table más robusto. Agregar test de formato. |
| 26 | 🟡 Medio | scripts/close-session.ps1:38-40 | **BITACORA.md prepend sin lock**. Dos close-session simultáneos pueden pisar la entrada del otro. | Usar Add-Content (append al final) + indicador de batch al inicio, no prepend. |
| 27 | 🟡 Medio | scripts/cross-ref-check.ps1:7 | **Path de usuario hardcodeado**. Fallback a HOME si USERPROFILE no existe, pero falla en sistemas sin ninguno (ej. contenedores mínimos). | Usar [Environment]::GetFolderPath('UserProfile') o verificar ambos con fallback más robusto. |
| 28 | 🟡 Medio | scripts/ensure-tools.ps1:70 | **PATH mutation por script**. Modifica el PATH de la sesión del caller si se hace dot-source. Sin documentación de efecto secundario. | Usar \C:\Program Files\PowerShell\7;C:\Program Files (x86)\Common Files\Oracle\Java\java8path;C:\Program Files (x86)\Common Files\Oracle\Java\javapath;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\Program Files\nodejs\;C:\Program Files\Warp\bin;C:\Program Files\Git\cmd;C:\composer;C:\adb;;C:\Program Files\Docker\Docker\resources\bin;C:\Program Files\GitHub CLI\;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\System32\Wbem;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;C:\WINDOWS\System32\OpenSSH\;C:\Program Files\dotnet\;C:\Program Files\PowerShell\7\;C:\Users\MK\.opencode\bin;C:\Users\MK\AppData\Local\Programs\Python\Python314\Scripts\;C:\Users\MK\AppData\Local\Programs\Python\Python314\;C:\Users\MK\scoop\apps\postgresql\current\bin;C:\Users\MK\bin;C:\Users\MK\AppData\Local\engram\bin;C:\Users\MK\scoop\shims;C:\Users\MK\AppData\Local\pnpm;C:\Users\MK\AppData\Local\Microsoft\WindowsApps;C:\Users\MK\AppData\Roaming\npm;C:\Users\MK\AppData\Local\Programs\Microsoft VS Code\bin;C:\Users\MK\AppData\Local\Programs\Windsurf\bin;C:\Users\MK\AppData\Roaming\Composer\vendor\bin;C:\Program Files\Tesseract-OCR;C:\Users\MK\AppData\Local\Microsoft\WindowsApps;C:\Users\MK\Downloads;C:\Users\MK\AppData\Local\Microsoft\WinGet\Packages\BurntSushi.ripgrep.MSVC_Microsoft.Winget.Source_8wekyb3d8bbwe\ripgrep-15.1.0-x86_64-pc-windows-msvc;;C:\Users\MK\AppData\Local\gentle-ai\bin;C:\Users\MK\AppData\Local\Python\bin;C:\Program Files\MySQL\MySQL Server 8.4\bin solo en scope del script o documentar que modifica sesión. |
| 29 | 🟡 Medio | scripts/check-upstream.ps1:91 | **Git ls-remote sin timeout**. Si el remote repo no responde (network down, DNS failure), el script se cuelga indefinidamente. | Agregar timeout: 	imeout 10 git ls-remote ... o Start-Process con timeout. |
| 30 | 🟡 Medio | scripts/pssa-gate.ps1:46,55 | **Parallel ForEach-Object sin manejo de errores de child runspace**. Si un archivo se bloquea entre la enumeración y la lectura, el error se pierde en \ del runspace. | Agregar try/catch dentro del bloque parallel + rethrow con información del archivo. |
| 31 | 🟢 Bajo | scripts/check-backlog-integrity.ps1:60-79 | **Parseo de tabla markdown asume columnas fijas**. Si CYCLE.md cambia de formato (agrega/quita columnas), el mapeo se rompe silenciosamente. | Validar número de columnas antes de acceder. Nombrar columnas por header match. |
| 32 | 🟢 Bajo | scripts/run-improvement-cycle.ps1:38 | **Sync de archivo sin bloqueo**. Add-Content puede entremezclarse con otra escritura concurrente en .learnings/LEARNINGS.md. | Agregar mutex o usar append con timestamp único. |
| 33 | 🟢 Bajo | scripts/capture-errors.ps1:84-89 | **Snapshot overwrite sin confirmación**. Sobrescribe LATEST_error.json sin verificar si hay datos no guardados previamente. | Renombrar anterior a timestamp antes de sobrescribir. |
| 34 | 🟢 Bajo | scripts/project-cycle.ps1:254-256 | **Slug de proyecto sin sanitización completa**. Regex-replace puede generar slugs vacíos o duplicados si el nombre es solo caracteres especiales. | Usar slugify más robusto con longitud mínima garantizada. |
| 35 | 🟢 Bajo | scripts/token-count.ps1:31 | **Heurística de tokens muy imprecisa**. chars/4 asume 4 chars/token. Para markdown con markup el ratio real puede ser 2-3x distinto. | Documentar que es heurística. Ofrecer flag para usar tiktoken real. |
| 36 | 🟢 Bajo | scripts/skill-test-suite.ps1:81 | **Regex de referencia huérfana con falsos positivos**. URLs que contienen /SKILL.md en texto plano se marcan como ref rotas incluso si son paths válidos. | Verificar que el path existe en filesystem antes de marcar como error. |
| 37 | 🟢 Bajo | scripts/bash-safe.ps1:106-108 | **Detección de GENTLEMAN_AGENT_ROOT solo para junctions**. Si el script se invoca desde symlink (no junction), no detecta el root. | Agregar soporte para SymbolicLink además de Junction. |
| 38 | 🟢 Bajo | scripts/run.ps1:24-29 | **Detección de root solo para junctions**. Misma limitación que bash-safe.ps1. | Agregar chequeo de LinkType -eq "SymbolicLink" como alternativa. |
| 39 | 🟢 Bajo | scripts/setup-machine.ps1:130 | **Junction requiere Admin en Windows moderna**. New-Item -ItemType Junction puede fallar sin privilegios elevados. Solo avisa, no ofrece alternativa automática. | Intentar symlink si junction falla. Como fallback final, copy con watch. |
| 40 | 🟢 Bajo | Todos los scripts | **Inconsistencia en output**: algunos usan Write-Host, otros Write-Output. Sin switch consistente -Quiet/-Json en muchos. En pipelines automatizados, Write-Host contamina stdout. | Usar Write-Information o Write-Verbose para output informativo. Write-Output solo para datos. |
| 41 | 🟢 Bajo | scripts/bootstrap.sh:134-135 | **git reset --hard sin confirmación en update**. Si el repo local tiene cambios no commiteados, se pierden sin warning. | Verificar git status --porcelain antes de reset --hard. Ofrecer stash. |
| 42 | 🟢 Bajo | scripts/gentleman.sh:44 | **git checkout -- . destructivo sin diff preview**. Sobrescribe todo el working directory. No hay confirmación del impacto real. | Mostrar git diff --stat antes de pedir confirmación. |
| 43 | 🟢 Bajo | scripts/bootstrap.ps1:66 | **Remove-Item -Recurse -Force sin verificación**. Si pull falla, borra todo el InstallDir y re-clona. Peligroso si InstallDir tiene contenido no relacionado. | Verificar que InstallDir es efectivamente el repo antes de borrar. |

## Resumen

**Total: 43** | 🔴 Críticos: 7 | 🟠 Altos: 11 | 🟡 Medios: 13 | 🟢 Bajos: 12

### Distribución por categoría

| Categoría | Conteo |
|-----------|--------|
| Error handling ausente (ErrorActionPreference / StrictMode) | 10 |
| Paths hardcodeados / platform-dependant sin check | 6 |
| Race conditions / falta de locking | 4 |
| Sin rollback / cleanup en operaciones destructivas | 6 |
| Regex frágiles o ReDoS | 4 |
| Encoding / Unicode / Paths especiales | 3 |
| Git calls con errores silenciados | 4 |
| Invoke-Expression / descarga insegura | 1 |
| Validación de parámetros ausente o insuficiente | 3 |
| Parseos de markdown con formato frágil | 2 |

### Notas adicionales

- **Ninguno** de los scripts implementa manejo de señales (Ctrl+C, SIGTERM, ConsoleCancel). En scripts largos como optimize-system.ps1, un Ctrl+C a mitad de camino deja el sistema en estado inconsistente.
- **Unicode en names**: varios scripts concatenan strings con \ para paths (ej. "\\.agents\skills") en lugar de usar Join-Path. Si \C:\Users\MK contiene caracteres Unicode, no hay problema directo, pero si aparecen en nombres de skills/rutas, Join-Path es más seguro.
- **No hay validación de paths con espacios** en scripts que invocan procesos externos sin citar correctamente los argumentos. Ej. bench-file-io.ps1 línea 78-82: & \.script \ — si \ tiene espacios, se pasa como múltiples argumentos.
- **El proyecto tiene 40+ scripts con buena higiene general** (mayoría con ambos Set-StrictMode y ErrorActionPreference). Los hallazgos críticos se concentran en scripts de backup/restore (que son los más riesgosos por naturaleza).
