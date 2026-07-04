# Seguridad · Inyección/Validación · gentleman-agent-gh

**Fecha:** 2026-07-03
**Alcance:** scripts/*.ps1 (58 scripts) + scripts/lib/JsonFast.psm1
**Enfoque:** PowerShell injection, shell injection, path traversal, command concatenation, input validation

---

## Hallazgos

| # | Severidad | Archivo:Línea | Descripción | Recomendación |
|---|---|---|---|---|
| 1 | 🔴 Crítico | install.ps1:46 | Invoke-Expression (Invoke-WebRequest -Uri url -UseBasicParsing).Content — descarga y ejecuta código arbitrario sin verificar integridad. MITM o DNS spoofing → ejecución arbitraria. | Reemplazar con descarga a temp + validación de checksum + & o dot-source condicional. url fijo pero el contenido no se verifica. |
| 2 | 🔴 Crítico | restore.ps1:28,37 | $Revision provisto por el usuario (L17 param string sin validación, L28 Read-Host) se interpola en git checkout "$Revision" -- . (L37). Aunque L30 hace git rev-parse --verify, un valor malicioso que pase esa verificación depende de cómo git maneje el argumento. | Usar ValidateScript o ValidatePattern para restringir Revision a hashes o referencias válidas. |
| 3 | 🟠 Alto | extract-skill.ps1:94 | Expresión regular construida concatenando key (L94: rx = "(?s)... " + key + " ...") sin [regex]::Escape(). key proviene de parámetro o del archivo .learnings/LEARNINGS.md. Si contiene metacaracteres (., *, +, (, )), causa ReDoS o bypass del matching. | Usar [regex]::Escape(key) al incrustar input en patrones regex. |
| 4 | 🟠 Alto | check-upstream.ps1:91 | & bashPath -c "git ls-remote 'url' HEAD 2>/dev/null" — url intercalado en comillas simples en un string bash -c. Aunque url es hardcoded (L41-44), si se modificara para contener una comilla simple ', se rompe el quoting y permite inyección de comandos en bash. | Usar Start-Process con -ArgumentList (array) o escapar comillas simples. Validar url con [System.Uri]. |
| 5 | 🟠 Alto | skillspector-gate.ps1:124 | docker run --rm -v "${hostPath}:/scan" $DockerImage scan $scanTarget ... — $DockerImage es parámetro [string] sin validación. Un atacante podría pasar -DockerImage malicioso y ejecutar un contenedor arbitrario. | Validar $DockerImage contra lista permitida o usar ValidatePattern. |
| 6 | 🟠 Alto | pull-upstream.ps1:48-54 | $TargetFile se usa directamente en git checkout y Move-Item sin validación de ../, podría hacer path traversal fuera del repo. | Validar $TargetFile con Resolve-Path y verificar que esté dentro del repo root. |
| 7 | 🟠 Alto | intake-verify.ps1:90,95-96 | Path construido concatenando p (param [string] sin validación): dv = "$p\docs\metricas". Luego escribe archivos ahí. Path traversal posible desde p. | Validar p con Test-Path y Resolve-Path. No usarlo como base para escritura sin verificar. |
| 8 | 🟡 Medio | bootstrap.ps1:57-58,63,67,75 | $Branch y $RepoUrl son parámetros [string] sin validación. Usados en git fetch, git reset, git clone. Branch malicioso podría causar problemas. | Agregar ValidatePattern a $Branch. Validar $RepoUrl con [System.Uri]. |
| 9 | 🟡 Medio | intake-verify.ps1:3 | param([string]p) — p sin ValidateScript ni ValidatePattern. Usado directamente en Test-Path, Get-ChildItem, Get-Content, New-Item. Sin restricciones, permite path traversal. | Agregar [ValidateScript({Test-Path $_ -PathType Container})]. |
| 10 | 🟡 Medio | verify.ps1:23,32,52 | Get-ChildItem con patrones de glob concatenados directamente. Aunque los directorios base vienen de Join-Path, el patrón es frágil. | Usar -Filter de Get-ChildItem. |
| 11 | 🟡 Medio | sync-global.ps1:31-36 | Paths críticos construidos con concatenación de strings en vez de Join-Path. Aunque confiables, es anti-patrón. | Usar Join-Path sistemáticamente. |
| 12 | 🟡 Medio | project-cycle.ps1:46/project-profile.ps1:23 | param([string]Path) sin validación tipográfica. Aunque hay Resolve-Path, no se verifica que esté dentro del proyecto. | Validar contra root del proyecto después de resolver. |
| 13 | 🟡 Medio | bash-safe.ps1:60-66 | Invoke-Bash acepta [string]Command sin restricciones y lo pasa a bash -c. Hoy solo usado en self-tests, pero es vector si se llama con input de usuario. | Dejar como está (by design). Documentar restricción. |
| 14 | 🟡 Medio | cross-ref-check.ps1:30 | config_refs en SKILL.md parseado y usado como path. Si contiene ../ puede leer fuera del repo. | Validar path resuelto contra repo root. |
| 15 | 🟢 Bajo | bootstrap.ps1:17 | Documentación muestra patrón inseguro de descarga+ejecución. | Cambiar a método con verificación. |
| 16 | 🟢 Bajo | capture-errors.ps1:59 | Uso de \.. en vez de Split-Path -Parent. | Usar Split-Path -Parent. |
| 17 | 🟢 Bajo | score-auto.ps1:11,14,16 | Paths relativos que dependen del cwd. | Usar $PSScriptRoot y Join-Path. |
| 18 | 🟢 Bajo | bench-file-io.ps1:78-82 | $Path sin validación usado como argumento a lambdas de lectura. | Validar con Test-Path. |
| 19 | 🟢 Bajo | run.ps1:37 | Join-Path con backslash en primer argumento. | Separar en dos Join-Path. |
| 20 | 🟢 Bajo | install.ps1:49 | Documentación muestra irm + iex como método alternativo. | Mostrar método seguro. |
| 21 | 🟢 Bajo | Varios | Uso de "$var\file" en vez de Join-Path en 10+ lugares. | Adoptar Join-Path como estándar. |

---

## Resumen

| Categoria | Conteo |
|---|---|
| Criticos | 2 |
| Altos | 5 |
| Medios | 7 |
| Bajos | 7 |
| **Total** | **21** |

### Distribucion por tipo de vulnerabilidad

- Invoke-Expression remoto: 1 (critico)
- Inyeccion en comandos git: 1 (critico); 3 (medios)
- Path traversal: 2 (altos); 3 (medios); 1 (bajo)
- Inyeccion en regex: 1 (alto)
- Inyeccion en bash -c: 1 (alto)
- Docker command injection: 1 (alto)
- Path concatenation insegura: 1 (medio); 5 (bajos)
- Parametros sin validacion: 2 (medios)
- Documentacion de malas practicas: 2 (bajos)

### Hallazgo mas critico

**install.ps1:46** — Invoke-Expression + Invoke-WebRequest es un vector clasico de supply-chain attack. Si un atacante compromete GitHub o hace MITM en la conexion, puede ejecutar codigo arbitrario en la maquina del usuario. El URL es de la organizacion Gentleman-Programming, pero no hay verificacion de integridad del contenido descargado. Este patron esta documentado y normalizado en bootstrap.ps1:17 como ejemplo de instalacion.
