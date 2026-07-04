# Revisión Lineal · Scripts Parte 1 · gentleman-agent-gh
Fecha: 2026-07-03
Revisor: auditoria estatica automatizada + analisis humano
Alcance: 22 scripts (orden alfabetico A-L), de los cuales 19 existen y 3 no se encontraron

## Hallazgos

| # | Severidad | Archivo:Linea | Descripcion | Recomendacion |
|---|-----------|---------------|-------------|----------------|
| 1 | 🟠 Alto | dev-server.ps1:128-135 | Fuga de EventSubscriber: Register-ObjectEvent crea suscripciones de evento persistentes que nunca se limpian. Cada Start-Server genera dos suscripciones (OutputDataReceived + ErrorDataReceived) que retienen referencias a StreamWriter. Se acumulan durante la sesion del agente. | Almacenar IDs de suscripcion en el registro y llamar Unregister-Event -SubscriptionId $id al hacer Kill o Cleanup. O usar Get-EventSubscriber | Unregister-Event en Cleanup. |
| 2 | 🟡 Medio | auto-clean.ps1:45-51 | Conteo y tamano incorrectos cuando falla Remove-Item: $size += $f.Length (L45) y $count++ (L51) se ejecutan incondicionalmente, incluso si el archivo no pudo eliminarse. El reporte final sobreestima archivos y bytes borrados. | Mover $size += $f.Length y $count++ DENTRO del bloque try, despues de Remove-Item. Solo contabilizar eliminaciones exitosas. |
| 3 | 🟡 Medio | bootstrap.ps1:45,47,57,63,67,75 | Uso de `$?` para verificar comandos externos en lugar de `$LASTEXITCODE`. `$?` es notoriamente poco confiable con redirecciones (`2>$null`), especialmente en PS 5.1 donde este script podria ejecutarse. Las fallas podrian no detectarse. | Reemplazar `if (-not $?)` por `if ($LASTEXITCODE -ne 0)` en todas las llamadas a git, scoop y choco. |
| 4 | 🟡 Medio | check-upstream.ps1:71 | Ruta hardcodeada a Git Bash (`C:\Program Files\Git\bin\bash.exe`). Falla en sistemas donde Git esta instalado en otra ruta (Chocolatey, Scoop, portable, WSL). | Usar bash-safe.ps1 o la misma logica de resolucion de bash (Get-Command bash, varias rutas candidatas). |
| 5 | 🟡 Medio | ensure-tools.ps1:25 | Ruta de ripgrep hardcodeada con version especifica ripgrep-15.1.0. Al actualizar via WinGet/choco la ruta cambia y la herramienta deja de detectarse. | Usar Get-ChildItem con wildcard en el directorio padre o Get-Command rg en PATH. |
| 6 | 🟡 Medio | cross-ref-check.ps1:16-17 | Potencial crash nulo si SKILLS-INDEX.md no existe: Select-String con -ErrorAction Stop lanza excepcion que no esta en try/catch. | Envolver en try/catch o verificar existencia con Test-Path antes de Select-String. |
| 7 | 🟢 Bajo | backup.ps1:13 | `#requires -Version 7.6` duplicado (tambien en linea 1). | Eliminar linea 13. |
| 8 | 🟢 Bajo | bench-file-io.ps1:16 | `#requires -Version 7.6` duplicado (tambien en linea 1). | Eliminar linea 16. |
| 9 | 🟢 Bajo | ensure-tools.ps1:13 | `#requires -Version 7.6` duplicado (tambien en linea 1). | Eliminar linea 13. |
| 10 | 🟢 Bajo | backup.ps1:22,27,28,30,35 | Comandos git sin verificacion de error: todo stderr se redirige a null (`2>&1 | Out-Null`) sin revisar `$LASTEXITCODE`. Fallas silenciosas en init, add, status. | Agregar verificacion `if ($LASTEXITCODE -ne 0) { Write-Warning ... }` despues de cada comando git critico. |
| 11 | 🟢 Bajo | close-session.ps1:50 | Dependencia implicita de scripts/score-auto.ps1. Si falta (no es el caso actual), falla silenciosamente (try/catch lo captura) pero el usuario no recibe advertencia. | Agregar Write-Debug o Write-Warning informativo en el catch. |
| 12 | 🟢 Bajo | check-skill-drift.ps1:42 | `[IO.File]::ReadAllText($cp)` sin especificar encoding. Archivos no UTF-8 (ej. Latin-1/Windows-1252 con caracteres especiales) darian conteo de lineas incorrecto. | Usar `[System.IO.File]::ReadAllText($cp, [System.Text.Encoding]::UTF8)`. |
| 13 | 🟢 Bajo | intake-verify.ps1:3 | Nombres de parametros cripticos (`$p`, `$i`, `$t`, `$m`, `$f`). Cero descubribilidad sin leer la implementacion. | Renombrar a `$Path`, `$Iterations`, `$Type`, `$EnableMetrics`, `$Format`. |
| 14 | 🟢 Bajo | intake-verify.ps1:46 | Iteracion fragil sobre array plano con indices pares/impares como pares path/label. Facil de romper al agregar un nuevo item. | Usar array de hashtables `@{path="..."; label="..."}` en lugar de indices implicitos. |
| 15 | 🟢 Bajo | bench-compare.ps1:13-15 | Definiciones de funcion (Get-Line, Get-Byte) dentro de un bloque try de nivel superior. No estandar y puede causar confusion de scoping. | Mover definiciones de funcion fuera del try/catch. |
| 16 | 🟢 Bajo | bench-compare.ps1:21 | Placeholder literal mostrado: `Write-Host ("  vMK (Go): ?L")` - el `?L` nunca fue reemplazado con el valor real. | Reemplazar `?L` con el resultado real o eliminar la linea. |
| 17 | 🟢 Bajo | capture-errors.ps1:107 | `Sort-Object LastWriteTime` sobre FileInfo es correcto, pero ordena por metadato del fs en vez del timestamp del contenido JSON. Si un archivo se copia, el orden podria diferir del cronologico real. | Ordenar por `$_.timestamp` (campo JSON) despues de parsear. |
| 18 | 🟢 Bajo | intake-verify.ps1:95 | `-en utf8` es abreviacion de `-Encoding utf8`. Funciona en PS pero es inconsistente con el estilo del resto del proyecto que usa `-Encoding UTF8`. | Usar `-Encoding UTF8` completo. |
| 19 | 🔴 Critico | auto-metrics.ps1 | Archivo NO ENCONTRADO en scripts/. No existe en el repositorio. Referenciado por AGENTS.md y close-session.ps1 como ruta conocida del pipeline de cierre. | Crear el script o actualizar todas las referencias cruzadas si fue renombrado/eliminado. |
| 20 | 🔴 Critico | commit-crafter.ps1 | Archivo NO ENCONTRADO en scripts/. No existe en el repositorio. Referenciado por AGENTS.md como parte del flujo !ship. | Crear el script o actualizar referencias. |
| 21 | 🔴 Critico | intake.ps1 | Archivo NO ENCONTRADO en scripts/. No existe en el repositorio (existe intake-verify.ps1 e intake-debug.ps1 pero no intake.ps1). | Crear o renombrar o documentar que no existe como script independiente. |

## Resumen

Total: 21 | 🔴 Criticos: 3 | 🟠 Altos: 1 | 🟡 Medios: 3 | 🟢 Bajos: 14

### Distribucion por archivo

| Archivo | Hallazgos | Highlights |
|---|---|---|
| auto-clean.ps1 | 1 | Conteo incorrecto en errores de borrado |
| auto-metrics.ps1 | 1 | **NO EXISTE** - referenciado como existente |
| backup.ps1 | 2 | `#requires` duplicado; git sin verificacion de error |
| bash-safe.ps1 | 0 | Sin issues funcionales |
| batch.ps1 | 0 | Script limpio |
| bench-compare.ps1 | 2 | Funciones en try; placeholder sin resolver |
| bench-file-io.ps1 | 1 | `#requires` duplicado |
| benchmark.ps1 | 0 | Extremadamente minificado pero funcional |
| bootstrap.ps1 | 1 | Uso de `$?` en vez de `$LASTEXITCODE` |
| capture-errors.ps1 | 1 | Sort por metadato del fs en vez de timestamp del contenido |
| check-backlog-integrity.ps1 | 0 | Script limpio |
| check-mcp-security.ps1 | 0 | Bien estructurado |
| check-skill-drift.ps1 | 1 | Encoding no especificado en ReadAllText |
| check-upstream.ps1 | 1 | Git Bash hardcodeado |
| close-session.ps1 | 1 | Warning silencioso si score-auto falta |
| commit-crafter.ps1 | 1 | **NO EXISTE** - referenciado como existente |
| cross-ref-check.ps1 | 1 | Crash potencial si SKILLS-INDEX.md falta |
| dev-server.ps1 | 1 | Fuga de EventSubscriber |
| ensure-tools.ps1 | 2 | Ruta rg hardcodeada; `#requires` duplicado |
| inter-track.ps1 | 0 | Script limpio |
| intake.ps1 | 1 | **NO EXISTE** |
| intake-verify.ps1 | 3 | Parametros cripticos; iteracion fragil; abreviatura inconsistente |

### Notas adicionales

- **Archivos limpios** (0 hallazgos): bash-safe.ps1, batch.ps1, benchmark.ps1, check-backlog-integrity.ps1, check-mcp-security.ps1, inter-track.ps1
- **Minificacion excesiva**: benchmark.ps1, cross-ref-check.ps1, intake-verify.ps1 priorizan densidad sobre legibilidad. Funcional pero dificil de mantener.
- **`#requires` duplicado**: Ocurre en 3 scripts (backup.ps1, bench-file-io.ps1, ensure-tools.ps1) - probablemente por merge o copia inadvertida.
- **Hallazgo #19 (auto-metrics.ps1) y #20 (commit-crafter.ps1)**: son criticos porque AGENTS.md los lista como parte del pipeline `!close` y `!ship` respectivamente. Sin ellos, esos flujos estan rotos.
- **dev-server.ps1** usa `#requires -Version 7.0` mientras el resto del proyecto usa `7.6`. Posiblemente heredado; funcional pero inconsistente.

